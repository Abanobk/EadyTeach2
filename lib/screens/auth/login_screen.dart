import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'ET',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'EASY TECH',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'إدارة المنزل الذكي',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'سجّل دخولك للوصول إلى جميع الخدمات',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openLogin(context),
                    icon: const Icon(Icons.login, color: Colors.black),
                    label: const Text('تسجيل الدخول'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => _checkLogin(context),
                  child: const Text(
                    'تحقق من تسجيل الدخول',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLogin(BuildContext context) async {
    final loginUrl = '${ApiService.baseUrl}/api/oauth/login?returnTo=/';
    // Open in browser - user logs in then comes back
    // Use url_launcher to open in browser
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _WebLoginScreen(url: loginUrl),
      ),
    ).then((_) => _checkLogin(context));
  }

  void _checkLogin(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    if (auth.isLoggedIn && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/role-select');
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تسجيل الدخول بعد. حاول مرة أخرى.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _WebLoginScreen extends StatefulWidget {
  final String url;
  const _WebLoginScreen({required this.url});

  @override
  State<_WebLoginScreen> createState() => _WebLoginScreenState();
}

class _WebLoginScreenState extends State<_WebLoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_browser, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'سيتم فتح صفحة تسجيل الدخول في المتصفح',
              style: TextStyle(color: AppColors.text, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.url,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('رجوع'),
            ),
          ],
        ),
      ),
    );
  }
}
