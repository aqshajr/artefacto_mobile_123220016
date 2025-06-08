import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artefacto/pages/menu/admin/temple_list_screen.dart';
import 'package:artefacto/pages/menu/admin/artifact_list_screen.dart';
import 'package:artefacto/pages/menu/admin/tiket_list_screen.dart';
import '../../auth/login_pages.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'Admin';
    });
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Konfirmasi Logout", style: GoogleFonts.merriweather()),
            content: Text("Apakah Anda yakin ingin keluar?",
                style: GoogleFonts.openSans()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Batal",
                    style: GoogleFonts.openSans(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Logout",
                    style: GoogleFonts.openSans(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      // Clear shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Navigate to login screen and remove all previous routes
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Admin Dashboard", style: GoogleFonts.playfairDisplay()),
        backgroundColor: const Color(0xffFFFFFF),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Selamat Datang, ${_username ?? '...'}!",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff233743),
                  shadows: [
                    Shadow(
                      offset: const Offset(1.5, 1.5),
                      blurRadius: 4,
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildAdminCard(
                context,
                title: "Kelola Candi",
                subtitle: "Tambah, Edit, Hapus data candi.",
                icon: Icons.temple_buddhist,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TempleListScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                context,
                title: "Kelola Artefak",
                subtitle: "Tambah, Edit, Hapus data artefak.",
                icon: Icons.collections_bookmark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ArtifactListScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildAdminCard(
                context,
                title: "Kelola Tiket",
                subtitle: "Tambah, Edit, Hapus data tiket.",
                icon: Icons.input_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TicketListScreen()),
                  );
                },
              ),
              // const SizedBox(height: 20),
              // _buildAdminCard(
              //   context,
              //   title: "Kelola Transaksi",
              //   subtitle: "Lihat dan kelola data transaksi.",
              //   icon: Icons.receipt_long,
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const TransactionListScreen()),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: const Color(0xFFFBF8F3),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: const Color(0xff233743)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.merriweather(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff233743),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Color(0xff233743)),
            ],
          ),
        ),
      ),
    );
  }
}
