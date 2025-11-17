import Flutter
import UIKit
import Security

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // Keystore method channel for wrapping/unwrapping keys
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "authenticator/keystore", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
