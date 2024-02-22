# Flutter <--> webview data exchange

Proof of concept for data exchange between Flutter and web app inside webview.

## Getting Started

### Web app

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
</head>
<body>
    <header>
        <h1>Webview app</h1>
    </header>
    <main id="response">
        Loading...
        <!-- This is where the JS will insert the text and time -->
    </main>
    <script src="req.js"></script>
</body>
</html>

```

`req.js`
```javascript
// Set response 
function setResponse(responseText) {
    currentTime = new Date().toLocaleTimeString();
    document.getElementById("response").innerHTML = `<p>Event time: ${currentTime}.</p><p>Event data: ${responseText}</p>`;
}

setResponse("Loading...");
```

### Flutter app

The Flutter app is a simple app with a button that sends a message to the web app.

It uses the `webview_flutter` package to display the web app.

Flutter can send data to the web app using the `WebViewController.runJavaScript()` method.

```dart
void _sendData(data)
{
  controller.runJavaScript("setResponse('$data');");
}
```