import 'dart:convert';

import 'package:artefacto/pages/auth/signup_pages.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:artefacto/service/auth_service.dart';
import 'package:artefacto/pages/menu/home.dart';
import 'package:artefacto/pages/menu/admin/admin_dashboard_page.dart';
import 'package:artefacto/common/page_header.dart';
import 'package:artefacto/common/page_heading.dart';
import 'package:artefacto/common/custom_input_field.dart';
import 'package:artefacto/common/custom_form_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/user_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Simpan user ke SharedPreferences
  Future<void> _saveUserToPrefs(UserData userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData.toJson()));
  }

  Future<void> _handleLogin() async {
    if (_loginFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (result['success'] == true) {
        final userData = result['data'] as UserData;
        await _saveUserToPrefs(userData);

        final isAdmin = userData.user?.role ?? false;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                isAdmin ? const AdminDashboardPage() : const HomePage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: Column(
          children: [
            const PageHeader(),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xffF5F0DF),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _loginFormKey,
                    child: Column(
                      children: [
                        const PageHeading(title: 'Log-in'),
                        CustomInputField(
                          controller: _emailController,
                          labelText: 'Email',
                          hintText: 'Your email id',
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Email wajib diisi';
                            }
                            if (!EmailValidator.validate(textValue)) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          hintText: 'Your password',
                          obscureText: true,
                          suffixIcon: true,
                          validator: (textValue) {
                            if (textValue == null || textValue.isEmpty) {
                              return 'Password wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomFormButton(
                          innerText: _isLoading ? 'Logging in...' : 'Login',
                          onPressed: _isLoading ? null : _handleLogin,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: size.width * 0.8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Don\'t have an account? ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupPage(),
                                  ),
                                ),
                                child: const Text(
                                  'Sign-up',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
