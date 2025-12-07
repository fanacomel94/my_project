import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'cryptomanager.dart';

class EncryptionPage extends StatefulWidget {
  const EncryptionPage({super.key});

  @override
  State<EncryptionPage> createState() => _EncryptionPageState();
}

class _EncryptionPageState extends State<EncryptionPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientPublicKeyController =
      TextEditingController();
  late String _myPrivateKeyBase64; // Loaded from secure storage
  String _outputText = '';
  String _outputLabel = ''; // Track encryption/decryption action

  @override
  void initState() {
    super.initState();
    // Load my private key from secure storage (generated during key generation)
    _loadMyPrivateKey();
  }

  // Secure storage instance (uses platform keystore/keychain)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _loadMyPrivateKey() async {
    try {
      final stored = await _secureStorage.read(
        key: 'wa_shield_x25519_private_key',
      );
      if (stored != null && stored.isNotEmpty) {
        _myPrivateKeyBase64 = stored;
      } else {
        // If no private key exists, prompt user to generate one first
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please generate a key pair first in the Key Generation page',
              ),
            ),
          );
        }
        _myPrivateKeyBase64 = '';
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading private key: $e')),
        );
      }
      _myPrivateKeyBase64 = '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _recipientPublicKeyController.dispose();
    super.dispose();
  }

  // Encrypt message using ECDH-derived AES key
  Future<void> _performEncryption() async {
    if (_myPrivateKeyBase64.isEmpty) {
      _showError(
        'Private key not loaded. Please restart the app or generate keys.',
      );
      return;
    }
    if (_recipientPublicKeyController.text.isEmpty) {
      _showError('Recipient public key is empty.');
      return;
    }
    if (_messageController.text.isEmpty) {
      _showError('Message is empty.');
      return;
    }

    try {
      // Step 1: Compute shared secret via ECDH (derives AES key)
      final sharedSecretBase64 =
          await CryptoManager.computeSharedSecretAesKeyBase64(
            _recipientPublicKeyController.text,
          );

      // Step 2: Encrypt message using the derived AES key
      final encryptedPayload = await CryptoManager.encryptAES256GCM(
        _messageController.text,
        sharedSecretBase64,
      );

      setState(() {
        _outputLabel = 'Encrypted Text';
        _outputText = encryptedPayload;
      });
    } catch (e) {
      _showError('Encryption failed: ${e.toString()}');
    }
  }

  // Decrypt message using ECDH-derived AES key
  Future<void> _performDecryption() async {
    if (_myPrivateKeyBase64.isEmpty) {
      _showError(
        'Private key not loaded. Please restart the app or generate keys.',
      );
      return;
    }
    if (_recipientPublicKeyController.text.isEmpty) {
      _showError('Recipient public key is empty.');
      return;
    }
    if (_messageController.text.isEmpty) {
      _showError('Encrypted message is empty.');
      return;
    }

    try {
      // Step 1: Compute shared secret (derives AES key)
      final sharedSecretBase64 =
          await CryptoManager.computeSharedSecretAesKeyBase64(
            _recipientPublicKeyController.text,
          );

      // Step 2: Decrypt message using the derived AES key
      final decryptedMessage = await CryptoManager.decryptAES256GCM(
        _messageController.text,
        sharedSecretBase64,
      );

      // Check if decryption returned an error (wrong key or tampered message)
      if (decryptedMessage.startsWith('Error:')) {
        _showError(decryptedMessage);
      } else {
        setState(() {
          _outputLabel = 'Decrypted Text';
          _outputText = decryptedMessage;
        });
      }
    } catch (e) {
      _showError('Decryption failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _copyToClipboard() {
    if (_outputText.isNotEmpty) {
      // Copy the encrypted/decrypted text
      Clipboard.setData(ClipboardData(text: _outputText));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
      }
    }
  }

  void _clearAll() {
    _messageController.clear();
    _recipientPublicKeyController.clear();
    setState(() {
      _outputText = '';
      _outputLabel = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final isDark = themeProvider.isDarkMode;
        final primaryColor = isDark
            ? const Color(0xFF8B9D3F)
            : const Color(0xFF6B8E23);
        final textColor = isDark ? Colors.white : Colors.black87;
        final hintColor = isDark ? Colors.grey[500] : Colors.grey[600];

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Icon(Icons.security, size: 24),
                const SizedBox(width: 12),
                const Expanded(child: Text('WA-Shield')),
                Icon(Icons.shield, size: 32),
              ],
            ),
            centerTitle: false,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  size: 24,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              ),
            ],
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
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message Input
                    _buildInputSection(
                      context,
                      label: 'Message',
                      controller: _messageController,
                      hintText: 'Enter your message',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      hintColor: hintColor,
                      textColor: textColor,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // Recipient Public Key Input
                    _buildInputSection(
                      context,
                      label: 'Recipient Public Key',
                      controller: _recipientPublicKeyController,
                      hintText: 'Receiver Public Key',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      hintColor: hintColor,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Encrypt',
                            onPressed: _performEncryption,
                            isPrimary: true,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            label: 'Decrypt',
                            onPressed: _performDecryption,
                            isPrimary: false,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            label: 'Clear',
                            onPressed: _clearAll,
                            isPrimary: false,
                            isDark: isDark,
                            primaryColor: primaryColor,
                            isOutlined: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Output Section
                    if (_outputText.isNotEmpty) ...[
                      Text(
                        _outputLabel,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey[900]?.withValues(alpha: 0.6)
                              : Colors.grey[100]?.withValues(alpha: 0.6),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display encrypted or decrypted text
                            SelectableText(
                              _outputText,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: textColor,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _copyToClipboard,
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
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputSection(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required String hintText,
    required bool isDark,
    required Color primaryColor,
    required Color? hintColor,
    required Color textColor,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: hintColor),
            filled: true,
            fillColor: isDark
                ? Colors.grey[900]?.withValues(alpha: 0.5)
                : Colors.grey[100]?.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: TextStyle(color: textColor),
          cursorColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required bool isDark,
    required Color primaryColor,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? primaryColor
            : primaryColor.withValues(alpha: 0.3),
        foregroundColor: isPrimary ? Colors.white : primaryColor,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: isPrimary ? 4 : 0,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
