import 'package:flutter/material.dart';

class WebViewData extends StatelessWidget {
  final String dataFromWeb;

  const WebViewData({Key? key, required this.dataFromWeb}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('Received from webview:'),
        Text(dataFromWeb),
        const Divider(),
      ],
    );
  }
}
