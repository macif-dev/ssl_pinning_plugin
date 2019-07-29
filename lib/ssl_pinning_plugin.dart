import 'dart:async';

import 'package:flutter/services.dart';


enum SHA {SHA1, SHA256}

class SslPinningPlugin {
  static const MethodChannel _channel = const MethodChannel('ssl_pinning_plugin');

  // Création d'un singleton pour le plugin
  static final SslPinningPlugin _sslPinning = new SslPinningPlugin._internal();

  factory SslPinningPlugin() => _sslPinning;

  SslPinningPlugin._internal() {
    _channel.setMethodCallHandler(_platformCallHandler);
  }

  static Future<String> check({ String serverURL, Map<String, String> headerHttp, SHA sha, List<String> allowedSHAFingerprints, int timeout }) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "url" : serverURL,
      "headers" : headerHttp,
      "type": sha.toString().split(".").last,
      "fingerprints" : allowedSHAFingerprints,
      "timeout" : timeout
    };
    String resp = await _channel.invokeMethod('check', params);
    return resp;
  }

  // Ecoute les retours du plugins
  Future _platformCallHandler(MethodCall call) async {
    print("_platformCallHandler call ${call.method} ${call.arguments}");
  }
}
