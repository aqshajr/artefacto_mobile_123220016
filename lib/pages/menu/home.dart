import 'package:artefacto/pages/auth/login_pages.dart';
import 'package:artefacto/pages/menu/profile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_history_page.dart';
import 'camera.dart';
import 'eksplorasi.dart';
import 'visit_notes.dart';
import '../tiket/my_tickets_page.dart';
import 'package:artefacto/service/auth_service.dart';
import 'package:artefacto/service/api_service.dart';
import 'package:artefacto/service/notification_service.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> _userDataFuture;
  final AuthService _authService = AuthService();
  Timer? _sessionCheckTimer;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();

    // DISABLE automatic session checking that causes immediate logout
    // Session will be checked only when user navigates or performs actions
    // _sessionCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
    //   final isValid = await _checkAndRefreshSession();
    //   if (!isValid && mounted) {
    //     _showSessionExpiredDialog();
    //   }
    // });

    // Reset selected index if it's out of bounds
    if (_selectedIndex >= 4) {
      _selectedIndex = 0;
    }

    // Load data with delay to ensure stable session
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _loadData();
      }
    });

    // AUTO SCHEDULE NOTIFICATIONS when app starts (for any new tickets)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _autoScheduleNotifications();
      }
    });

    print('HomePage initState completed - No automatic session checks');
  }

  @override
  void dispose() {
    _sessionCheckTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    print('[HomePage] _loadUserData called');
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

      final userData = {
        'userId': userId,
        'username': prefs.getString('username') ?? 'Guest',
        'email': prefs.getString('email') ?? '',
        'profilePicture': prefs.getString('profilePicture') ?? '',
      };

      print('[HomePage] Loaded user data from cache: ${userData['username']}');
      return userData;
    } catch (e) {
      debugPrint('Error loading user data: $e');
      rethrow;
    }
  }

  Future<void> _loadData() async {
    setState(() {});

    try {
      print('[HomePage] Loading temples and artifacts...');

      // Load temples and artifacts directly (same as EksplorasiPage)
      final templesResult = await _apiService.getTemples();
      final artifactsResult = await _apiService.getArtifacts();

      print('[HomePage] Temples result: $templesResult');
      print('[HomePage] Artifacts result: $artifactsResult');

      int templesCount = 0;
      int artifactsCount = 0;

      // Parse temples response
      if (templesResult['success']) {
        final templesData = templesResult['data'];
        print('[HomePage] Temples data structure: $templesData');

        if (templesData is List) {
          templesCount = templesData.length;
        } else if (templesData is Map) {
          if (templesData['data'] is List) {
            templesCount = (templesData['data'] as List).length;
          } else if (templesData['status'] == 'sukses' &&
              templesData['data'] is List) {
            templesCount = (templesData['data'] as List).length;
          } else if (templesData['status'] == 'sukses' &&
              templesData['data'] is Map &&
              templesData['data']['temples'] is List) {
            templesCount = (templesData['data']['temples'] as List).length;
          }
        }
        print('[HomePage] Parsed temples count: $templesCount');
      } else {
        print('[HomePage] Temples failed: ${templesResult['message']}');
      }

      // Parse artifacts response
      if (artifactsResult['success']) {
        final artifactsData = artifactsResult['data'];
        print('[HomePage] Artifacts data structure: $artifactsData');

        if (artifactsData is List) {
          artifactsCount = artifactsData.length;
        } else if (artifactsData is Map) {
          if (artifactsData['data'] is List) {
            artifactsCount = (artifactsData['data'] as List).length;
          } else if (artifactsData['status'] == 'sukses' &&
              artifactsData['data'] is List) {
            artifactsCount = (artifactsData['data'] as List).length;
          } else if (artifactsData['status'] == 'sukses' &&
              artifactsData['data'] is Map &&
              artifactsData['data']['artifacts'] is List) {
            artifactsCount =
                (artifactsData['data']['artifacts'] as List).length;
          }
        }
        print('[HomePage] Parsed artifacts count: $artifactsCount');
      } else {
        print('[HomePage] Artifacts failed: ${artifactsResult['message']}');
      }

      // Update state with parsed data
      setState(() {});

      print(
          '[HomePage] Final counts - Temples: $templesCount, Artifacts: $artifactsCount');
    } catch (e) {
      print('[HomePage] Error loading data: $e');
      setState(() {});
    } finally {
      setState(() {});
    }
  }

  // AUTO SCHEDULE NOTIFICATIONS FOR USER'S TICKETS
  Future<void> _autoScheduleNotifications() async {
    try {
      print('[HomePage] 🎫 Auto scheduling notifications for user tickets...');

      // Schedule notifications for all user tickets (background scheduling)
      await NotificationService.autoScheduleWhenTicketPurchased();

      print('[HomePage] ✅ Auto notification scheduling completed');
    } catch (e) {
      print('[HomePage] ❌ Error auto scheduling notifications: $e');
    }
  }

  // Method to refresh user data - called from ProfilePage
  Future<void> refreshUserData() async {
    print('[HomePage] refreshUserData called from ProfilePage');
    if (mounted) {
      print('[HomePage] Refreshing _userDataFuture...');
      setState(() {
        _userDataFuture = _loadUserData();
      });
      print('[HomePage] _userDataFuture refresh completed');
    } else {
      print('[HomePage] Widget not mounted, skipping refresh');
    }
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
          ProfilePage(
            userData: userData,
            onProfileUpdated: refreshUserData, // Add callback
          ),
        ];

        const List<BottomNavigationBarItem> navItems =
            <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Tiket Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Notes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
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
                          builder: (context) =>
                              const NotificationHistoryPage()),
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
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                items: navItems,
                currentIndex: _selectedIndex,
                selectedItemColor: const Color(0xff233743),
                unselectedItemColor: Colors.grey,
                selectedFontSize: 12,
                unselectedFontSize: 12,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.white,
                elevation: 0,
                onTap: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
