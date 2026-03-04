import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Use adminLogin procedure (supports admin accounts)
      final result = await ApiService.mutate(
        'auth.adminLogin',
        input: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final auth = context.read<AuthProvider>();
        await auth.checkAuth();
        if (!mounted) return;
        if (auth.isLoggedIn) {
          Navigator.pushReplacementNamed(context, '/role-select');
        } else {
          setState(() => _error = 'تم تسجيل الدخول لكن تعذّر تحميل البيانات.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errMsg = e.toString();
      if (errMsg.contains('UNAUTHORIZED') || errMsg.contains('غير صحيح')) {
        setState(() => _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      } else {
        setState(() => _error = 'حدث خطأ. تأكد من الاتصال بالإنترنت.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

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
                  const SizedBox(height: 20),
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

                  // Error message
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Email field
                  Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      'البريد الإلكتروني',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      hintStyle: const TextStyle(color: AppColors.muted),
                      prefixIcon: const Icon(Icons.email_outlined,
                          color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل البريد الإلكتروني';
                      if (!v.contains('@')) return 'بريد إلكتروني غير صحيح';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Password field
                  Align(
                    alignment: Alignment.centerRight,
                    child: const Text(
                      'كلمة المرور',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(color: AppColors.text),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: const TextStyle(color: AppColors.muted),
                      prefixIcon: const Icon(Icons.lock_outline,
                          color: AppColors.muted),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        child: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.muted,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 36),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, color: Colors.black),
                                SizedBox(width: 8),
                                Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
