import 'dart:async';

class SocketService {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get messagesStream => _controller.stream;

  void sendMessage(String message) {
    // Simulate echo back after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      _controller.sink.add("Friend: $message");
    });
  }

  void dispose() {
    _controller.close();
  }
}
