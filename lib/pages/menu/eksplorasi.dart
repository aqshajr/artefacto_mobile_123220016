import 'package:artefacto/pages/tiket/ticket_selected_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artefacto/service/temple_service.dart';
import 'package:artefacto/service/artifact_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'detail_artifact.dart';
import 'detail_temples.dart';
import 'package:artefacto/pages/learning/learning_page.dart';

class EksplorasiPage extends StatefulWidget {
  final String? username;
  const EksplorasiPage({Key? key, this.username}) : super(key: key);

  @override
  State<EksplorasiPage> createState() => _EksplorasiPageState();
}

class _EksplorasiPageState extends State<EksplorasiPage> {
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  int totalTemples = 0;
  int totalArtifacts = 0;
  String? _username;

  // Ganti dengan path yang benar jika Anda punya aset logo, atau set null jika tidak ada.
  final String? logoAssetPath = null; // 'assets/images/logo_artefacto.png';

  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    if (_username == null) {
      await _getUsernameFromPrefs();
    }
    await _getCounts();
  }

  Future<void> _getUsernameFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'Pengguna';
      });
    }
  }

  Future<void> _getCounts() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final templeResponse = await TempleService.getTemples();
      final artifactResponse = await ArtifactService.getArtifacts();

      if (mounted) {
        setState(() {
          if (templeResponse.isNotEmpty) {
            totalTemples = templeResponse.length;
          }
          if (artifactResponse.isNotEmpty) {
            totalArtifacts = artifactResponse.length;
          }
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Gagal memuat data statistik: ${e.toString()}';
          isLoading = false;
        });
      }
      debugPrint('Error loading counts: $e');
    }
  }

  Future<void> _refreshData() async {
    await _getCounts();
  }

  Widget _buildHeader() {
    Widget logoDisplay;
    if (logoAssetPath != null) {
      try {
        logoDisplay =
            Image.asset(logoAssetPath!, height: 55); // Sesuaikan tinggi logo
      } catch (e) {
        // Fallback jika path logo salah atau aset tidak ditemukan, tampilkan teks besar
        debugPrint(
            "Error loading logo asset ($logoAssetPath): $e. Displaying text name.");
        logoDisplay = Text(
          'ARTEFACTO',
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFB69574),
          ),
        );
      }
    } else {
      // Jika logoAssetPath null, tampilkan teks Artefacto
      logoDisplay = Text(
        'ARTEFACTO',
        style: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFB69574),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 40),
        logoDisplay, // Hanya tampilkan logo (gambar atau teks), bukan keduanya
        const SizedBox(height: 4),
        Text(
          'Culture Explorer',
          style: GoogleFonts.poppins(
            fontSize: 15,
            color: Colors.grey[600],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildGreetingAndStats() {
    String greeting;
    final hour = DateTime.now().hour;
    if (hour < 4) {
      greeting = 'Selamat Malam';
    } else if (hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 25.0),
      color: const Color(0xFFFDFBF5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$greeting, ${_username ?? "Pengguna"}!',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xff233743),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan keajaiban arsitektur dan sejarah nusantara yang menakjubkan.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Color(0xffB69574)))))
          else if (!hasError)
            Row(
              mainAxisAlignment: MainAxisAlignment
                  .center, // Pusatkan row statistik jika diinginkan, atau biarkan default
              children: [
                Icon(Icons.location_city_rounded,
                    color: const Color(0xff233743), size: 18),
                const SizedBox(width: 6),
                Text('$totalTemples Candi',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xff233743),
                        fontWeight: FontWeight.w500)),
                const SizedBox(width: 24),
                Icon(Icons.museum_rounded,
                    color: const Color(0xff233743), size: 18),
                const SizedBox(width: 6),
                Text('$totalArtifacts Artefak',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xff233743),
                        fontWeight: FontWeight.w500)),
              ],
            )
          else
            Text(errorMessage,
                style: GoogleFonts.poppins(
                    color: Colors.red.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
        margin: const EdgeInsets.only(bottom: 18.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 30, color: const Color(0xFFB69574)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff233743),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: Colors.grey[650],
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalCTA(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
      child: Column(
        children: [
          Icon(Icons.star_outline_rounded, color: Color(0xFFB69574), size: 40),
          const SizedBox(height: 15),
          Text(
            'Mulai Petualangan Budayamu Sekarang!',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff233743),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Bergabunglah dengan ribuan penjelajah budaya lainnya dan temukan keajaiban Indonesia yang tersembunyi.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
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
              errorMessage.isNotEmpty
                  ? errorMessage
                  : 'Terjadi kesalahan saat memuat data.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Gagal membuka URL, tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
        );
      }
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFFFDFBF5);

    if (isLoading && _username == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
            child: CircularProgressIndicator(color: const Color(0xffB69574))),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        color: const Color(0xffB69574),
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildGreetingAndStats(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20.0, 22.0, 20.0, 10.0), // Mengurangi padding bawah sedikit
                child: Column(
                  children: [
                    _buildActionCard(
                      icon: Icons.confirmation_num_outlined,
                      title: 'Beli Tiket Masuk',
                      description:
                          'Pesan tiket candi dengan mudah untuk pengalaman wisata budaya tak terlupakan.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const TicketSelectionPage()),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.menu_book_rounded,
                      title: 'Mulai Pembelajaran',
                      description:
                          'Jelajahi sejarah dan budaya Indonesia melalui panduan candi interaktif.',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LearningPage()),
                        );
                      },
                    ),
                    _buildActionCard(
                      icon: Icons.article_outlined,
                      title: 'Baca Artikel & Berita',
                      description:
                          'Temukan wawasan terbaru seputar dunia cagar budaya dan pariwisata.',
                      onTap: () {
                        _launchURL(
                            'https://artefacts.id/2024/11/11/artefak-indonesia-di-manca-negara-jejak-sejarah-dan-warisan-budaya-dan-pengaruhnya-di-kancah-global/');
                      },
                    ),
                  ],
                ),
              ),
              _buildFinalCTA(context),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
