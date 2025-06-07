import 'package:artefacto/model/user_model.dart';
import 'package:artefacto/pages/auth/login_pages.dart';
import 'package:artefacto/pages/menu/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notif_page.dart';
import 'camera.dart';
import 'eksplorasi.dart';
import 'visit_notes.dart';
import '../tiket/my_tickets_page.dart';
import 'package:artefacto/service/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _userDataFuture;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final isValid = await _authService.checkSession();
    if (!isValid && mounted) {
      // Session expired, redirect to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if user is logged in
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (!isLoggedIn) {
        throw Exception('Not logged in');
      }

      // Get user ID as int
      final userId = prefs.getInt('userId');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      return {
        'userId': userId,
        'username': prefs.getString('username') ?? 'Guest',
        'email': prefs.getString('email') ?? '',
        'profilePicture': prefs.getString('profilePicture') ?? '',
      };
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
    }
  }

  Widget _buildProfilePage(Map<String, dynamic> userData) {
    return ProfilePage(userData: userData);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gagal memuat data pengguna.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      // Check session first
                      final isValid = await _authService.checkSession();
                      if (!isValid && mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginPage()),
                        );
                        return;
                      }

                      // If session is valid, reload data
                      if (mounted) {
                        setState(() {
                          _userDataFuture = _loadUserData();
                        });
                      }
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        }

        final userData = snapshot.data!;

        final List<Widget> widgetOptions = <Widget>[
          EksplorasiPage(username: userData['username']),
          const MyTicketsPage(),
          const CameraPage(),
          const VisitNotesPage(),
          _buildProfilePage(userData),
        ];

        const List<BottomNavigationBarItem> navItems =
            <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            label: 'Tiket Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan Artefak',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Catatan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ];

        return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  color: const Color(0xff233743),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationPage()),
                    );
                  },
                ),
                const SizedBox(width: 16.0)
              ],
              automaticallyImplyLeading: false,
              toolbarHeight: 60,
            ),
            body: Container(
              color: Colors.white,
              child: widgetOptions.elementAt(_selectedIndex),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: navItems,
              currentIndex: _selectedIndex,
              selectedItemColor: const Color(0xff233743),
              unselectedItemColor: Colors.grey,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
            ),
          ),
        );
      },
    );
  }
}
