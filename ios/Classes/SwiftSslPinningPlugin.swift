import Flutter
import UIKit
import CryptoSwift
import Alamofire

public class SwiftSslPinningPlugin: NSObject, FlutterPlugin {

    let manager = Alamofire.SessionManager.default
    var fingerprints: Array<String>?
    var flutterResult: FlutterResult?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ssl_pinning_plugin", binaryMessenger: registrar.messenger())
        let instance = SwiftSslPinningPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.flutterResult = result
        switch (call.method) {
            case "check":
                if let _args = call.arguments as? Dictionary<String, AnyObject> {
                    self.check(call: call, args: _args)
                } else {
                    result(FlutterError(code: "Arguments vide", message: "Veuillez préciser les arguments", details: nil))
                }
                break
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    public func sendResponse(result: AnyObject){
        if let _res = self.flutterResult{
            _res(result)
        }
    }

    public func check(call: FlutterMethodCall, args: Dictionary<String, AnyObject>){
        // Récupération des params
        guard let _urlString = args["url"] as? String,
              let _headers = args["headers"] as? Dictionary<String, String>,
              let _fingerprints = args["fingerprints"] as? Array<String>,
              let _type = args["type"] as? String
        else {
            self.sendResponse(result: FlutterError(code: "Params incorrect", message: "Les params sont incorrect", details: nil))
            return
        }

        self.fingerprints = _fingerprints

        // Timeout en millisecond
        var _timeout = 60
        if let _timeoutArg = args["timeout"] as? Int {
            _timeout = _timeoutArg
        }

        Alamofire.request(_urlString, parameters: _headers).validate().responseJSON() { response in
            switch response.result {
            case .success:
                break
            case .failure(let error):
                self.sendResponse(result: FlutterError(code: "URL Format", message: error.localizedDescription, details: nil))
                break
            }
        }

        manager.session.configuration.timeoutIntervalForRequest = TimeInterval(_timeout)

        manager.delegate.sessionDidReceiveChallenge = { session, challenge in

            guard
                let _serverTrust = challenge.protectionSpace.serverTrust,
                let _serverCert = SecTrustGetCertificateAtIndex(_serverTrust, 0),
                challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
                SecTrustEvaluate(_serverTrust, nil) == errSecSuccess
                else {
                    self.sendResponse(result: FlutterError(code: "ERROR CERT", message: "Le certificat est invalide", details: nil))
                    return (.cancelAuthenticationChallenge, nil)
            }

            let _serverCertData = SecCertificateCopyData(_serverCert) as Data
            var _serverCertSha = _serverCertData.sha256().toHexString()

            if(_type == "SHA1"){
                _serverCertSha = _serverCertData.sha1().toHexString()
            }

            var isSecure = false
            if var _fp = self.fingerprints {
                // Suprime les espaces
                _fp = _fp.compactMap { (val) -> String? in
                    val.replacingOccurrences(of: " ", with: "")
                }

                // Compare les strings
                isSecure = _fp.contains(where: { (value) -> Bool in
                    value.caseInsensitiveCompare(_serverCertSha) == .orderedSame
                })
            }

            if isSecure {
                self.sendResponse(result: "CONNECTION_SECURE" as AnyObject)
            }else {
                self.sendResponse(result: FlutterError(code: "CONNECTION_NOT_SECURE", message: nil, details: nil))
            }

            //Annule l'authentification car ici on test juste le ssl pinning
            return (.cancelAuthenticationChallenge, nil)
        }

    }

}