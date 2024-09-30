import 'package:flutter/material.dart';

class ScalesData extends StatelessWidget {
  final String serverResponse;

  const ScalesData({Key? key, required this.serverResponse}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('Received from scales:'),
        Text(serverResponse),
        const Divider(),
      ],
    );
  }
}
