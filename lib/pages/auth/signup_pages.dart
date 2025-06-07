import 'dart:io';

import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artefacto/common/page_header.dart';
import 'package:artefacto/common/page_heading.dart';
import 'package:artefacto/common/custom_input_field.dart';
import 'package:artefacto/common/custom_form_button.dart';
import 'package:artefacto/service/auth_service.dart';

import 'login_pages.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  File? _profileImage;
  String? _imageError;
  final _signupFormKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passConfirmController = TextEditingController();

  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final file = File(image.path);
      final fileSize = await file.length();
      final allowedTypes = ['jpg', 'jpeg', 'png', 'gif'];
      final ext = image.path.split('.').last.toLowerCase();
      if (!allowedTypes.contains(ext)) {
        setState(() {
          _imageError = 'File harus berupa gambar (JPG, PNG, GIF)';
          _profileImage = null;
        });
        return;
      }
      if (fileSize > 5 * 1024 * 1024) {
        setState(() {
          _imageError = 'Ukuran file maksimal 5MB';
          _profileImage = null;
        });
        return;
      }
      setState(() {
        _profileImage = file;
        _imageError = null;
      });
    } on PlatformException catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Future<void> _handleSignup() async {
    if (_signupFormKey.currentState!.validate()) {
      if (_imageError != null) return;
      final result = await _authService.register(
        username: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _passConfirmController.text,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Registration failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Form(
            key: _signupFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F0DF),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(title: 'Sign-up'),
                      const SizedBox(height: 16),
                      CustomInputField(
                        controller: _nameController,
                        labelText: 'Username',
                        hintText: 'Your username',
                        isDense: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username wajib diisi';
                          }
                          if (value.length < 3) {
                            return 'Username minimal 3 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        controller: _emailController,
                        labelText: 'Email',
                        hintText: 'Your email',
                        isDense: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email wajib diisi';
                          }
                          if (!EmailValidator.validate(value)) {
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
                        isDense: true,
                        obscureText: true,
                        suffixIcon: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (value.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        controller: _passConfirmController,
                        labelText: 'Confirm Password',
                        hintText: 'Re-type your password',
                        isDense: true,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          if (value != _passwordController.text) {
                            return 'Konfirmasi password harus sama dengan password';
                          }
                          return null;
                        },
                      ),
                      if (_imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _imageError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 22),
                      CustomFormButton(
                        innerText: 'Signup',
                        onPressed: _handleSignup,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff939393),
                            ),
                          ),
                          GestureDetector(
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                ),
                            child: const Text(
                              'Log-in',
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xff748288),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
