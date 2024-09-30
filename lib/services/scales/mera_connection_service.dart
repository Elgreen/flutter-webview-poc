import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MeraConnectionService {
  final String serverAddress;
  final int port;
  final Function(String) onMessageReceived;
  final Function(String) onError;
  final Function() onDone;

  MeraConnectionService({
    required this.serverAddress,
    required this.port,
    required this.onMessageReceived,
    required this.onError,
    required this.onDone,
  });

  Future<void> connectToServerInBackground() async {
    try {
      Socket socket = await Socket.connect(serverAddress, port);
      print('Connected to server: $serverAddress:$port');

      socket.listen((List<int> data) {
        String receivedMessage = ascii.decode(data);
        print('Message received');
        String base64String = base64Encode(data);
        print('Base64: $base64String');
        onMessageReceived(_extractWeight(receivedMessage));

        socket.write('!');
        print('Acknowledgment sent: !');
      }, onError: (error) {
        print("Error: $error");
        onError("Connection error: $error");
        socket.destroy();
      }, onDone: () {
        print("Connection closed");
        onDone();
        socket.destroy();
      });
    } catch (e) {
      print("Error: $e");
      onError("Connection error: $e");
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
      return "Can't extract weight from message";
    }
  }
}
