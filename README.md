# ssl_pinning_plugin

Plugin for check SSL Pinning on request HTTP.

Checks the equality between the known SHA-1 or SHA-256 fingerprint and the SHA-1 or SHA-256 of the target server.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

For help on editing plugin code, view the [documentation](https://flutter.io/platform-plugins/#edit-code).

## Check

###Params

- serveurUrl : `String`
- headerHttp : `Map<String, String>`
- sha : `SHA` enum [SHA.SHA1 || SHA.SHA256]
- allowedSHAFingerprints : `List<String>`
- timeout : `int`

###Usage :

`await SslPinningPlugin.check(serverURL: url, headerHttp : new Map(), sha: SHA.SHA1, allowedSHAFingerprints: new List<String>, timeout : 50);`

###Return :

- On success, return String "CONNECTION_SECURE"
- On error, return String "CONNECTION_INSECURE"

If an exception, return the stacktrace on String value.