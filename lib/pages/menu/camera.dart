import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import '../../service/model_service.dart';
import '../../service/artifact_service.dart';
import 'detail_artifact.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  Map<String, dynamic>? _predictionResult;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final ModelService _modelService = ModelService();

  final Color _primaryDarkBlue = const Color(0xff233743);
  final Color _errorRed = const Color(0xFFE57373);
  final Color _accentBrown = const Color(0xffB69574);

  Future<bool> _requestGalleryPermission() async {
    try {
      if (Platform.isAndroid) {
        // Android 13+ (API 33) menggunakan media permissions
        if (await Permission.mediaLibrary.isRestricted) {
          return false;
        }

        final status = await Permission.mediaLibrary.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          _showSettingsDialog();
          return false;
        }

        // Fallback untuk Android <13
        final storageStatus = await Permission.storage.request();
        return storageStatus.isGranted;
      } else {
        // iOS
        final status = await Permission.photos.request();
        if (status.isGranted) return true;
        if (status.isPermanentlyDenied) {
          _showSettingsDialog();
          return false;
        }
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('Permission error: $e');
      return false;
    }
  }

  Future<bool> _requestCameraPermission() async {
    try {
      if (await Permission.camera.isRestricted) {
        return false;
      }

      final status = await Permission.camera.request();
      if (status.isGranted) return true;
      if (status.isPermanentlyDenied) {
        _showSettingsDialog();
        return false;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint('Camera permission error: $e');
      return false;
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Permission Required',
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
        content: Text('Please enable permissions in app settings',
            style: GoogleFonts.openSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                openAppSettings().then((_) => Navigator.pop(context)),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final hasPermission = await _requestGalleryPermission();
      if (!hasPermission) {
        _showError('Gallery permission denied');
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _predictionResult = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
      debugPrint('Image picker error: $e');
    }
  }

  Future<void> _captureImageFromCamera() async {
    try {
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        _showError('Camera permission denied');
        return;
      }

      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _predictionResult = null;
        });
      }
    } catch (e) {
      _showError('Failed to capture image: ${e.toString()}');
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _predict() async {
    if (_imageFile == null) {
      _showError('Please select or capture an artifact image first');
      return;
    }

    setState(() {
      _isLoading = true;
      _predictionResult = null;
    });

    try {
      final result = await _modelService.predictArtifact(_imageFile!);
      setState(() {
        _predictionResult = result;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _errorRed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Artefak',
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              'Identifikasi artefak dengan AI',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        toolbarHeight: 80,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions Text
              Text(
                'Pilih Sumber Gambar',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryDarkBlue,
                ),
              ),
              const SizedBox(height: 16),

              // Image Preview Container with improved spacing
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _imageFile != null
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                              ),
                            ),
                            if (!_isLoading && _predictionResult == null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _imageFile = null;
                                      _predictionResult = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: _primaryDarkBlue,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Container(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ambil atau pilih foto artefak',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Format yang didukung: JPG, PNG',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[400],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons with improved layout
              if (_imageFile == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureImageFromCamera,
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: Text(
                          'Kamera',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryDarkBlue,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: const Icon(Icons.photo_library,
                            color: Colors.white),
                        label: Text(
                          'Galeri',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentBrown,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (!_isLoading && _predictionResult == null) ...[
                // Scan Button when image is selected
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _predict,
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: Text(
                      'Scan Artefak',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryDarkBlue,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              // Loading Indicator
              if (_isLoading)
                Center(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Memindai Artefak...',
                        style: GoogleFonts.poppins(
                          color: _primaryDarkBlue,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

              // Results Section with improved spacing
              if (_predictionResult != null) ...[
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: _accentBrown,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Hasil Prediksi',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryDarkBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Artefak terdeteksi sebagai:',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _predictionResult!['prediction'],
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _accentBrown,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Tingkat Kepercayaan:',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _predictionResult!['confidence'],
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getConfidenceColor(_predictionResult!['confidence']),
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_predictionResult!['confidence'] * 100).toStringAsFixed(1)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _getConfidenceColor(
                              _predictionResult!['confidence']),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Action Buttons for results
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  final artifacts =
                                      await ArtifactService.getArtifacts();
                                  final matchingArtifact = artifacts.firstWhere(
                                    (a) =>
                                        a.title.toLowerCase() ==
                                        _predictionResult!['prediction']
                                            .toLowerCase(),
                                    orElse: () => throw Exception(
                                        'Artefak tidak ditemukan'),
                                  );
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ArtifactDetailPage(
                                                artifact: matchingArtifact),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  _showError(
                                      'Tidak dapat menemukan detail artefak');
                                }
                              },
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.white),
                              label: Text(
                                'Lihat Detail Artefak',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _accentBrown,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 32,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _imageFile = null;
                                  _predictionResult = null;
                                });
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: Text(
                                'Scan Artefak Lain',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
