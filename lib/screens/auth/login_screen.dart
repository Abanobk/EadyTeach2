import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  bool _waitingForReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called when app comes back to foreground after browser
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForReturn) {
      setState(() => _waitingForReturn = false);
      _checkLogin();
    }
  }

  Future<void> _openLogin() async {
    final loginUrl = '${ApiService.baseUrl}/api/oauth/login?returnTo=/';
    final uri = Uri.parse(loginUrl);
    if (await canLaunchUrl(uri)) {
      setState(() => _waitingForReturn = true);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذّر فتح المتصفح. تأكد من وجود متصفح على الجهاز.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _checkLogin() async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuth();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/role-select');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تسجيل الدخول بعد. سجّل دخولك في المتصفح ثم ارجع للتطبيق.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

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

                if (_waitingForReturn) ...[
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    'أكمل تسجيل الدخول في المتصفح ثم ارجع للتطبيق',
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _checkLogin,
                    child: const Text(
                      'تحققت من تسجيل الدخول',
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ] else ...[
                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _openLogin,
                      icon: const Icon(Icons.login, color: Colors.black),
                      label: const Text('تسجيل الدخول'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _checkLogin,
                    child: const Text(
                      'تحقق من تسجيل الدخول',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
