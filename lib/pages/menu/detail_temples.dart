import 'package:artefacto/model/artifact_model.dart';
import 'package:artefacto/pages/menu/detail_artifact.dart';
import 'package:artefacto/service/artifact_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../model/temple_model.dart';
import 'lbs_map_page.dart';

class TempleDetailPage extends StatefulWidget {
  final Temple temple;

  const TempleDetailPage({super.key, required this.temple});

  @override
  State<TempleDetailPage> createState() => _TempleDetailPageState();
}

class _TempleDetailPageState extends State<TempleDetailPage> {
  late Future<List<Artifact>> _artifactsFuture;

  @override
  void initState() {
    super.initState();
    _artifactsFuture = _fetchArtifactsForTemple();
  }

  void _refreshArtifacts() {
    setState(() {
      _artifactsFuture = _fetchArtifactsForTemple();
    });
  }

  Future<List<Artifact>> _fetchArtifactsForTemple() async {
    try {
      // TODO: Idealnya, miliki endpoint API khusus untuk artefak berdasarkan templeID
      final allArtifacts = await ArtifactService.getArtifacts();
      return allArtifacts
          .where((artifact) => artifact.templeID == widget.temple.templeID)
          .toList();
    } catch (e) {
      debugPrint(
          'Error fetching artifacts for temple ${widget.temple.templeID}: $e');
      // Mengembalikan list kosong atau throw error lagi agar FutureBuilder bisa handle
      return []; // Atau throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = const Color(0xFFFDFBF5);
    Color primaryTextColor = const Color(0xff233743);
    Color accentColor = const Color(0xFFB69574);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(widget.temple.title ?? 'Detail Candi',
            style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold, color: primaryTextColor)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTempleImage(widget.temple),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Tentang Candi', primaryTextColor),
                  const SizedBox(height: 8),
                  _buildTempleDescription(widget.temple),
                  if (widget.temple.funfactTitle != null &&
                      widget.temple.funfactTitle!.isNotEmpty)
                    _buildFunFact(widget.temple, primaryTextColor, accentColor),
                  const SizedBox(height: 24),
                  if (widget.temple.locationUrl != null &&
                      widget.temple.locationUrl!.isNotEmpty)
                    _buildLocationButton(widget.temple, context, accentColor),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            _buildArtifactsSection(primaryTextColor),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  Widget _buildTempleImage(Temple temple) {
    return SizedBox(
      width: double.infinity,
      height: 280, // Tinggi gambar candi lebih besar
      child: (temple.imageUrl != null && temple.imageUrl!.isNotEmpty)
          ? Image.network(
              temple.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image,
                      size: 60, color: Colors.grey[500])),
            )
          : Container(
              color: Colors.grey[300],
              child: Icon(Icons.account_balance_outlined,
                  size: 80, color: Colors.grey[500]),
            ),
    );
  }

  Widget _buildTempleDescription(Temple temple) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        temple.description ?? 'Deskripsi tidak tersedia.',
        style: GoogleFonts.poppins(
            fontSize: 15, color: Colors.grey[800], height: 1.6),
        textAlign: TextAlign.justify,
      ),
    );
  }

  Widget _buildFunFact(Temple temple, Color titleColor, Color borderColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: borderColor.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              )
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              temple.funfactTitle!,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.bold, color: titleColor),
            ),
            const SizedBox(height: 8),
            Text(
              temple.funfactDescription ?? '',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationButton(
      Temple temple, BuildContext context, Color buttonColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.map_outlined, color: Colors.white),
        label: Text('Lihat Lokasi',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LBSMapPage(
                candi: temple,
                mode: LbsMode.temples,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildArtifactsSection(Color titleColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Jelajahi Artefak', titleColor),
          const SizedBox(height: 16),
          FutureBuilder<List<Artifact>>(
            future: _artifactsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: CircularProgressIndicator(color: Color(0xFFB69574)),
                ));
              }
              if (snapshot.hasError) {
                return Center(
                    child: Text('Gagal memuat artefak: ${snapshot.error}',
                        style:
                            GoogleFonts.poppins(color: Colors.red.shade700)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text('Belum ada artefak untuk candi ini.',
                      style: GoogleFonts.poppins(color: Colors.grey[600])),
                ));
              }

              final artifacts = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: artifacts.length,
                itemBuilder: (context, index) {
                  final artifact = artifacts[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2.0,
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 10.0),
                      leading: (artifact.imageUrl != null &&
                              artifact.imageUrl!.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6.0),
                              child: Image.network(
                                artifact.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image, size: 40),
                              ),
                            )
                          : Icon(Icons.inventory_2_outlined,
                              size: 40, color: Colors.grey[500]),
                      title: Text(artifact.title,
                          style: GoogleFonts.playfairDisplay(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff233743))),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                              artifact.description.length > 80
                                  ? '${artifact.description.substring(0, 80)}...'
                                  : artifact.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(
                            artifact.isRead ? "Sudah Dibaca" : "Belum Dibaca",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: artifact.isRead
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(Icons.arrow_forward_ios_rounded,
                          size: 16, color: Colors.grey[400]),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ArtifactDetailPage(artifact: artifact),
                          ),
                        ).then((_) => _refreshArtifacts());
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
