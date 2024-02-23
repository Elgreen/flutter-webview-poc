# Flutter <--> webview data exchange

Proof of concept for data exchange between Flutter and web app inside webview.

<img src="docs/Screenshot_20240223_141900.png" width="300">

## Flutter app

### Web app to Flutter communication

In web app:

The web app can send data to the Flutter app using the `window.flutter_inappwebview.callHandler()` method.
```javascript
function sendMessageToFlutter(message) {
    window.flutter_inappwebview.callHandler('flutterApp', message).then(function(result) {
       console.log(result);
    });
}
```

In flutter app:

Flutter listens for messages from the web app using the `WebViewController.addJavaScriptHandler()` method.

```dart
InAppWebView(
  ...
  onWebViewCreated: (controller) {
    webViewController.addJavaScriptHandler(handlerName: 'flutterApp', callback: (data) {
      _recieveData(args[0]);
    });
  },
  ...
),
```

### Flutter to web app communication

The Flutter app is a simple app with a button that sends a message to the web app.

It uses the `flutter_inappwebview` package to display the web app.

In flutter app:

Flutter can send data to the web app using the `WebViewController.evaluateJavascript()` method.

```dart
void _sendData(String data) async {
  await webViewController?.evaluateJavascript(source: "receiveMessageFromFlutter('$data');");
}
```

In web app:

it calls the `receiveMessageFromFlutter` function in the web app with the data as an argument.

```javascript
function receiveMessageFromFlutter(message) {
    currentTime = new Date().toLocaleTimeString();
    document.getElementById("response").innerHTML = `<p>Event time: ${currentTime}.</p><p>Event data: ${message}</p>`;
}
```

## Web app

Example app hosted at https://venerable-bienenstitch-6073af.netlify.app/

It's a simple web app that displays the time and a message. The message is set by the Flutter app.

Web app source code:

`index.html`
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Web App</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<header>
    <h1>Webview app</h1>
</header>
<h2>Send to flutter</h2>

<form>
    <label for="dataToSend">Data to send:</label><br>
    <input type="text" id="dataToSend" name="dataToSend"><br>
    <input type="button" value="Submit" onclick="sendMessageToFlutter(document.getElementById('dataToSend').value)">
</form>

<h2>Received from flutter</h2>
<main id="response">
    No data received yet
    <!-- This is where the JS will insert data from flutter -->
</main>

<script>
        // Get data from flutter

        function receiveMessageFromFlutter(message) {
            currentTime = new Date().toLocaleTimeString();
            document.getElementById("response").innerHTML = `<p>Event time: ${currentTime}.</p><p>Event data: ${message}</p>`;
        }

        function sendMessageToFlutter(message) {
            window.flutter_inappwebview.callHandler('flutterApp', message).then(function(result) {
               console.log(result);
            });
        }

        // Placeholder for function FlutterApp.postMessage to send data to flutter
        let FlutterApp = {
            postMessage: (message) => {console.log("Can't send message because not inside webview_flutter or JavascriptChannel is not used.");},
        };
    </script>
</body>
</html>
```