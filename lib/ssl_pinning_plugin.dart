import 'dart:async';

import 'package:flutter/services.dart';

enum SHA { SHA1, SHA256 }
enum HttpMethod { Get, Head }

class SslPinningPlugin {
  static const MethodChannel _channel =
      const MethodChannel('ssl_pinning_plugin');

  static Future<String> check(
      {required String serverURL,
      HttpMethod httpMethod = HttpMethod.Get,
      Map<String, String>? headerHttp,
      required SHA sha,
      required List<String> allowedSHAFingerprints,
      required int timeout}) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "url": serverURL,
      "httpMethod": httpMethod.toString().split(".").last,
      "headers": headerHttp ?? new Map(),
      "type": sha.toString().split(".").last,
      "fingerprints": allowedSHAFingerprints,
      "timeout": timeout
    };

    String resp = await _channel.invokeMethod('check', params);
    return resp;
  }
}
