import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'encryption_page.dart';
import 'key_generation.dart';
import 'scan_receiver.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'WA-Shield',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const MyHomePage(title: 'WA-Shield'),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    const oliveGreen = Color(0xFF6B8E23);
    const white = Color(0xFFFFFFFF);
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: oliveGreen,
        secondary: oliveGreen,
        tertiary: const Color(0xFF8B9D3F),
        surface: white,
        error: const Color(0xFFB3261E),
      ),
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: oliveGreen,
        foregroundColor: white,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const oliveGreen = Color(0xFF8B9D3F);
    const grey = Color(0xFF2C2C2C);
    const darkGreyBg = Color(0xFF1A1A1A);
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: oliveGreen,
        secondary: oliveGreen,
        tertiary: const Color(0xFFAABF3F),
        surface: grey,
        error: const Color(0xFFF2B8B5),
      ),
      scaffoldBackgroundColor: darkGreyBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: grey,
        foregroundColor: oliveGreen,
        elevation: 0,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
          'Use "Generate your Key" to create two keys. Then open Encrypt/Decrypt Message to use them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('WA-Shield'),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  size: 28,
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
                colors: themeProvider.isDarkMode
                    ? [const Color(0xFF1A1A1A), const Color(0xFF2C2C2C)]
                    : [Colors.white, const Color(0xFFF5F5F0)],
              ),
            ),
            child: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Header Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: themeProvider.isDarkMode
                              ? const Color(0xFF8B9D3F).withValues(alpha: 0.2)
                              : const Color(0xFF6B8E23).withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.lock_outline,
                          size: 80,
                          color: themeProvider.isDarkMode
                              ? const Color(0xFF8B9D3F)
                              : const Color(0xFF6B8E23),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Title
                      Text(
                        'Secure Chat',
                        style: Theme.of(context).textTheme.headlineLarge
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode
                                  ? const Color(0xFF8B9D3F)
                                  : const Color(0xFF6B8E23),
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Subtitle
                      Text(
                        'Protect Your Conversations',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Description
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[900]?.withValues(alpha: 0.5)
                              : Colors.grey[100]?.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: themeProvider.isDarkMode
                                ? const Color(0xFF8B9D3F).withValues(alpha: 0.3)
                                : const Color(
                                    0xFF6B8E23,
                                  ).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          'Choose how you want to secure your messages: encrypt for privacy or decrypt to read protected conversations.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[300]
                                    : Colors.grey[700],
                                height: 1.6,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 60),
                      // Action Buttons: stacked full-width buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.lock_outline,
                              label: 'Encrypt/Decrypt Message',
                              isDark: themeProvider.isDarkMode,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EncryptionPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.vpn_key,
                              label: 'Key Generation',
                              isDark: themeProvider.isDarkMode,
                              isSecondary: true,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const KeyGenerationPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.qr_code_scanner,
                              label: 'Scan Receiver',
                              isDark: themeProvider.isDarkMode,
                              isSecondary: true,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ScanReceiverPage(),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Small help circle with question mark, aligned to right
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => _showHelpDialog(context),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: themeProvider.isDarkMode
                                    ? const Color(0xFF8B9D3F)
                                    : const Color(0xFF6B8E23),
                                child: const Text(
                                  '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isDark,
    bool isSecondary = false,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isSecondary
              ? LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF8B9D3F).withValues(alpha: 0.3),
                          const Color(0xFF8B9D3F).withValues(alpha: 0.1),
                        ]
                      : [
                          const Color(0xFF6B8E23).withValues(alpha: 0.1),
                          const Color(0xFF6B8E23).withValues(alpha: 0.05),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF8B9D3F), const Color(0xFF7A8E35)]
                      : [const Color(0xFF6B8E23), const Color(0xFF5A7C1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF8B9D3F).withValues(alpha: 0.4)
                : const Color(0xFF6B8E23).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0xFF8B9D3F).withValues(alpha: 0.2)
                  : const Color(0xFF6B8E23).withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSecondary
                  ? (isDark ? const Color(0xFF8B9D3F) : const Color(0xFF6B8E23))
                  : Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isSecondary
                    ? (isDark
                          ? const Color(0xFF8B9D3F)
                          : const Color(0xFF6B8E23))
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
