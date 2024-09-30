import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'data_producer.dart';
import 'widgets/action_buttons.dart';
import 'widgets/scales_data.dart';
import 'widgets/url_input.dart';
import 'widgets/webview_data.dart';

const String defaultWebAppUrl = 'https://elgreen.github.io/flutter-webview-poc/';
const String noData = 'No data';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentUrl = defaultWebAppUrl;
  String dataFromWeb = noData;
  bool showUrlBar = true;
  bool showSettings = false;
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      javaScriptEnabled: true,
      iframeAllowFullscreen: false);
  String serverResponse = "Ожидание данных...";

  @override
  void initState() {
    super.initState();
    _connectToServerInBackground();
  }

  Future<void> _connectToServerInBackground() async {
    const String serverAddress = '127.0.0.1';
    const int port = 10001;

    try {
      Socket socket = await Socket.connect(serverAddress, port);
      print('Подключено к серверу: $serverAddress:$port');
      setState(() {
        serverResponse = 'Подключено к серверу: $serverAddress:$port';
      });

      socket.listen((List<int> data) {
        String receivedMessage = ascii.decode(data);
        print('Получено сообщение');
        String base64String = base64Encode(data);
        print('Base64: $base64String');
        String weight = _extractWeight(receivedMessage);
        print(weight);
        setState(() {
          serverResponse = weight;
        });

        socket.write('!');
        print('Подтверждение отправлено: !');
      }, onError: (error) {
        print("Ошибка: $error");
        setState(() {
          serverResponse = "Ошибка подключения: $error";
        });
        socket.destroy();
      }, onDone: () {
        print("Соединение закрыто");
        setState(() {
          serverResponse = "Соединение закрыто сервером";
        });
        socket.destroy();
      });
    } catch (e) {
      print("Ошибка: $e");
      setState(() {
        serverResponse = "Ошибка подключения: $e";
      });
    }
  }

  String _extractWeight(String message) {
    int weightStartIndex =
        message.contains('+') ? message.indexOf('+') : message.indexOf('-');
    int weightEndIndex = message.indexOf('kg');

    if (weightStartIndex != -1 && weightEndIndex != -1) {
      String weight =
          message.substring(weightStartIndex, weightEndIndex).trim();
      return weight;
    } else {
      return "Не удалось извлечь вес";
    }
  }

  void _sendCurrentData() {
    _sendData(DataProducer.getValue().toString());
  }

  void _sendData(String data) async {
    await webViewController?.evaluateJavascript(
        source: "receiveMessageFromFlutter('$data');");
  }

  void _recieveData(String data) async {
    setState(() {
      dataFromWeb = '$data on ${DateTime.now().toString()}';
    });
  }

  void _clearWebViewData() {
    setState(() {
      dataFromWeb = noData;
    });
  }

  void _navigateToUrl(String url) async {
    setState(() {
      currentUrl = url;
    });
    await webViewController?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    _clearWebViewData();
  }

  void _toggleUrl() {
    setState(() {
      showUrlBar = !showUrlBar;
    });
  }

  void _toggleSettings() {
    setState(() {
      showSettings = !showSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(children: <Widget>[
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                  key: webViewKey,
                  initialUrlRequest: URLRequest(url: WebUri(defaultWebAppUrl)),
                  initialSettings: settings,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                    controller.addJavaScriptHandler(
                        handlerName: 'flutterApp',
                        callback: (args) {
                          _recieveData(args[0]);
                          return 'hello from flutter';
                        });
                  },
                  onConsoleMessage: (controller, consoleMessage) {
                    if (kDebugMode) {
                      print(consoleMessage);
                    }
                  },
                ),
              ],
            ),
          ),
          if (showSettings) ...[
            ScalesData(serverResponse: serverResponse),
            WebViewData(dataFromWeb: dataFromWeb),
            UrlInput(
              showUrlBar: showUrlBar,
              currentUrl: currentUrl,
              onSubmitted: (value) {
                _navigateToUrl(value);
                _toggleUrl();
              },
            ),
            ActionButtons(
              showUrlBar: showUrlBar,
              navigateToDefaultUrl: () => _navigateToUrl(defaultWebAppUrl),
              toggleUrl: _toggleUrl,
              reloadWebView: () {
                webViewController?.reload();
                _clearWebViewData();
              },
              sendCurrentData: _sendCurrentData,
            ),
          ],
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleSettings,
        tooltip: 'Show settings',
        backgroundColor: showSettings
            ? Theme.of(context).colorScheme.inversePrimary
            : Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.settings),
      ),
    );
  }
}