import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:growlit_mobile/features/auth/presentation/screens/beranda_screen.dart';
import 'package:growlit_mobile/services/local_notification_service.dart';
import 'package:growlit_mobile/services/session_service.dart';
import 'package:growlit_mobile/theme/colors.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text;

      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showError('Email atau password salah.');
        return;
      }

      final data = query.docs.first.data();
      final storedEmail = (data['email'] ?? '').toString().trim().toLowerCase();
      final storedPassword = (data['password'] ?? '').toString();
      final storedUsername = (data['username'] ?? '').toString().trim();

      final isValid = storedEmail == email && storedPassword == password;

      if (!isValid) {
        _showError('Email atau password salah.');
        return;
      }

      await SessionService.instance.saveSession(
        username: storedUsername.isEmpty ? 'User' : storedUsername,
        email: storedEmail,
      );

      await GrowlitLocalNotificationService.instance.showAlert(
        title: 'Login berhasil',
        body:
            'Selamat datang, ${storedUsername.isEmpty ? 'User' : storedUsername}',
        payload: 'login_success',
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BerandaScreen(
            username: storedUsername.isEmpty ? 'User' : storedUsername,
            email: storedEmail,
          ),
        ),
      );
    } on FirebaseException catch (error) {
      _showError(error.message ?? 'Gagal login ke Firestore.');
    } catch (_) {
      _showError('Terjadi kesalahan saat login.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9F3),
              Color(0xFFEAF3BE),
              AppColors.lightGreen,
            ],
            stops: [0.0, 0.36, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      Hero(
                        tag: 'growlit-logo',
                        child: Image.asset(
                          'asset/img/logo.png',
                          width: 108,
                          height: 108,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 2.0,
                                sigmaY: 2.0,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    22,
                                    22,
                                    24,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.96),
                                    borderRadius: BorderRadius.circular(24.0),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      width: 1.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.darkGreen.withValues(
                                          alpha: 0.10,
                                        ),
                                        blurRadius: 28,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Login',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayMedium
                                            ?.copyWith(
                                              color: AppColors.darkGreen,
                                              fontSize: 30,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Masuk dengan data yang tersimpan di Firestore.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppColors.darkGreen
                                                  .withValues(alpha: 0.68),
                                              height: 1.35,
                                            ),
                                      ),
                                      const SizedBox(height: 26),
                                      _buildTextField(
                                        controller: _emailController,
                                        context: context,
                                        labelText: 'Email',
                                        hintText: 'Masukkan alamat email',
                                        icon: Icons.person_outline,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        validator: (value) {
                                          final text = value?.trim() ?? '';
                                          if (text.isEmpty) {
                                            return 'Email wajib diisi';
                                          }
                                          if (!text.contains('@')) {
                                            return 'Format email tidak valid';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                      _buildTextField(
                                        controller: _passwordController,
                                        context: context,
                                        labelText: 'Password',
                                        hintText: 'Masukkan kata sandi',
                                        icon: Icons.lock_outline,
                                        obscureText: !_isPasswordVisible,
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                            ? 'Password wajib diisi'
                                            : null,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordVisible
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.darkGreen
                                                .withValues(alpha: 0.72),
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _isPasswordVisible =
                                                  !_isPasswordVisible;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      SizedBox(
                                        width: 120,
                                        child: ElevatedButton(
                                          onPressed: _isLoading
                                              ? null
                                              : _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppColors.resedaGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: const StadiumBorder(),
                                            elevation: 0,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Text('Login'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required BuildContext context,
    required String labelText,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: AppColors.resedaGreen.withValues(alpha: 0.55),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.darkGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(color: AppColors.darkGreen),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.darkGreen.withValues(alpha: 0.42),
            ),
            prefixIcon: Icon(icon, color: AppColors.resedaGreen),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(
                color: AppColors.fernGreen,
                width: 1.4,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }
}
