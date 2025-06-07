import 'package:artefacto/model/artifact_model.dart';
import 'package:artefacto/model/temple_model.dart';
import 'package:artefacto/pages/menu/detail_temples.dart';
import 'package:artefacto/service/artifact_service.dart';
import 'package:artefacto/service/temple_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Helper class untuk menyimpan progres
class TempleLearningProgress {
  final int totalArtifacts;
  final int readArtifacts;
  final double progressPercent;

  TempleLearningProgress({
    this.totalArtifacts = 0,
    this.readArtifacts = 0,
    this.progressPercent = 0.0,
  });
}

// Helper class untuk menggabungkan candi dengan progresnya
class TempleCardData {
  final Temple temple;
  final TempleLearningProgress progress;

  TempleCardData({required this.temple, required this.progress});
}

class LearningPage extends StatefulWidget {
  const LearningPage({Key? key}) : super(key: key);

  @override
  State<LearningPage> createState() => _LearningPageState();
}

class _LearningPageState extends State<LearningPage> {
  List<TempleCardData> _allTemples = [];
  List<TempleCardData> _filteredTemples = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterTemples(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTemples = _allTemples;
      } else {
        _filteredTemples = _allTemples
            .where((temple) =>
                temple.temple.title
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false)
            .toList();
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final temples = await TempleService.getTemples();
      final artifacts = await ArtifactService.getArtifacts();

      final List<TempleCardData> templeCards = [];

      for (var temple in temples) {
        final templeArtifacts =
            artifacts.where((a) => a.templeID == temple.templeID).toList();
        final readArtifacts =
            templeArtifacts.where((artifact) => artifact.isRead).length;

        final progress = TempleLearningProgress(
          totalArtifacts: templeArtifacts.length,
          readArtifacts: readArtifacts,
          progressPercent: templeArtifacts.isEmpty
              ? 0
              : (readArtifacts / templeArtifacts.length) * 100,
        );

        templeCards.add(TempleCardData(temple: temple, progress: progress));
      }

      setState(() {
        _allTemples = templeCards;
        _filteredTemples = templeCards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5),
      appBar: AppBar(
        title: Text('Pembelajaran',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _filterTemples,
              decoration: InputDecoration(
                hintText: 'Cari candi...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xff233743)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? _buildErrorWidget(_errorMessage)
                    : _filteredTemples.isEmpty
                        ? _buildEmptyStateWidget()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredTemples.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child:
                                    _buildTempleCard(_filteredTemples[index]),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempleCard(TempleCardData templeCardData) {
    final temple = templeCardData.temple;
    final progress = templeCardData.progress;

    return Card(
      color: Colors.white,
      elevation: 3.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(15.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TempleDetailPage(temple: templeCardData.temple),
            ),
          ).then((_) => _refreshData());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTempleImage(temple, 180),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    temple.title ?? 'Tanpa Judul',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff233743),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    temple.description != null &&
                            temple.description!.length > 100
                        ? '${temple.description!.substring(0, 100)}...'
                        : temple.description ?? 'Tidak ada deskripsi.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  _buildProgressBar(progress, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTempleImage(Temple temple, double height) {
    if (temple.imageUrl != null && temple.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(15.0),
          topRight: Radius.circular(15.0),
        ),
        child: Image.network(
          temple.imageUrl!,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15.0),
                  topRight: Radius.circular(15.0),
                ),
              ),
              child:
                  Icon(Icons.broken_image, color: Colors.grey[400], size: 40),
            );
          },
        ),
      );
    } else {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15.0),
            topRight: Radius.circular(15.0),
          ),
        ),
        child: Icon(Icons.account_balance_outlined,
            color: Colors.grey[500], size: 50),
      );
    }
  }

  Widget _buildProgressBar(
      TempleLearningProgress progress, BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress Eksplorasi',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
            Text(
              '${progress.progressPercent.toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFFB69574),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.progressPercent / 100,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB69574)),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${progress.readArtifacts} dari ${progress.totalArtifacts} artefak dipelajari',
          style: GoogleFonts.poppins(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorWidget(String errorMsg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 60, color: Colors.red.shade400),
            const SizedBox(height: 20),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text('Coba Lagi',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontWeight: FontWeight.w500)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffB69574),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0))),
              onPressed: _refreshData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            'Belum ada data pembelajaran candi.',
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}
