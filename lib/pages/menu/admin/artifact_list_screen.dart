import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artefacto/model/artifact_model.dart';
import 'package:artefacto/service/artifact_service.dart';
import 'dart:io';

import 'artifact_form_screen.dart';

class ArtifactListScreen extends StatefulWidget {
  const ArtifactListScreen({super.key});

  @override
  State<ArtifactListScreen> createState() => _ArtifactListScreenState();
}

class _ArtifactListScreenState extends State<ArtifactListScreen> {
  List<Artifact> artifacts = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadArtifacts();
  }

  Future<void> _loadArtifacts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final data = await ArtifactService.getArtifacts();
      setState(() {
        artifacts = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load artifacts: ${e.toString()}';
      });
      _showErrorSnackbar(errorMessage!);
    }
  }

  Future<void> _editArtifact(Map<String, dynamic>? result) async {
    if (result == null) return;
    final Artifact? updatedArtifact = result['artifact'] as Artifact?;
    final File? imageFile = result['image'] as File?;
    if (updatedArtifact == null) return;
    try {
      await ArtifactService.updateArtifactWithImage(updatedArtifact, imageFile);
      await _loadArtifacts();
      _showSuccessSnackbar('${updatedArtifact.title} updated successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to update artifact: ${e.toString()}');
    }
  }

  Future<void> _deleteArtifact(int artifactID) async {
    try {
      await ArtifactService.deleteArtifact(artifactID);
      setState(() {
        artifacts.removeWhere((artifact) => artifact.artifactID == artifactID);
      });
      _showSuccessSnackbar('Artifact deleted successfully');
    } catch (e) {
      _showErrorSnackbar('Failed to delete artifact: ${e.toString()}');
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
          "Manage Artifacts",
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xff233743),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArtifacts,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadArtifacts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (artifacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No artifacts found',
              style: GoogleFonts.openSans(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadArtifacts,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArtifacts,
      child: ListView.builder(
        itemCount: artifacts.length,
        itemBuilder: (context, index) {
          final artifact = artifacts[index];
          return _buildArtifactCard(artifact);
        },
      ),
    );
  }

  Widget _buildArtifactCard(Artifact artifact) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (artifact.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  artifact.imageUrl! +
                      '?v=${DateTime.now().millisecondsSinceEpoch}',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              artifact.title,
              style: GoogleFonts.merriweather(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              artifact.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.openSans(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    final result = await Navigator.push<Map<String, dynamic>?>(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ArtifactFormScreen(artifact: artifact),
                      ),
                    );
                    await _editArtifact(result);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _showDeleteDialog(artifact),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(Artifact artifact) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${artifact.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteArtifact(artifact.artifactID);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
