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
  Map<String, String> headerHttp = new Map();
  String allowedSHA1Fingerprint = '';
  int timeout = 0;
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  _PiningSslData _data = new _PiningSslData();
  BuildContext scaffoldContext;

  @override
  initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  check(String url, String fingerprint, Map<String, String> headerHttp, int timeout) async {

    List<String> allowedShA1FingerprintList = new List();
    allowedShA1FingerprintList.add(fingerprint);

    try {
      // Platform messages may fail, so we use a try/catch PlatformException.
      String checkMsg = await SslPinningPlugin.check(serverURL: url,
          headerHttp: headerHttp,
          allowedSHA1Fingerprint: allowedShA1FingerprintList,
          timeout: timeout);

      // If the widget was removed from the tree while the asynchronous platform
      // message was in flight, we want to discard the reply rather than calling
      // setState to update our non-existent appearance.
      if (!mounted)
        return;

      Scaffold.of(scaffoldContext).showSnackBar(
        new SnackBar(
          content: new Text(checkMsg),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),

      );
    }catch (e){
      Scaffold.of(scaffoldContext).showSnackBar(
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
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save(); // Save our form now.

      this.check(_data.serverURL, _data.allowedSHA1Fingerprint, _data.headerHttp, _data.timeout);
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
        body:
          new Builder(builder: (BuildContext context) {
            this.scaffoldContext = context;
            return new Container(
              padding: new EdgeInsets.all(20.0),
              child: new Form(
                key: this._formKey,
                child: new ListView(
                children: <Widget>[
                  new TextFormField(
                    keyboardType: TextInputType.url,
                    decoration: new InputDecoration(
                      hintText: 'https://yourdomain.com',
                      labelText: 'URL'
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some url';
                      }
                    },
                    onSaved: (String value) {
                      this._data.serverURL = value;
                    }
                  ),
                  new TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: new InputDecoration(
                       hintText: 'OO OO OO OO OO OO OO OO OO OO',
                       labelText: 'Fingerprint'
                    ),
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter some fingerprint';
                      }
                    },
                    onSaved: (String value) {
                      this._data.allowedSHA1Fingerprint = value;
                    }
                  ),
                  new TextFormField(
                      keyboardType: TextInputType.number,
                      initialValue: '60',
                      decoration: new InputDecoration(
                          hintText: '60',
                          labelText: 'Timeout'
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter some timeout';
                        }
                      },
                      onSaved: (String value) {
                        this._data.timeout = int.parse(value);
                      }
                  ),
                  new Container(
                    child: new RaisedButton(
                      child: new Text(
                        'Check',
                        style: new TextStyle(
                          color: Colors.white
                        ),
                      ),
                      onPressed: () => submit(),
                      color: Colors.blue,
                    ),
                    margin: new EdgeInsets.only(
                      top: 20.0
                    ),
                  )
                ],
              ),
            )
          );
        })
      ),
    );
  }
}
