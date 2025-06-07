import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../model/temple_model.dart';
import '../../../service/temple_service.dart';
import 'temple_form_screen.dart';

class TempleListScreen extends StatefulWidget {
  const TempleListScreen({super.key});

  @override
  State<TempleListScreen> createState() => _TempleListScreenState();
}

class _TempleListScreenState extends State<TempleListScreen> {
  List<Temple> _temples = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTemples();
  }

  Future<void> _loadTemples() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final temples = await TempleService.getTemples();
      setState(() {
        _temples = temples;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data: $e';
        _isLoading = false;
      });
    }
  }


  Future<void> _handleEditTemple(Map<String, dynamic>? result) async {
    if (result == null) return;
    final Temple? updatedTemple = result['temple'] as Temple?;
    final File? imageFile = result['image'] as File?;
    if (updatedTemple == null) return;
    try {
      setState(() => _isLoading = true);
      await TempleService.updateTempleWithImage(
        templeId: updatedTemple.templeID!,
        title: updatedTemple.title ?? '',
        description: updatedTemple.description ?? '',
        funfactTitle: updatedTemple.funfactTitle,
        funfactDescription: updatedTemple.funfactDescription,
        locationUrl: updatedTemple.locationUrl,
        imageFile: imageFile,
      );
      await _loadTemples();
      _showSuccessSnackbar('${updatedTemple.title} berhasil diperbarui');
    } catch (e) {
      _showErrorSnackbar('Gagal memperbarui candi: $e');
    }
  }

  Future<void> _handleDeleteTemple(int templeId) async {
    try {
      setState(() => _isLoading = true);
      await TempleService.deleteTemple(templeId);
      await _loadTemples();
      _showSuccessSnackbar('Candi berhasil dihapus');
    } catch (e) {
      _showErrorSnackbar('Gagal menghapus candi: $e');
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kelola Candi",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff233743),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<Map<String, dynamic>?>(
                context,
                MaterialPageRoute(
                  builder: (context) => const TempleFormScreen(),
                ),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTemples),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _loadTemples,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_temples.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data candi',
          style: GoogleFonts.openSans(fontSize: 18),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTemples,
      child: ListView.builder(
        itemCount: _temples.length,
        itemBuilder: (context, index) {
          final temple = _temples[index];
          return _buildTempleCard(temple);
        },
      ),
    );
  }

  Widget _buildTempleCard(Temple temple) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        leading:
            temple.imageUrl != null
                ? Image.network(
                  temple.imageUrl! +
                      '?v=${DateTime.now().millisecondsSinceEpoch}',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                )
                : const Icon(Icons.temple_buddhist, size: 60),
        title: Text(
          temple.title ?? 'Tanpa Judul',
          style: GoogleFonts.merriweather(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (temple.templeID != null)
              Text(
                'ID Candi: ${temple.templeID}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            Text(
              temple.description ?? 'Tidak ada deskripsi',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (temple.locationUrl != null)
              Text(
                temple.locationUrl!,
                style: const TextStyle(color: Colors.blue),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final result = await Navigator.push<Map<String, dynamic>?>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TempleFormScreen(temple: temple),
                  ),
                );

                await _handleEditTemple(result);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteDialog(temple),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Temple temple) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hapus Candi?'),
            content: Text('Yakin ingin menghapus ${temple.title}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _handleDeleteTemple(temple.templeID!);
                },
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }
}
