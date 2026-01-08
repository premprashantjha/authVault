import Flutter
import UIKit

public class AccountPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.cdac.authenticator/account", binaryMessenger: registrar.messenger())
        let instance = AccountPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAppleAccountId":
            getAppleAccountId(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func getAppleAccountId(result: @escaping FlutterResult) {
        // Get iCloud account identifier
        // This uses the ubiquity container identifier which is tied to the user's Apple ID
        if let token = FileManager.default.ubiquityIdentityToken {
            // Convert token to string representation
            let tokenString = token.description
            result(tokenString)
        } else {
            result(FlutterError(code: "NO_ACCOUNT",
                              message: "No Apple ID found. Please sign in to iCloud.",
                              details: nil))
        }
    }
}
