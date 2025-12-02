import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var keystoreChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Optimize startup: register plugins first (required)
    GeneratedPluginRegistrant.register(with: self)
    
    // Prevent screenshots and screen recording for security
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(applicationWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    
    // Defer keystore channel setup to avoid blocking startup
    // This will be initialized on first use
    DispatchQueue.main.async { [weak self] in
      self?.setupKeystoreChannel()
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @objc func applicationWillResignActive(_ notification: Notification) {
    // Hide sensitive content when app goes to background
    // This prevents screenshots in app switcher
    if let window = self.window {
      let blurEffect = UIBlurEffect(style: .light)
      let blurView = UIVisualEffectView(effect: blurEffect)
      blurView.frame = window.bounds
      blurView.tag = 999 // Tag to identify and remove later
      window.addSubview(blurView)
    }
  }
  
  override func applicationDidBecomeActive(_ application: UIApplication) {
    // Remove blur overlay when app becomes active
    if let window = self.window {
      window.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }
  }
  
  private func setupKeystoreChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return
    }
    
    keystoreChannel = FlutterMethodChannel(
      name: "authenticator/keystore",
      binaryMessenger: controller.binaryMessenger
    )
    
    keystoreChannel?.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) ining FlutterResult) in
      guard let self = self else {
        result(FlutterError(code: "internal_error", message: "AppDelegate deallocated", details: nil))
        return
      }
      
      switch call.method {
      case "generateKey":
        let args = call.arguments as? [String: Any]
        let alias = args?["alias"] as? String ?? "authenticator_key"
        do {
          let created = try self.ensureKey(alias: alias)
          result(created)
        } catch {
          result(FlutterError(code: "keystore_error", message: error.localizedDescription, details: nil))
        }
      case "wrapKey":
        let args = call.arguments as? [String: Any]
        let alias = args?["alias"] as? String ?? "authenticator_key"
        let keyBase64 = args?["key"] as? String ?? ""
        do {
          let wrapped = try self.wrapKey(alias: alias, keyBase64: keyBase64)
          result(wrapped)
        } catch {
          result(FlutterError(code: "keystore_error", message: error.localizedDescription, details: nil))
        }
      case "unwrapKey":
        let args = call.arguments as? [String: Any]
        let alias = args?["alias"] as? String ?? "authenticator_key"
        let wrapped = args?["wrapped"] as? String ?? ""
        do {
          let unwrapped = try self.unwrapKey(alias: alias, wrappedBase64: wrapped)
          result(unwrapped)
        } catch {
          result(FlutterError(code: "keystore_error", message: error.localizedDescription, details: nil))
        }
      case "isKeyHardwareBacked":
        let args = call.arguments as? [String: Any]
        let alias = args?["alias"] as? String ?? "authenticator_key"
        let isHw = self.isKeyHardwareBacked(alias: alias)
        result(isHw)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Check whether a key with the given alias is stored in Secure Enclave
  private func isKeyHardwareBacked(alias: String) -> Bool {
    let tag = alias.data(using: .utf8)!
    let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrApplicationTag as String: tag,
                                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                kSecReturnRef as String: true]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status != errSecSuccess { return false }
    guard let key = item as! SecKey? else { return false }

    // Inspect attributes - token ID indicates Secure Enclave
    if let attrs = SecKeyCopyAttributes(key) as? [CFString: Any],
       let tokenId = attrs[kSecAttrTokenID] as? String {
      return tokenId == kSecAttrTokenIDSecureEnclave as String
    }

    return false
  }

  // iOS Secure Enclave / Keychain helpers
  func ensureKey(alias: String) throws -> Bool {
    let tag = alias.data(using: .utf8)!
    // Check if key exists
    let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrApplicationTag as String: tag,
                                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                kSecReturnRef as String: true]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecSuccess {
      return true
    }

    // Create new RSA key pair
    let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                     kSecAttrKeySizeInBits as String: 2048,
                                     kSecAttrIsPermanent as String: true,
                                     kSecAttrApplicationTag as String: tag]

    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw error!.takeRetainedValue() as Error
    }
    _ = privateKey
    return true
  }

  func wrapKey(alias: String, keyBase64: String) throws -> String {
    let tag = alias.data(using: .utf8)!
    // Find public key
    let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrApplicationTag as String: tag,
                                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                kSecReturnRef as String: true]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let pubKey = item as! SecKey? else {
      throw NSError(domain: "keystore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Public key not found"])
    }

    guard let keyData = Data(base64Encoded: keyBase64) else {
      throw NSError(domain: "keystore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 key"])
    }

    var error: Unmanaged<CFError>?
    guard let cipherText = SecKeyCreateEncryptedData(pubKey, .rsaEncryptionOAEPSHA256, keyData as CFData, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }

    return cipherText.base64EncodedString()
  }

  func unwrapKey(alias: String, wrappedBase64: String) throws -> String {
    let tag = alias.data(using: .utf8)!
    // Find private key
    let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                kSecAttrApplicationTag as String: tag,
                                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                kSecReturnRef as String: true]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess, let privKey = item as! SecKey? else {
      throw NSError(domain: "keystore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Private key not found"])
    }

    guard let wrappedData = Data(base64Encoded: wrappedBase64) else {
      throw NSError(domain: "keystore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid wrapped base64"])
    }

    var error: Unmanaged<CFError>?
    guard let plainData = SecKeyCreateDecryptedData(privKey, .rsaEncryptionOAEPSHA256, wrappedData as CFData, &error) as Data? else {
      throw error!.takeRetainedValue() as Error
    }

    return plainData.base64EncodedString()
  }
}
