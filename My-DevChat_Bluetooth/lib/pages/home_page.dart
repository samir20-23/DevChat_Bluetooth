import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/custom_app_bar.dart';
import '../services/bluetooth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> _messages = [];
  final _controller = TextEditingController();
  final _btService = BluetoothService();

  @override
  void initState() {
    super.initState();
    _btService.startScanAndConnect().then((_) {
      _btService.messagesStream.listen((msg) {
        setState(() {
          _messages.insert(0, {'text': msg, 'sender': 'Phone'});
        });
      });
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.insert(0, {'text': text, 'sender': 'You'});
    });
    _btService.sendMessage(text);
    _controller.clear();
  }

  @override
  void dispose() {
    _btService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'DevChat'),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (ctx, i) => MessageBubble(
                text: _messages[i]['text']!,
                sender: _messages[i]['sender']!,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(labelText: 'Type your message'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
