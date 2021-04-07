import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssl_pinning_plugin/ssl_pinning_plugin.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _PiningSslData {
  String serverURL = '';
  HttpMethod httpMethod = HttpMethod.Get;
  Map<String, String> headerHttp = new Map();
  String allowedSHAFingerprint = '';
  int timeout = 0;
  late SHA sha = SHA.SHA1;
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  _PiningSslData _data = new _PiningSslData();
  late BuildContext scaffoldContext;

  @override
  initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  check(String url, String fingerprint, HttpMethod httpMethod, SHA sha,
      Map<String, String> headerHttp, int timeout) async {
    List<String> allowedShA1FingerprintList = [];
    allowedShA1FingerprintList.add(fingerprint);

    try {
      // Platform messages may fail, so we use a try/catch PlatformException.
      String checkMsg = await SslPinningPlugin.check(
          serverURL: url,
          headerHttp: headerHttp,
          httpMethod: httpMethod,
          sha: sha,
          allowedSHAFingerprints: allowedShA1FingerprintList,
          timeout: timeout);

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted) return;

      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        new SnackBar(
          content: new Text(checkMsg),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        new SnackBar(
          content: new Text(e.toString()),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void submit() {
    // First validate form.
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // Save our form now.

      this.check(_data.serverURL, _data.allowedSHAFingerprint, _data.httpMethod,
          _data.sha, _data.headerHttp, _data.timeout);
    }
  }

  @override
  Widget build(BuildContext context) {
    this.scaffoldContext = context;
    return new MaterialApp(
      home: new Scaffold(
          appBar: new AppBar(
            title: new Text('Ssl Pinning Plugin'),
          ),
          body: new Builder(builder: (BuildContext context) {
            this.scaffoldContext = context;
            return Container(
                padding: EdgeInsets.all(20.0),
                child: Form(
                  key: this._formKey,
                  child: new ListView(
                    children: <Widget>[
                      TextFormField(
                          keyboardType: TextInputType.url,
                          initialValue: "https://flutter.dev/",
                          decoration: InputDecoration(
                            hintText: 'https://yourdomain.com',
                            labelText: 'URL',
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter some url';
                            }
                            return null;
                          },
                          onSaved: (value) => this._data.serverURL = value!),
                      DropdownButton(
                        items: [
                          DropdownMenuItem(
                            child: Text(SHA.SHA1.toString()),
                            value: SHA.SHA1,
                          ),
                          DropdownMenuItem(
                            child: Text(SHA.SHA256.toString()),
                            value: SHA.SHA256,
                          )
                        ],
                        value: _data.sha,
                        isExpanded: true,
                        onChanged: (SHA? val) {
                          setState(() {
                            this._data.sha = val!;
                          });
                        },
                      ),
                      DropdownButton(
                        items: [
                          DropdownMenuItem(
                            child: Text(HttpMethod.Get.toString()),
                            value: HttpMethod.Get,
                          ),
                          DropdownMenuItem(
                            child: Text(HttpMethod.Head.toString()),
                            value: HttpMethod.Head,
                          )
                        ],
                        value: _data.httpMethod,
                        isExpanded: true,
                        onChanged: (HttpMethod? val) {
                          setState(() {
                            this._data.httpMethod = val!;
                          });
                        },
                      ),
                      TextFormField(
                          keyboardType: TextInputType.text,
                          initialValue:
                              "9D B3 FC A9 17 36 04 27 A2 82 2F BD 06 95 F1 DC 0A 00 9F 72",
                          decoration: InputDecoration(
                              hintText: 'OO OO OO OO OO OO OO OO OO OO',
                              labelText: 'Fingerprint'),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter some fingerprint';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              this._data.allowedSHAFingerprint = value!),
                      TextFormField(
                          keyboardType: TextInputType.number,
                          initialValue: '60',
                          decoration: InputDecoration(
                              hintText: '60', labelText: 'Timeout'),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter some timeout';
                            }
                            return null;
                          },
                          onSaved: (value) =>
                              this._data.timeout = int.parse(value!)),
                      Container(
                        child: ElevatedButton(
                          child: Text(
                            'Check',
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => submit(),
                        ),
                        margin: EdgeInsets.only(top: 20.0),
                      )
                    ],
                  ),
                ));
          })),
    );
  }
}
