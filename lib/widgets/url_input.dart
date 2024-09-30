import 'package:flutter/material.dart';

class UrlInput extends StatelessWidget {
  final bool showUrlBar;
  final String currentUrl;
  final Function(String) onSubmitted;

  const UrlInput({
    Key? key,
    required this.showUrlBar,
    required this.currentUrl,
    required this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: !showUrlBar
          ? Container()
          : TextField(
              decoration:
                  const InputDecoration(prefixIcon: Icon(Icons.navigate_next)),
              keyboardType: TextInputType.url,
              controller: TextEditingController()..text = currentUrl,
              onSubmitted: onSubmitted,
            ),
    );
  }
}
