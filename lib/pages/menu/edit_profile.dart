import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artefacto/model/user_model.dart';
import 'package:artefacto/service/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  final User user;

  const EditProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _editFormKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  File? _newProfileImage;
  String? _imageError;
  bool _isUpdating = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _errorMessage;
  String? _successMessage;

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
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSize = await file.length();
      final ext = pickedFile.path.split('.').last.toLowerCase();
      final allowedTypes = ['jpg', 'jpeg', 'png', 'gif'];

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

  Future<void> _handleSubmit() async {
    if (!_editFormKey.currentState!.validate()) return;
    if (_imageError != null) return;

    // Check if email is being changed
    final originalEmail = widget.user.email;
    final newEmail = _emailController.text.trim();
    final isEmailChanged = originalEmail != newEmail && newEmail.isNotEmpty;

    // Validate current password is required for email changes OR new password
    if ((isEmailChanged || _newPasswordController.text.isNotEmpty) &&
        _currentPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage =
            'Password saat ini diperlukan untuk mengubah email atau password';
      });
      return;
    }

    // Validate password match if new password is provided
    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Password baru dan konfirmasi tidak cocok';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    print('[EditProfilePage] Submitting profile update...');
    print('[EditProfilePage] Original email: $originalEmail');
    print('[EditProfilePage] New email: $newEmail');
    print('[EditProfilePage] Email changed: $isEmailChanged');
    print(
        '[EditProfilePage] Current password provided: ${_currentPasswordController.text.isNotEmpty}');
    print(
        '[EditProfilePage] New password provided: ${_newPasswordController.text.isNotEmpty}');

    // If email is being changed, validate current password first
    if (isEmailChanged && _currentPasswordController.text.isNotEmpty) {
      print(
          '[EditProfilePage] Email change detected, validating current password first...');

      // Try to validate current password by making a test login request
      try {
        final authService = AuthService();
        final testResponse = await authService.login(
          email: originalEmail ?? '',
          password: _currentPasswordController.text,
        );

        print(
            '[EditProfilePage] Password validation response: ${testResponse['success']}');

        if (!testResponse['success']) {
          setState(() {
            _errorMessage = 'Password saat ini salah';
            _isUpdating = false; // Reset loading state
          });
          return;
        }
      } catch (e) {
        print('[EditProfilePage] Password validation error: $e');
        setState(() {
          _errorMessage = 'Gagal memvalidasi password saat ini';
          _isUpdating = false; // Reset loading state
        });
        return;
      }
    }

    try {
      final response = await _authService.updateProfile(
        username: _nameController.text.trim().isNotEmpty
            ? _nameController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        currentPassword: _currentPasswordController.text.isNotEmpty
            ? _currentPasswordController.text
            : null,
        newPassword: _newPasswordController.text.isNotEmpty
            ? _newPasswordController.text
            : null,
        profilePicture: _newProfileImage,
      );

      print('[EditProfilePage] Profile update response: $response');

      if (response['success']) {
        setState(() {
          _successMessage = 'Profil berhasil diperbarui!';
        });

        // Reset password fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        // Reset image
        setState(() {
          _newProfileImage = null;
        });

        if (mounted) {
          print(
              '[EditProfilePage] Profile update successful, returning true to ProfilePage');
          Navigator.pop(context, true); // Return true to indicate success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Gagal memperbarui profil');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.playfairDisplay(
            color: const Color(0xff233743),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff233743)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _editFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green.shade700, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.poppins(
                              color: Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xff233743).withOpacity(0.1),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _newProfileImage != null
                              ? Image.file(
                                  _newProfileImage!,
                                  fit: BoxFit.cover,
                                )
                              : widget.user.profilePicture != null &&
                                      widget.user.profilePicture!.isNotEmpty
                                  ? Image.network(
                                      '${widget.user.profilePicture!}?t=${DateTime.now().millisecondsSinceEpoch}', // Add cache buster
                                      key: ValueKey(
                                          '${widget.user.profilePicture!}_${DateTime.now().millisecondsSinceEpoch}'), // Force refresh
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[400],
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
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
                              color: const Color(0xff233743),
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
                ),
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _imageError!,
                      style: GoogleFonts.poppins(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 32),
                Text(
                  'Basic Information',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff233743),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  label: 'Username',
                  icon: Icons.person_outline,
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
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
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
                const SizedBox(height: 32),
                Text(
                  'Change Password',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff233743),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _currentPasswordController,
                  label: 'Password Saat Ini',
                  icon: Icons.lock_outline,
                  obscureText: !_showCurrentPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showCurrentPassword = !_showCurrentPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    // Check if email is being changed
                    final originalEmail = widget.user.email;
                    final newEmail = _emailController.text.trim();
                    final isEmailChanged =
                        originalEmail != newEmail && newEmail.isNotEmpty;

                    // Current password required for email changes OR new password
                    if ((isEmailChanged ||
                            _newPasswordController.text.isNotEmpty) &&
                        (value == null || value.isEmpty)) {
                      return 'Password saat ini wajib diisi untuk mengubah email atau password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _newPasswordController,
                  label: 'Password Baru',
                  icon: Icons.lock_outline,
                  obscureText: !_showNewPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showNewPassword = !_showNewPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'Password minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _confirmPasswordController,
                  label: 'Konfirmasi Password Baru',
                  icon: Icons.lock_outline,
                  obscureText: !_showConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showConfirmPassword = !_showConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty &&
                        value != _newPasswordController.text) {
                      return 'Password tidak cocok';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24), // Reduced from 40 to 24
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff233743),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Simpan Perubahan',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: const Color(0xff233743),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.grey[600],
        ),
        prefixIcon: Icon(icon, color: const Color(0xff233743), size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xff233743).withOpacity(0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xff233743).withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xff233743),
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: validator,
    );
  }
}
