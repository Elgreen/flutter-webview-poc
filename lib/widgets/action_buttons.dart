import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final bool showUrlBar;
  final Function() navigateToDefaultUrl;
  final Function() toggleUrl;
  final Function() reloadWebView;
  final Function() sendCurrentData;

  const ActionButtons({
    Key? key,
    required this.showUrlBar,
    required this.navigateToDefaultUrl,
    required this.toggleUrl,
    required this.reloadWebView,
    required this.sendCurrentData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OverflowBar(
      alignment: MainAxisAlignment.center,
      children: <Widget>[
        ElevatedButton(
          child: const Icon(Icons.star),
          onPressed: navigateToDefaultUrl,
        ),
        ElevatedButton(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
              if (showUrlBar) {
                return Theme.of(context).colorScheme.inversePrimary;
              }
              return Theme.of(context).colorScheme.surface;
            }),
          ),
          onPressed: toggleUrl,
          child: const Icon(Icons.open_in_browser),
        ),
        ElevatedButton(
          child: const Icon(Icons.refresh),
          onPressed: reloadWebView,
        ),
        ElevatedButton(
          child: const Icon(Icons.send),
          onPressed: sendCurrentData,
        ),
      ],
    );
  }
}
