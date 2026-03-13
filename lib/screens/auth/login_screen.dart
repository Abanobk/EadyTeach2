import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/notification_service.dart';
import 'signup_screen.dart';

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
  bool _googleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String? _error;

  static const _keyRememberMe = 'remember_me';

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _rememberMe = prefs.getBool(_keyRememberMe) ?? true);
  }

  Future<void> _saveRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
  }

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
    ApiService.setPersistSession(_rememberMe);

    try {
      // Try adminLogin first (for admins/staff), then userLogin (for customers)
      Map<String, dynamic>? result;
      try {
        result = await ApiService.mutate(
          'auth.adminLogin',
          input: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
      } catch (_) {
        // Admin login failed (wrong role, wrong credentials, etc.) – try user login
        result = await ApiService.mutate(
          'auth.userLogin',
          input: {
            'email': _emailController.text.trim(),
            'password': _passwordController.text,
          },
        );
      }

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        final auth = context.read<AuthProvider>();
        final data = result['data'];
        if (data != null && data is Map<String, dynamic> && data['user'] != null) {
          auth.setUserFromLoginData(data);
        } else {
          await auth.checkAuth();
        }
        if (!mounted) return;
        if (auth.isLoggedIn) {
          try {
            await NotificationService().getAndSaveFcmToken();
            unawaited(NotificationService().updateBadgeFromServer());
          } catch (e) {
            print('FCM_ERROR: $e');
          }
          Navigator.pushReplacementNamed(context, '/role-select');
        } else {
          setState(() => _error = 'تم تسجيل الدخول لكن تعذّر تحميل البيانات.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      // طباعة الخطأ الحقيقي في التيرمنال للمساعدة في التشخيص (لن يراه المستخدم)
      // ignore: avoid_print
      print('LOGIN_ERROR: $e');
      final errMsg = e.toString();
      if (errMsg.contains('UNAUTHORIZED') || errMsg.contains('غير صحيح') || errMsg.contains('غير نشط')) {
        setState(() => _error = 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      } else {
        setState(() => _error = 'خطأ: ${errMsg.length > 120 ? errMsg.substring(0, 120) : errMsg}');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    ApiService.setPersistSession(_rememberMe);

    try {
      final result = await GoogleAuthService.signIn();
      if (result == null) {
        // User cancelled
        setState(() => _googleLoading = false);
        return;
      }

      if (!mounted) return;

      if (result['success'] == true) {
        final auth = context.read<AuthProvider>();
        final data = result['data'];
        if (data != null && data is Map<String, dynamic> && data['user'] != null) {
          auth.setUserFromLoginData(data);
        } else {
          await auth.checkAuth();
        }
        if (!mounted) return;
        if (auth.isLoggedIn) {
          try {
            await NotificationService().getAndSaveFcmToken();
            unawaited(NotificationService().updateBadgeFromServer());
          } catch (e) {
            print('FCM_ERROR: $e');
          }
          Navigator.pushReplacementNamed(context, '/role-select');
        } else {
          setState(() => _error = 'تم تسجيل الدخول لكن تعذّر تحميل البيانات.');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'فشل تسجيل الدخول بـ Google. حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
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

                  const SizedBox(height: 40),

                  // Google Sign In button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _googleLoading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF3C3C3C), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: AppColors.card,
                      ),
                      child: _googleLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Google logo
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFF4285F4),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'تسجيل الدخول بـ Google',
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.muted.withOpacity(0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'أو',
                          style: TextStyle(color: AppColors.muted.withOpacity(0.7), fontSize: 13),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.muted.withOpacity(0.3))),
                    ],
                  ),

                  const SizedBox(height: 20),

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
                          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.muted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.muted),
                      suffixIcon: GestureDetector(
                        onTap: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                      return null;
                    },
                    onFieldSubmitted: (_) => _login(),
                  ),

                  const SizedBox(height: 16),

                  // حفظ الحساب للتذكّر
                  InkWell(
                    onTap: () async {
                      final newVal = !_rememberMe;
                      setState(() => _rememberMe = newVal);
                      await _saveRememberMe(newVal);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (v) async {
                                setState(() => _rememberMe = v ?? true);
                                await _saveRememberMe(_rememberMe);
                              },
                              activeColor: AppColors.primary,
                              fillColor: MaterialStateProperty.resolveWith((states) {
                                if (states.contains(MaterialState.selected)) return AppColors.primary;
                                return Colors.transparent;
                              }),
                              side: BorderSide(color: AppColors.muted.withOpacity(0.6)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'حفظ الحساب للتذكّر — التنقّل بدون إعادة الدخول',
                            style: TextStyle(color: AppColors.text, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

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

                  const SizedBox(height: 20),

                  // Sign Up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ليس لديك حساب؟ ',
                        style: TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignupScreen()),
                          );
                        },
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
  }
}
