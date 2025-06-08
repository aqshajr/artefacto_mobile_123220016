import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artefacto/model/user_model.dart';
import 'package:artefacto/service/auth_service.dart';
import 'package:artefacto/service/api_service.dart';
import 'package:artefacto/pages/auth/login_pages.dart';
import 'package:artefacto/pages/testimoni.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final VoidCallback? onProfileUpdated;

  ProfilePage({super.key, required this.userData, this.onProfileUpdated})
      : assert(userData['userId'] != null, 'UserData must contain userId');

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  bool isLoading = false;
  String? errorMessage;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    try {
      dynamic userId = widget.userData['userId'];

      if (userId is int) {
        userId = userId.toString();
      }

      if (userId == null || userId.toString().isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final cachedUserId = prefs.getInt('userId');

        if (cachedUserId == null) {
          throw Exception('User ID not available in cache');
        }

        userId = cachedUserId.toString();
      }

      user = User(
        id: int.tryParse(userId.toString()) ?? 0,
        username: widget.userData['username']?.toString() ?? '',
        email: widget.userData['email']?.toString() ?? '',
        profilePicture: widget.userData['profilePicture']?.toString(),
      );

      if (user!.id == 0) {
        throw Exception('Invalid user ID format');
      }

      await _loadUserData();
    } catch (e) {
      setState(() {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      debugPrint("Initialization error: $e");
    }
  }

  Future<void> _loadUserData() async {
    print('[ProfilePage] _loadUserData called');

    if (user == null || user!.id == 0) {
      setState(() => errorMessage = 'Invalid user data');
      print('[ProfilePage] Invalid user data, returning');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    print('[ProfilePage] Loading user data from API...');

    try {
      final response = await _apiService.getUserProfile();
      print('[ProfilePage] API response: $response');

      if (response['success'] && response['data'] != null) {
        final userData = response['data'];

        // Handle nested response structure: {data: {user: {...}}}
        final userInfo =
            userData['data']?['user'] ?? userData['user'] ?? userData;

        print('[ProfilePage] User info from API: $userInfo');
        print('[ProfilePage] Raw userData structure: $userData');

        setState(() {
          user = User(
            id: userInfo['userID'] ?? userInfo['id'] ?? user!.id,
            username: userInfo['username'] ?? user!.username,
            email: userInfo['email'] ?? user!.email,
            profilePicture: userInfo['profilePicture'] ?? user!.profilePicture,
          );
        });

        print('[ProfilePage] User updated in setState: ${user?.username}');
        await _updateLocalCache(user!);
        print('[ProfilePage] Local cache updated');
        print('[ProfilePage] Cache updated with username: ${user?.username}');
      } else {
        throw Exception(response['message'] ?? 'Failed to load user data');
      }
    } catch (e) {
      setState(
        () => errorMessage =
            'Error: ${e.toString().replaceAll('Exception: ', '')}',
      );
      debugPrint("Error loading user: $e");
    } finally {
      setState(() => isLoading = false);
      print('[ProfilePage] _loadUserData completed');
    }
  }

  Future<void> _deleteAccount() async {
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: const Text('Apakah Anda yakin ingin menghapus akun Anda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Note: Delete account functionality needs to be implemented in AuthService
        // For now, just logout
        await _logout();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus akun: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateLocalCache(User updatedUser) async {
    final prefs = await SharedPreferences.getInstance();
    if (updatedUser.id != null) {
      await prefs.setInt('userId', updatedUser.id!);
    }
    await prefs.setString('username', updatedUser.username ?? '');
    await prefs.setString('email', updatedUser.email ?? '');
    if (updatedUser.profilePicture != null) {
      await prefs.setString('profilePicture', updatedUser.profilePicture!);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (user == null) return;

    print('[ProfilePage] Navigating to edit profile...');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: user!),
      ),
    );

    print('[ProfilePage] Returned from edit profile with result: $result');

    // Refresh data jika edit profile berhasil
    if (result == true) {
      print('[ProfilePage] Refreshing user data after successful edit...');
      await _loadUserData();

      // Also refresh HomePage user data
      if (widget.onProfileUpdated != null) {
        print('[ProfilePage] Calling HomePage refresh callback...');
        widget.onProfileUpdated!();
      }

      print('[ProfilePage] User data refresh completed');
    } else {
      print('[ProfilePage] No refresh needed (result was not true)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBodyContent(),
    );
  }

  Widget _buildBodyContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null && user == null
              ? _buildErrorWidget()
              : user == null
                  ? _buildNoUserWidget()
                  : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildProfileInfo(),
            const SizedBox(height: 40),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              key: ValueKey(
                  '${user?.profilePicture ?? 'default'}_${DateTime.now().millisecondsSinceEpoch}'), // Force refresh with timestamp
              radius: 50,
              backgroundColor: const Color(0xffF5F0DF),
              backgroundImage: user?.profilePicture != null &&
                      user!.profilePicture!.isNotEmpty
                  ? NetworkImage(
                      '${user!.profilePicture!}?t=${DateTime.now().millisecondsSinceEpoch}' // Add cache buster
                      )
                  : null,
              child:
                  user?.profilePicture == null || user!.profilePicture!.isEmpty
                      ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                      : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xffF5F0DF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xff233743),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.person_outline,
            title: 'Username',
            value: user?.username ?? 'Not set',
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            icon: Icons.email_outlined,
            title: 'Email',
            value: user?.email ?? 'Not set',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xff233743)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xff233743),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          label: "Edit Profile",
          color: const Color(0xff233743),
          onPressed: _navigateToEditProfile,
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.feedback_outlined,
          label: "Testimoni",
          color: const Color(0xff233743),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpPage()),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.logout,
          label: "Logout",
          color: Colors.grey[400]!,
          onPressed: () => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Logout',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text('Apakah Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: _logout,
                  child:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButton(
          icon: Icons.delete_outline,
          label: "Hapus Akun",
          color: Colors.red[400]!,
          onPressed: _deleteAccount,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.2)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _initializeUser,
                child: const Text('Try Again'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _logout,
                child: const Text('Login Again'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoUserWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No user data available', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _initializeUser,
            child: const Text('Refresh'),
          ),
        ],
      ),
    );
  }
}
