import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import '../../../model/artifact_model.dart';
import '../../../service/artifact_service.dart';
import '../../../model/temple_model.dart';
import '../../../service/temple_service.dart';

class ArtifactFormScreen extends StatefulWidget {
  final Artifact? artifact; // Jika ada artifact, berarti mode edit

  const ArtifactFormScreen({super.key, this.artifact});

  @override
  State<ArtifactFormScreen> createState() => _ArtifactFormScreenState();
}

class _ArtifactFormScreenState extends State<ArtifactFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Add loading state to prevent multiple submissions
  bool _isLoading = false;

  // ... (controller declarations remain the same)
  late TextEditingController _templeIdController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _detailPeriodController;
  late TextEditingController _detailMaterialController;
  late TextEditingController _detailSizeController;
  late TextEditingController _detailStyleController;
  late TextEditingController _funfactTitleController;
  late TextEditingController _funfactDescriptionController;
  late TextEditingController _locationUrlController;
  late TextEditingController _imageUrlController;
  late File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();
  List<Temple> _templeList = [];
  bool _isTempleLoading = false;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai dari widget.artifact jika ada
    _templeIdController = TextEditingController(
      text: widget.artifact?.templeID?.toString() ?? '',
    );
    _titleController = TextEditingController(
      text: widget.artifact?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.artifact?.description ?? '',
    );
    _detailPeriodController = TextEditingController(
      text: widget.artifact?.detailPeriod ?? '',
    );
    _detailMaterialController = TextEditingController(
      text: widget.artifact?.detailMaterial ?? '',
    );
    _detailSizeController = TextEditingController(
      text: widget.artifact?.detailSize ?? '',
    );
    _detailStyleController = TextEditingController(
      text: widget.artifact?.detailStyle ?? '',
    );
    _funfactTitleController = TextEditingController(
      text: widget.artifact?.funfactTitle ?? '',
    );
    _funfactDescriptionController = TextEditingController(
      text: widget.artifact?.funfactDescription ?? '',
    );
    _locationUrlController = TextEditingController(
      text: widget.artifact?.locationUrl ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.artifact?.imageUrl ?? '',
    ); // Untuk tampilan lokal
    _selectedImageFile = null;
    _fetchTemples();
  }

  @override
  void dispose() {
    // Pastikan semua controller di-dispose
    _templeIdController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _detailPeriodController.dispose();
    _detailMaterialController.dispose();
    _detailSizeController.dispose();
    _detailStyleController.dispose();
    _funfactTitleController.dispose();
    _funfactDescriptionController.dispose();
    _locationUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memilih gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchTemples() async {
    setState(() => _isTempleLoading = true);
    try {
      final temples = await TempleService.getTemples();
      setState(() {
        _templeList = temples;
        _isTempleLoading = false;
      });
    } catch (e) {
      setState(() => _isTempleLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat daftar candi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _saveArtifact() async {
    // Prevent multiple submissions
    if (_isLoading) return;

    if (_formKey.currentState!.validate()) {
      if (_imageError != null) return;

      setState(() {
        _isLoading = true;
      });

      try {
        _formKey.currentState!.save();

        final int artifactId = widget.artifact?.artifactID ?? 0;
        final int templeId = int.parse(_templeIdController.text);
        final String templeTitle =
            widget.artifact?.templeTitle ?? 'Candi ${_templeIdController.text}';

        final newArtifact = Artifact(
          artifactID: artifactId,
          templeID: templeId,
          title: _titleController.text,
          description: _descriptionController.text,
          detailPeriod: _detailPeriodController.text,
          detailMaterial: _detailMaterialController.text,
          detailSize: _detailSizeController.text,
          detailStyle: _detailStyleController.text,
          funfactTitle: _funfactTitleController.text,
          funfactDescription: _funfactDescriptionController.text,
          locationUrl: _locationUrlController.text,
          imageUrl: null,
          templeTitle: templeTitle,
          isBookmarked: false,
          isRead: false,
        );

        Artifact? resultArtifact;

        if (widget.artifact == null) {
          // Create new artifact
          resultArtifact = await ArtifactService.createArtifactWithImage(
            artifact: newArtifact,
            imageFile: _selectedImageFile,
          );
        } else {
          // Update existing artifact
          resultArtifact = await ArtifactService.updateArtifactWithImage(
            newArtifact,
            _selectedImageFile,
          );
        }

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                widget.artifact == null
                    ? 'Artefak berhasil ditambahkan!'
                    : 'Artefak berhasil diperbarui!'
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back with result
        Navigator.pop(context, {
          'artifact': resultArtifact,
          'image': _selectedImageFile,
          'action': widget.artifact == null ? 'create' : 'update',
        });

      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan artefak: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.artifact == null ? "Tambah Artefak Baru" : "Edit Artefak",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff233743),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
            children: [
        Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ... (all form fields remain the same)
              _isTempleLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                value: _templeIdController.text.isNotEmpty
                    ? int.tryParse(_templeIdController.text)
                    : null,
                items: _templeList
                    .map(
                      (temple) => DropdownMenuItem<int>(
                    value: temple.templeID,
                    child: Text(
                      temple.title ?? 'Candi ${temple.templeID}',
                    ),
                  ),
                )
                    .toList(),
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _templeIdController.text = value?.toString() ?? '';
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Pilih Candi',
                  labelStyle: GoogleFonts.openSans(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white70,
                ),
                validator: (value) {
                  if (value == null) {
                    return 'Pilih candi terlebih dahulu';
                  }
                  return null;
                },
              ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _titleController,
                  labelText: "Judul Artefak",
                  validator:
                      (v) => _validateRequired(
                        v,
                        minLength: 3,
                        fieldName: 'Judul artefak',
                      ),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _descriptionController,
                  labelText: "Deskripsi",
                  maxLines: 3,
                  validator:
                      (v) => _validateRequired(
                        v,
                        minLength: 10,
                        fieldName: 'Deskripsi artefak',
                      ),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _detailPeriodController,
                  labelText: "Detail Periode",
                  validator:
                      (v) => _validateRequired(v, fieldName: 'Detail periode'),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _detailMaterialController,
                  labelText: "Detail Material",
                  validator:
                      (v) => _validateRequired(v, fieldName: 'Detail material'),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _detailSizeController,
                  labelText: "Detail Ukuran",
                  validator:
                      (v) => _validateRequired(v, fieldName: 'Detail ukuran'),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _detailStyleController,
                  labelText: "Detail Gaya",
                  validator:
                      (v) => _validateRequired(v, fieldName: 'Detail gaya'),
                ),
                const SizedBox(height: 20),
                _buildTextFormField(
                  controller: _funfactTitleController,
                  labelText: "Judul Funfact",
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
                  labelText: "Deskripsi Funfact",
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
                  labelText: "URL Lokasi",
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
                if (_imageError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _imageError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 30),
                // Preview gambar lama (jika ada) dan gambar baru (jika dipilih)
                if (_selectedImageFile != null) ...[
                  Text(
                    "Gambar yang dipilih:",
                    style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Image.file(
                    _selectedImageFile!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ] else if (widget.artifact?.imageUrl != null &&
                    widget.artifact!.imageUrl!.isNotEmpty) ...[
                  Text(
                    "Gambar saat ini:",
                    style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Image.network(
                    widget.artifact!.imageUrl! +
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
                ],
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveArtifact,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff233743),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.merriweather(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  widget.artifact == null
                      ? "Tambah Artefak"
                      : "Simpan Perubahan",
                ),
              ),
            ],
          ),
        ),
        ),
              // Loading overlay
              if (_isLoading)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
        ),
      ),
    );
  }
  // Helper method untuk membuat TextFormField yang konsisten
  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? Function(String?)? validator,
    int? maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading, // Disable when loading
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.openSans(),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white70,
      ),
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}