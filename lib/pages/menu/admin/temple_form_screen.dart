import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../model/temple_model.dart';
import '../../../service/temple_service.dart';

class TempleFormScreen extends StatefulWidget {
  final Temple? temple;

  const TempleFormScreen({super.key, this.temple});

  @override
  State<TempleFormScreen> createState() => _TempleFormScreenState();
}

class _TempleFormScreenState extends State<TempleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _funfactTitleController;
  late TextEditingController _funfactDescriptionController;
  late TextEditingController _locationUrlController;

  File? _selectedImageFile;
  bool _isLoading = false;
  bool _isEditMode = false;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.temple != null;
    _initializeControllers();
  }

  void _initializeControllers() {
    final temple = widget.temple;
    _titleController = TextEditingController(text: temple?.title ?? '');
    _descriptionController = TextEditingController(
      text: temple?.description ?? '',
    );
    _funfactTitleController = TextEditingController(
      text: temple?.funfactTitle ?? '',
    );
    _funfactDescriptionController = TextEditingController(
      text: temple?.funfactDescription ?? '',
    );
    _locationUrlController = TextEditingController(
      text: temple?.locationUrl ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _funfactTitleController.dispose();
    _funfactDescriptionController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();
        final allowedTypes = ['jpg', 'jpeg', 'png', 'gif'];
        final ext = pickedFile.path.split('.').last.toLowerCase();
        if (!allowedTypes.contains(ext)) {
          setState(() {
            _imageError = 'File harus berupa gambar (JPG, PNG, GIF)';
            _selectedImageFile = null;
          });
          return;
        }
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            _imageError = 'Ukuran file maksimal 5MB';
            _selectedImageFile = null;
          });
          return;
        }
        setState(() {
          _selectedImageFile = file;
          _imageError = null;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Gagal memilih gambar: $e');
    }
  }

  Future<void> _saveTemple() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditMode && _selectedImageFile == null) {
      setState(() {
        _imageError = 'Harap pilih gambar untuk candi baru';
      });
      return;
    }
    if (_imageError != null) return;

    setState(() => _isLoading = true);

    try {
      Temple savedTemple;
      if (!_isEditMode) {
        savedTemple = await TempleService.createTempleWithImage(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          funfactTitle: _funfactTitleController.text.trim(),
          funfactDescription: _funfactDescriptionController.text.trim(),
          locationUrl: _locationUrlController.text.trim(),
          imageFile: _selectedImageFile,
        );
      } else {
        savedTemple = await TempleService.updateTempleWithImage(
          templeId: widget.temple!.templeID!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          funfactTitle: _funfactTitleController.text.trim(),
          funfactDescription: _funfactDescriptionController.text.trim(),
          locationUrl: _locationUrlController.text.trim(),
          imageFile: _selectedImageFile,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, {
        'temple': savedTemple,
        'image': _selectedImageFile,
      });
    } catch (e) {
      _showErrorSnackbar('Gagal menyimpan candi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? "Edit Candi" : "Tambah Candi Baru",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff233743),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        _buildTextFormField(
                          controller: _titleController,
                          labelText: "Judul Candi*",
                          validator:
                              (v) => _validateRequired(
                                v,
                                minLength: 3,
                                fieldName: 'Judul candi',
                              ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _descriptionController,
                          labelText: "Deskripsi*",
                          maxLines: 3,
                          validator:
                              (v) => _validateRequired(
                                v,
                                minLength: 10,
                                fieldName: 'Deskripsi candi',
                              ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _funfactTitleController,
                          labelText: "Judul Funfact*",
                          validator:
                              (v) => _validateRequired(
                                v,
                                minLength: 3,
                                fieldName: 'Judul funfact',
                              ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _funfactDescriptionController,
                          labelText: "Deskripsi Funfact*",
                          maxLines: 3,
                          validator:
                              (v) => _validateRequired(
                                v,
                                minLength: 10,
                                fieldName: 'Deskripsi funfact',
                              ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          controller: _locationUrlController,
                          labelText: "URL Lokasi*",
                          validator: _validateUrl,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.image),
                          label: const Text("Pilih Gambar dari Galeri"),
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff233743),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_selectedImageFile != null) ...[
                          Text(
                            "Gambar yang dipilih:",
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Image.file(
                            _selectedImageFile!,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ] else if (_isEditMode &&
                            widget.temple?.imageUrl != null) ...[
                          Text(
                            "Gambar saat ini:",
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Image.network(
                            widget.temple!.imageUrl! +
                                '?v=${DateTime.now().millisecondsSinceEpoch}',
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 150),
                          ),
                          Text(
                            "Pilih gambar baru untuk mengubah",
                            style: GoogleFonts.openSans(fontSize: 12),
                          ),
                        ] else if (!_isEditMode) ...[
                          Text(
                            "Harap pilih gambar untuk candi baru",
                            style: GoogleFonts.openSans(color: Colors.red),
                          ),
                        ],
                        if (_imageError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _imageError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _saveTemple,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff233743),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: Text(
                            _isEditMode ? "Simpan Perubahan" : "Tambah Candi",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  String? _validateRequired(
    String? value, {
    int minLength = 1,
    String? fieldName,
  }) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? "Field ini"} wajib diisi';
    }
    if (minLength > 1 && value.trim().length < minLength) {
      return '${fieldName ?? "Field ini"} minimal $minLength karakter';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'URL lokasi wajib diisi';
    }
    final uri = Uri.tryParse(value.trim());
    if (uri == null || (!uri.isAbsolute)) {
      return 'URL lokasi wajib diisi dengan format yang valid';
    }
    return null;
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white70,
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }
}
