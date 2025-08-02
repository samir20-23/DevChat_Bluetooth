// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import '../widgets/message_bubble.dart';
import '../widgets/custom_app_bar.dart';
import '../services/nostr_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nostr = NostrService();
  final _ctrl = TextEditingController();
  final List<Map<String, String>> _messages = [];

  @override
  void initState() {
    super.initState();
    _nostr.init().then((_) {
      _nostr.messages.listen((msg) {
        setState(() {
          _messages.insert(0, {
            'sender': 'Friend',
            'text': msg,
          });
        });
      });
    });
  }

  void _send() {
    final txt = _ctrl.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.insert(0, {
        'sender': 'You',
        'text': txt,
      });
    });
    _nostr.send(txt);
    _ctrl.clear();
  }

  @override
  void dispose() {
    _nostr.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                      controller: _ctrl,
                      decoration:
                          const InputDecoration(labelText: 'Type your message'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            ),
          ],
        ),
      );
}
