import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../model/artifact_model.dart';
import '../../model/temple_model.dart';
import '../../service/artifact_service.dart';
import 'lbs_map_page.dart';

class ArtifactDetailPage extends StatefulWidget {
  final Artifact artifact;

  const ArtifactDetailPage({super.key, required this.artifact});

  @override
  State<ArtifactDetailPage> createState() => _ArtifactDetailPageState();
}

class _ArtifactDetailPageState extends State<ArtifactDetailPage> {
  late bool _isRead;
  late bool _isBookmarked;
  bool _isLoading = true;
  late Artifact _artifact;

  @override
  void initState() {
    super.initState();
    _loadArtifactDetails();
  }

  Future<void> _loadArtifactDetails() async {
    try {
      // Mengambil data artefak terbaru dari service untuk memastikan state (isRead, isBookmarked) up-to-date
      final fullArtifact =
          await ArtifactService.getArtifactById(widget.artifact.artifactID);
      if (mounted) {
        setState(() {
          _artifact = fullArtifact;
          _isRead = _artifact.isRead;
          _isBookmarked = _artifact.isBookmarked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Jika gagal, gunakan data awal dari widget & hentikan loading
          _artifact = widget.artifact;
          _isRead = widget.artifact.isRead;
          _isBookmarked = widget.artifact.isBookmarked;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal memuat detail terbaru: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF5),
      appBar: AppBar(
        title: Text('Detail Artefak',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _artifact.imageUrl ?? '',
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[200],
                  child: const Icon(Icons.inventory_2_outlined,
                      size: 60, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Judul Utama Artefak
            Text(
              _artifact.title,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff233743)),
            ),
            const SizedBox(height: 8),
            Text(
              'Candi ${_artifact.templeTitle}',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700]),
            ),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Deskripsi
            _buildSectionTitle('Deskripsi', Icons.notes_rounded),
            const SizedBox(height: 12),
            Text(
              _artifact.description,
              style: GoogleFonts.poppins(
                  fontSize: 15, height: 1.6, color: Colors.grey[850]),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 24),

            // Detail Artefak
            if (_hasDetails()) _buildDetailsContainer(),
            const SizedBox(height: 16),

            // Fun Fact
            if (_artifact.funfactTitle != null) _buildFunFactContainer(),
            const SizedBox(height: 24),

            // Tombol Lokasi di paling bawah
            if (_artifact.locationUrl != null &&
                _artifact.locationUrl!.isNotEmpty)
              _buildLocationButton(),
          ],
        ),
      ),
    );
  }

  bool _hasDetails() {
    return _artifact.detailPeriod != null ||
        _artifact.detailMaterial != null ||
        _artifact.detailSize != null ||
        _artifact.detailStyle != null;
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xff233743), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xff233743)),
        ),
      ],
    );
  }

  Widget _buildDetailsContainer() {
    // Membangun daftar item detail secara dinamis untuk memastikan spacing konsisten
    final List<Widget> detailItems = [];
    if (_artifact.detailPeriod != null) {
      detailItems.add(_buildDetailItem("Periode", _artifact.detailPeriod!));
    }
    if (_artifact.detailMaterial != null) {
      detailItems.add(_buildDetailItem("Material", _artifact.detailMaterial!));
    }
    if (_artifact.detailSize != null) {
      detailItems.add(_buildDetailItem("Ukuran", _artifact.detailSize!));
    }
    if (_artifact.detailStyle != null) {
      detailItems.add(_buildDetailItem("Gaya", _artifact.detailStyle!));
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Detail Artefak', Icons.list_alt_rounded),
          const Divider(height: 24),
          // Menggunakan loop untuk menambahkan item dan spasi di antaranya
          for (int i = 0; i < detailItems.length; i++) ...[
            detailItems[i],
            if (i < detailItems.length - 1) const SizedBox(height: 16),
          ]
        ],
      ),
    );
  }

  Widget _buildFunFactContainer() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Fun Fact', Icons.lightbulb_outline_rounded),
          const SizedBox(height: 12),
          Text(
            _artifact.funfactTitle!,
            style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xff233743).withOpacity(0.8)),
          ),
          const SizedBox(height: 8),
          Text(
            _artifact.funfactDescription ?? '',
            style: GoogleFonts.poppins(
                fontSize: 14, color: Colors.grey[800], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToggleButton(
            icon: _isRead ? Icons.check_circle : Icons.check_circle_outline,
            label: "Sudah Dibaca",
            isActive: _isRead,
            onTap: _toggleReadStatus,
            activeColor: Colors.green.shade800,
            inactiveColor: const Color(0xffa58565),
          ),
          _buildToggleButton(
            icon: _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: "Bookmark",
            isActive: _isBookmarked,
            onTap: _toggleBookmark,
            activeColor: Theme.of(context).primaryColor,
            inactiveColor: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        label: Text('Lihat Lokasi',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 16)),
        onPressed: () {
          if (_artifact.locationUrl != null &&
              _artifact.locationUrl!.isNotEmpty) {
            _launchURL(_artifact.locationUrl!);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB69574),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Future<void> _toggleReadStatus() async {
    if (_isRead) return;

    await ArtifactService.markArtifactAsRead(_artifact.artifactID);
    if (mounted) {
      setState(() => _isRead = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Artefak ditandai telah dibaca'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isBookmarked) {
      await ArtifactService.unbookmarkArtifact(_artifact.artifactID);
    } else {
      await ArtifactService.bookmarkArtifact(_artifact.artifactID);
    }
    if (mounted) {
      setState(() => _isBookmarked = !_isBookmarked);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBookmarked
              ? 'Artefak berhasil di-bookmark'
              : 'Bookmark dihapus'),
          backgroundColor: _isBookmarked ? Colors.blueAccent : Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka URL: $url')),
        );
      }
    }
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final Color color = isActive ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
