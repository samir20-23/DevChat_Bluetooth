// lib/services/nostr_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:nostr/nostr.dart';

class NostrService {
  late final Keychain _keys;
  late final WebSocket _ws;
  final _msgCtrl = StreamController<String>.broadcast();

  Stream<String> get messages => _msgCtrl.stream;

  Future<void> init() async {
    _keys = Keychain.generate();
    _ws = await WebSocket.connect('wss://relay.damus.io');
    // subscribe to all text notes (kind=1)
    _ws.add(jsonEncode(['REQ', 'sub1', {'kinds': [1]}]));
    _ws.listen((raw) {
      final msg = jsonDecode(raw as String);
      if (msg is List && msg.isNotEmpty && msg[0] == 'EVENT') {
        final payload = msg[2] as Map<String, dynamic>;
        _msgCtrl.add(payload['content'] as String);
      }
    });
  }

  Future<void> send(String text) async {
    final event = Event.from(
      kind: 1,
      tags: [],
      content: text,
      privkey: _keys.private,
    );
    _ws.add(event.serialize());
    _msgCtrl.add(text); // echo locally
  }

  void dispose() {
    _ws.close();
    _msgCtrl.close();
  }
}
