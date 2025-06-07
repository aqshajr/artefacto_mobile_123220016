import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:artefacto/common/page_header.dart';
import 'package:artefacto/common/page_heading.dart';
import 'package:artefacto/common/custom_input_field.dart';
import 'package:artefacto/common/custom_form_button.dart';
import 'package:artefacto/model/user_model.dart';
import 'package:artefacto/service/user_service.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _editFormKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  File? _newProfileImage;
  String? _imageError;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.username);
    _emailController = TextEditingController(text: widget.user.email);
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedImage == null) return;

      final file = File(pickedImage.path);
      final fileSize = await file.length();
      final allowedTypes = ['jpg', 'jpeg', 'png', 'gif'];
      final ext = pickedImage.path.split('.').last.toLowerCase();

      if (!allowedTypes.contains(ext)) {
        setState(() {
          _imageError = 'Hanya file gambar (JPG, PNG, GIF) yang diperbolehkan';
          _newProfileImage = null;
        });
        return;
      }

      if (fileSize > 5 * 1024 * 1024) {
        setState(() {
          _imageError = 'Ukuran file maksimal 5MB';
          _newProfileImage = null;
        });
        return;
      }

      setState(() {
        _newProfileImage = file;
        _imageError = null;
      });
    } catch (e) {
      setState(() {
        _imageError = 'Gagal memilih gambar: $e';
      });
    }
  }

  void _handleUpdateProfile() async {
    if (!_editFormKey.currentState!.validate()) return;
    if (_imageError != null) return;

    // Validate password match if new password is provided
    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru dan konfirmasi tidak cocok'),
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    final updatedUser = User(
      id: widget.user.id,
      username: _nameController.text.trim(),
      email: _emailController.text.trim(),
      currentPassword: _currentPasswordController.text.isNotEmpty
          ? _currentPasswordController.text
          : null,
      newPassword: _newPasswordController.text.isNotEmpty
          ? _newPasswordController.text
          : null,
      confirmNewPassword: _confirmPasswordController.text.isNotEmpty
          ? _confirmPasswordController.text
          : null,
    );

    try {
      final result = await UserApi.updateUserWithImage(
        updatedUser,
        _newProfileImage,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final userData = result['data'];
        if (userData != null && userData['data'] != null) {
          final updatedUser = UserModel.fromJson(userData).data?.user;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              duration: Duration(seconds: 2),
            ),
          );

          Navigator.pop(context, updatedUser);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui tetapi data tidak valid'),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memperbarui profil'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xffFFFFFF),
        body: SingleChildScrollView(
          child: Form(
            key: _editFormKey,
            child: Column(
              children: [
                const PageHeader(),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xffF5F0DF),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      const PageHeading(title: 'Edit Profile'),
                      const SizedBox(height: 16),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.brown,
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: _getProfileImageWidget(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.brown,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_imageError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _imageError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        controller: _nameController,
                        labelText: 'Username',
                        hintText: 'Username Anda',
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
                        hintText: 'Email Anda',
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
                        controller: _currentPasswordController,
                        labelText: 'Password Saat Ini',
                        hintText: 'Masukkan password saat ini',
                        isDense: true,
                        obscureText: true,
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return 'Password saat ini wajib diisi untuk mengubah password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        controller: _newPasswordController,
                        labelText: 'Password Baru',
                        hintText: 'Masukkan password baru (opsional)',
                        isDense: true,
                        obscureText: true,
                        validator: (value) {
                          if (value != null && value.isNotEmpty && value.length < 8) {
                            return 'Password minimal 8 karakter';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        controller: _confirmPasswordController,
                        labelText: 'Konfirmasi Password Baru',
                        hintText: 'Masukkan kembali password baru',
                        isDense: true,
                        obscureText: true,
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty &&
                              (value == null || value.isEmpty)) {
                            return 'Konfirmasi password wajib diisi';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Password tidak cocok';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Biarkan kosong jika tidak ingin mengubah password',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      _isUpdating
                          ? const CircularProgressIndicator()
                          : CustomFormButton(
                        innerText: 'Perbarui Profil',
                        onPressed: _handleUpdateProfile,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(color: Colors.brown),
                        ),
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

  Widget _getProfileImageWidget() {
    if (_newProfileImage != null) {
      return Image.file(
        _newProfileImage!,
        fit: BoxFit.cover,
      );
    } else if (widget.user.profilePicture != null &&
        widget.user.profilePicture!.isNotEmpty) {
      return Image.network(
        widget.user.profilePicture!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.person,
            size: 60,
            color: Colors.grey,
          );
        },
      );
    } else {
      return const Icon(
        Icons.person,
        size: 60,
        color: Colors.grey,
      );
    }
  }
}