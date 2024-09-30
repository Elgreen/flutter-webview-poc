import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'data_producer.dart';

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
    connectToServerInBackground();
  }

  Future<void> connectToServerInBackground() async {
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
        print(receivedMessage);
        setState(() {
          serverResponse = receivedMessage;
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

  String extractWeight(String message) {
    int weightStartIndex = message.contains('+') ? message.indexOf('+') : message.indexOf('-');
    int weightEndIndex = message.indexOf('kg');

    if (weightStartIndex != -1 && weightEndIndex != -1) {
      String weight = message.substring(weightStartIndex, weightEndIndex).trim();
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

  _toggleUrl() {
    setState(() {
      showUrlBar = !showUrlBar;
    });
  }

  _toggleSettings() {
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
          !showSettings
              ? const SizedBox(width: 0, height: 0)
              : Column(children: <Widget>[
                  const Text('Received from scales:'),
                  Text(serverResponse),
                  const Divider(),
                  const Text('Received from webview:'),
                  Text(dataFromWeb),
                  const Divider(),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: !showUrlBar
                        ? Container()
                        : TextField(
                            decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.navigate_next)),
                            keyboardType: TextInputType.url,
                            controller: TextEditingController()
                              ..text = currentUrl,
                            onSubmitted: (value) {
                              _navigateToUrl(value);
                              _toggleUrl();
                            },
                          ),
                  ),
                  OverflowBar(
                    alignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Icon(Icons.star),
                        onPressed: () {
                          _navigateToUrl(defaultWebAppUrl);
                        },
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>(
                                  (states) {
                            if (showUrlBar) {
                              return Theme.of(context)
                                  .colorScheme
                                  .inversePrimary;
                            }
                            return Theme.of(context).colorScheme.surface;
                          }),
                        ),
                        onPressed: () {
                          _toggleUrl();
                        },
                        child: const Icon(Icons.open_in_browser),
                      ),
                      ElevatedButton(
                        child: const Icon(Icons.refresh),
                        onPressed: () {
                          webViewController?.reload();
                          _clearWebViewData();
                        },
                      ),
                      ElevatedButton(
                        child: const Icon(Icons.send),
                        onPressed: () {
                          _sendCurrentData();
                        },
                      ),
                    ],
                  ),
                ]),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _toggleSettings();
        },
        tooltip: 'Show settings',
        backgroundColor: showSettings
            ? Theme.of(context).colorScheme.inversePrimary
            : Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.settings),
      ),
    );
  }
}