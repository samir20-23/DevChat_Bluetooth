import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/nostr_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final NostrService _nostrService = NostrService();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _filterController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  List<_Message> _messages = [];
  String _filter = '';
  DateTime _lastSendTime = DateTime.now().subtract(const Duration(seconds: 2));
  final String _myUserId = "user_\${Random().nextInt(1000)}";

  @override
  void initState() {
    super.initState();
    _nostrService.init();
    _nostrService.messages.listen((rawMsg) {
      final split = rawMsg.split(':');
      final sender = split.first.trim();
      final content = split.sublist(1).join(':').trim();

      setState(() {
        _messages.insert(
          0,
          _Message(sender: sender, content: content, timestamp: DateTime.now()),
        );
      });
    });
    _filterController.addListener(() {
      setState(() {
        _filter = _filterController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _nostrService.dispose();
    _controller.dispose();
    _filterController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    final now = DateTime.now();
    if (text.isEmpty) return;
    if (now.difference(_lastSendTime).inMilliseconds < 1000) return;

    await _nostrService.send("\$_myUserId: \$text");
    _controller.clear();
    _lastSendTime = now;
    _inputFocus.requestFocus();
  }

  void _replyTo(_Message msg) {
    _controller.text = "@${msg.sender}: ";
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
    _inputFocus.requestFocus();
  }

  void _copyContent(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard 📋')),
    );
  }

  List<_Message> get _filteredMessages {
    if (_filter.isEmpty) return _messages;
    return _messages
        .where((m) => m.content.toLowerCase().contains(_filter) || m.sender.toLowerCase().contains(_filter))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔥 DevChat Dark'),
        backgroundColor: Colors.black87,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                _myUserId,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _filterController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                hintText: 'Filter messages...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _filter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () => _filterController.clear(),
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _filteredMessages.length,
              itemBuilder: (context, index) {
                final msg = _filteredMessages[index];
                final isMine = msg.sender == _myUserId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Card(
                    color: isMine ? Colors.blueAccent : Colors.grey[850],
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isMine ? 'Me' : msg.sender,
                                style: TextStyle(
                                  color: Colors.grey[300],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _formatTime(msg.timestamp),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            msg.content,
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy, size: 20, color: Colors.white70),
                                onPressed: () => _copyContent(msg.content),
                              ),
                              IconButton(
                                icon: const Icon(Icons.reply, size: 20, color: Colors.white70),
                                onPressed: () => _replyTo(msg),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _inputFocus,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '💬 Type a message...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "\${time.hour.toString().padLeft(2, '0')}:\${time.minute.toString().padLeft(2, '0')}";
  }
}

class _Message {
  final String sender;
  final String content;
  final DateTime timestamp;
  _Message({required this.sender, required this.content, required this.timestamp});
}
