import Flutter
import UIKit

// Simplified AppDelegate without custom keystore implementations
// flutter_secure_storage handles iOS Keychain integration automatically

@main
@objc class AppDelegate: FlutterAppDelegate {
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins
    GeneratedPluginRegistrant.register(with: self)
    
    // Prevent screenshots and screen recording for security
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleWillResignActive),
      name: UIApplication.willResignActiveNotification,
      object: nil
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  @objc func handleWillResignActive(_ notification: Notification) {
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
    super.applicationDidBecomeActive(application)
    // Remove blur overlay when app becomes active
    if let window = self.window {
      window.subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
    }
  }
}
