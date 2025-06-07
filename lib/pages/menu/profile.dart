import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artefacto/model/user_model.dart';
import 'package:artefacto/service/user_service.dart';
import 'package:artefacto/pages/auth/login_pages.dart';
import 'package:artefacto/pages/testimoni.dart';
import 'edit_profile.dart';

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  ProfilePage({super.key, required this.userData})
      : assert(userData['userId'] != null, 'UserData must contain userId');

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user;
  bool isLoading = false;
  String? errorMessage;

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
        final cachedUserId = prefs.getString('userId');

        if (cachedUserId == null || cachedUserId.isEmpty) {
          throw Exception('User ID not available in cache');
        }

        userId = cachedUserId;
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
    if (user == null || user!.id == 0) {
      setState(() => errorMessage = 'Invalid user data');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final userService = UserService();
      final response = await userService.getCurrentUser();

      if (response != null) {
        setState(() => user = response);
        await _updateLocalCache(user!);
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (e) {
      setState(
        () => errorMessage =
            'Error: ${e.toString().replaceAll('Exception: ', '')}',
      );
      debugPrint("Error loading user: $e");
    } finally {
      setState(() => isLoading = false);
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
        final userService = UserService();
        final response = await userService.deleteUser();

        if (response['success']) {
          await _logout();
        } else {
          throw Exception(response['message'] ?? 'Gagal menghapus akun');
        }
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
    await prefs.setString('userId', updatedUser.id.toString());
    await prefs.setString('username', updatedUser.username ?? '');
    await prefs.setString('email', updatedUser.email ?? '');
    if (updatedUser.profilePicture != null) {
      await prefs.setString('profilePicture', updatedUser.profilePicture!);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _navigateToEditProfile() async {
    if (user == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilePage(user: user!),
      ),
    );

    // Refresh data jika edit profile berhasil
    if (result == true) {
      await _loadUserData();
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
              radius: 50,
              backgroundColor: const Color(0xffF5F0DF),
              backgroundImage: user?.profilePicture != null &&
                      user!.profilePicture!.isNotEmpty
                  ? NetworkImage(user!.profilePicture!)
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
