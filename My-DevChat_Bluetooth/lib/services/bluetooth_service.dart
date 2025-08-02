import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class BluetoothService {
  final _ble = FlutterReactiveBle();
  DiscoveredDevice? _device;
  QualifiedCharacteristic? _writeChar;
  StreamSubscription<List<int>>? _notifySub;
  StreamSubscription<DiscoveredDevice>? _scanSub;
  final _msgCtrl = StreamController<String>.broadcast();

  /// Stream of incoming text messages.
  Stream<String> get messagesStream => _msgCtrl.stream;

  /// Scan for “DevChatPhone”, connect, discover, and subscribe.
  Future<void> startScanAndConnect() async {
    _scanSub = _ble.scanForDevices(withServices: []).listen((dev) async {
      if (dev.name == 'DevChatPhone') {
        _device = dev;
        await _scanSub?.cancel();

        // Connect (waits for first connection event)
        await _ble.connectToDevice(id: dev.id).first;

        // Discover services & characteristics
        final services = await _ble.discoverServices(dev.id);
        for (var svc in services) {
          for (var char in svc.characteristics) {
            final qc = QualifiedCharacteristic(
              serviceId: svc.serviceId,
              characteristicId: char.characteristicId,
              deviceId: dev.id,
            );

            // If it's notifiable, subscribe
            if (char.isNotifiable) {
              _notifySub = _ble
                  .subscribeToCharacteristic(qc)
                  .listen((bytes) => _msgCtrl.add(String.fromCharCodes(bytes)));
            }

            // Capture the first writable-with-response characteristic
            if (_writeChar == null && char.isWritableWithResponse) {
              _writeChar = qc;
            }
          }
        }
      }
    });
  }

  /// Send UTF-8 text over the first writable characteristic.
  Future<void> sendMessage(String text) async {
    if (_writeChar == null) return;
    await _ble.writeCharacteristicWithResponse(
      _writeChar!,
      value: text.codeUnits,
    );
  }

  /// Clean up all subscriptions.
  void dispose() {
    _scanSub?.cancel();
    _notifySub?.cancel();
    _msgCtrl.close();
  }
}
