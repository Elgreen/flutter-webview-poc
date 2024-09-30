import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:math';

const String defaultWebAppUrl =
    'https://elgreen.github.io/flutter-webview-poc/';
const String noData = 'No data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class DataProducer {
  static double getValue() {
    var now = DateTime.now();
    var seconds = now.microsecond + now.second * 1000;
    return 100 * sin((seconds / 60000.0 * pi));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter <--> Webview Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter <--> Webview Demo'),
    );
  }
}

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

  // Метод для подключения к серверу и получения данных в фоне
  Future<void> connectToServerInBackground() async {
    const String serverAddress = '127.0.0.1'; // IP-адрес сервера
    // const String serverAddress = 'accounting.keenetic.pro'; // IP-адрес сервера

    // const int port = 1001; // Wifi
    // const int port = 1011; // Ethernet
    const int port = 10001; // Ethernet

    try {
      // Подключаемся к серверу
      Socket socket = await Socket.connect(serverAddress, port);
      print('Подключено к серверу: $serverAddress:$port');
      setState(() {
        serverResponse = 'Подключено к серверу: $serverAddress:$port';
      });

      // Слушаем поток данных в бесконечном режиме
      socket.listen((List<int> data) {
        String receivedMessage = ascii.decode(data);
        print('Получено сообщение');

        // Извлекаем вес из полученного сообщения
        // receivedMessage = extractWeight(receivedMessage);
        String base64String = base64Encode(data);
        print('Base64: $base64String');
        print(receivedMessage);
        setState(() {
          serverResponse = receivedMessage;
        });

        // Отправляем подтверждение "!"
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

  // Функция для извлечения веса из полученного сообщения
  String extractWeight(String message) {
    // Ищем позицию знака массы (+ или -) и ключевое слово "kg"
    int weightStartIndex = message.contains('+') ? message.indexOf('+') : message.indexOf('-');
    int weightEndIndex = message.indexOf('kg');

    if (weightStartIndex != -1 && weightEndIndex != -1) {
      // Извлекаем подстроку с весом
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
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
                    // register a JavaScript handler with name "flutterApp"
                    controller.addJavaScriptHandler(
                        handlerName: 'flutterApp',
                        callback: (args) {
                          _recieveData(args[0]);

                          // return data to the JavaScript side!
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
                        // open default url
                        child: const Icon(Icons.star),
                        onPressed: () {
                          _navigateToUrl(defaultWebAppUrl);
                        },
                      ),
                      ElevatedButton(
                        // open url bar
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
                          //_navigateToUrl(defaultWebAppUrl);
                        }, // open url bar
                        child: const Icon(Icons.open_in_browser),
                      ),
                      ElevatedButton(
                        // reload webview
                        child: const Icon(Icons.refresh),
                        onPressed: () {
                          webViewController?.reload();
                          _clearWebViewData();
                        },
                      ),
                      ElevatedButton(
                        // send data to webview
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
