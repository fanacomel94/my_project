import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
// Removed custom random key generation; use CryptoManager
import 'package:flutter/services.dart';
//import 'package:cryptography/cryptography.dart';
import 'cryptomanager.dart';
import 'main.dart';

class KeyGenerationPage extends StatefulWidget {
  const KeyGenerationPage({super.key});

  @override
  State<KeyGenerationPage> createState() => _KeyGenerationPageState();
}

class _KeyGenerationPageState extends State<KeyGenerationPage> {
  late String _publicKey = '';
  // Private key is stored securely; not exposed in the UI

  @override
  void initState() {
    super.initState();
    _initKeys();
  }

  Future<void> _initKeys() async {
    try {
      await CryptoManager.ensureKeysExist();
      final pubs = await CryptoManager.getStoredPublicKeys();
      _publicKey = pubs['x25519_public'] ?? '';
    } catch (e) {
      // Fallback if generation fails
      _publicKey = '';
    }
    if (mounted) setState(() {});
  }

  Future<void> _refreshKeys() async {
    // Generate a fresh keypair, store private seed and update public key
    try {
      final newPubs = await CryptoManager.rotateKeys();
      _publicKey = newPubs['x25519_public'] ?? '';
      if (mounted) setState(() {});
    } catch (e) {
      // fallback: random public key
      setState(() {
        _publicKey = '';
      });
    }
  }

  Future<void> _copyToClipboard(String text, String label) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label copied to clipboard')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to copy to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = isDark
            ? const Color(0xFFAABF3F)
            : const Color(0xFF6B8E23);
        final surfaceColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Key Generation'),
            centerTitle: true,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)]
                    : [Colors.white, const Color(0xFFF5F5F0)],
              ),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // QR Code
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _publicKey.isEmpty
                            ? const SizedBox(height: 250, width: 250)
                            : QrImageView(
                                data: _publicKey,
                                version: QrVersions.auto,
                                size: 250.0,
                                backgroundColor: Colors.white,
                                gapless: false,
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Private key note
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.12),
                        ),
                      ),
                      child: Text(
                        'Private key is stored securely on this device.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Public Key display and copy
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.18),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public Key',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _publicKey,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColor,
                                  fontFamily: 'monospace',
                                ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _copyToClipboard(_publicKey, 'Public Key'),
                              icon: const Icon(Icons.content_copy, size: 18),
                              label: const Text('Copy'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _refreshKeys,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Generate New Keys'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
