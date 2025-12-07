import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:crypto/crypto.dart';

class ScanReceiverPage extends StatefulWidget {
  const ScanReceiverPage({super.key});

  @override
  State<ScanReceiverPage> createState() => _ScanReceiverPageState();
}

class _ScanReceiverPageState extends State<ScanReceiverPage> {
  final MobileScannerController _cameraController = MobileScannerController();
  String _publicKey = '';
  String _id = '';
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    String content = raw.trim();

    try {
      // Try parse as JSON: { "publicKey": "...", "id": "..." }
      final parsed = jsonDecode(content);
      if (parsed is Map && parsed['publicKey'] != null) {
        final pk = parsed['publicKey'].toString();
        final id = parsed['id']?.toString() ?? _fingerprint(pk);
        setState(() {
          _publicKey = pk;
          _id = id;
          _scanned = true;
        });
        await _cameraController.stop();
        return;
      }
    } catch (_) {
      // Not JSON — treat whole content as public key
    }

    // If we reach here, treat content as the public key string
    final pk = content;
    setState(() {
      _publicKey = pk;
      _id = _fingerprint(pk);
      _scanned = true;
    });
    await _cameraController.stop();
  }

  String _fingerprint(String publicKey) {
    final bytes = utf8.encode(publicKey);
    final digest = sha256.convert(bytes);
    // Shorten to first 16 hex chars for display (you can change formatting)
    return digest.toString();
  }

  Future<void> _copy(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
  }

  void _resetScanner() async {
    setState(() {
      _publicKey = '';
      _id = '';
      _scanned = false;
    });
    await _cameraController.start();
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receiver QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScanner,
            tooltip: 'Rescan',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: _onDetect,
                ),
                if (!_scanned)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Point the camera to the receiver QR code',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scanned Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Public Key',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          _publicKey.isEmpty ? '- not scanned -' : _publicKey,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: Text('ID: ${_id.isEmpty ? '-' : _id}')),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _publicKey.isEmpty
                            ? null
                            : () => _copy(_publicKey, 'Public key'),
                        tooltip: 'Copy public key',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _scanned ? _resetScanner : null,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Rescan'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _publicKey.isEmpty
                            ? null
                            : () => _copy(_publicKey, 'Public key'),
                        icon: const Icon(Icons.copy_all),
                        label: const Text('Copy Public Key'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
