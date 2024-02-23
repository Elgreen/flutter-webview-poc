import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:math';

const String defaultWebAppUrl = 'https://elgreen.github.io/flutter-webview-poc/';
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
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter <--> Webview Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentUrl = defaultWebAppUrl;
  String dataFromWeb = noData;
  bool showUrlBar = false;
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;
  InAppWebViewSettings settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      mediaPlaybackRequiresUserGesture: false,
      allowsInlineMediaPlayback: true,
      javaScriptEnabled: true,
      iframeAllowFullscreen: false);

  void _sendCurrentData() {
    _sendData(DataProducer.getValue().toString());
  }

  void _sendData(String data) async {
    await webViewController?.evaluateJavascript(source: "receiveMessageFromFlutter('$data');");
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

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("${widget.title}"),
      ),
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
          Text('Received from webview:'),
          Text(dataFromWeb),
          Divider(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: !showUrlBar ? Container() : TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.navigate_next)),
              keyboardType: TextInputType.url,
              controller: TextEditingController()..text = currentUrl,
              onSubmitted: (value) {
                _navigateToUrl(value);
                _toggleUrl();
              },
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton( // open default url
                child: const Icon(Icons.star),
                onPressed: () {
                  _navigateToUrl(defaultWebAppUrl);
                },
              ),
              ElevatedButton( // open url bar
                child: const Icon(Icons.open_in_browser),
                // set button visually pressed if showUrlBar is true
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (showUrlBar) {
                      return Theme.of(context).colorScheme.primary.withOpacity(0.00001);
                    }
                    return Theme.of(context).colorScheme.background;
                  }),
                ),
                onPressed: () {
                  _toggleUrl();
                  //_navigateToUrl(defaultWebAppUrl);
                },
              ),
              ElevatedButton( // reload webview
                child: const Icon(Icons.refresh),
                onPressed: () {
                  webViewController?.reload();
                  _clearWebViewData();
                },
              ),
              ElevatedButton( // send data to webview
                child: const Icon(Icons.send),
                onPressed: () {
                  _sendCurrentData();
                },
              ),
            ],
          ),
        ]),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
