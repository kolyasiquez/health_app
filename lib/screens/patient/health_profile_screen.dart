import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Для Logout
import 'package:health_app/services/api_service.dart';

// Константи (якщо вони у вас в окремому файлі - розкоментуйте імпорт зверху)
const String kDefaultPlaceholderPath = 'assets/avatars/placeholder.png';
const List<String> kDefaultAvatarPaths = [
  'assets/avatars/avatar_1.png',
  'assets/avatars/avatar_2.png',
  'assets/avatars/avatar_3.png',
  'assets/avatars/avatar_4.png',
  'assets/avatars/avatar_5.png', // Додав ще одну для прикладу
];

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _avatarUrl;
  String? _userName;
  String? _userEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'] ?? kDefaultPlaceholderPath;
        _userName = userData?['name'] ?? 'Patient';
        _userEmail = userData?['email'] ?? _auth.currentUser?.email ?? '';
        _isLoading = false;
      });
    }
  }

  // --- ЛОГІКА ЗМІНИ АВАТАРКИ ---
  void _openAvatarAssetSelectionDialog() {
    final primaryTeal = Theme.of(context).colorScheme.primary;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300,
          child: Column(
            children: [
              Text('Choose profile picture', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: kDefaultAvatarPaths.length,
                  itemBuilder: (context, index) {
                    final assetPath = kDefaultAvatarPaths[index];
                    return GestureDetector(
                      onTap: () {
                        setState(() { _avatarUrl = assetPath; });
                        _saveProfile();
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          backgroundImage: AssetImage(assetPath),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_avatarUrl != null) {
      setState(() { _isLoading = true; });
      try {
        await _apiService.updateUserProfile({'avatarUrl': _avatarUrl});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated successfully!')));
        }
      } catch (e) {
        // Handle error
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      // Повертаємось на екран логіну (або видаляємо всі маршрути)
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true, // Центруємо заголовок
        backgroundColor: Colors.white,

        // 🚀 ЗМІНА 1: Робимо колір елементів (стрілочки і тексту) фірмовим (Teal)
        foregroundColor: primaryTeal,

        elevation: 0,

        // 🚀 ЗМІНА 2: Примусово додаємо кнопку "Назад", щоб вона точно була
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new), // Сучасна стрілочка
          onPressed: () => Navigator.pop(context), // Повертає на Dashboard
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(theme),

            const SizedBox(height: 30),

            _buildSectionTitle('Medical Records'),
            // Цю кнопку теж можна залишити, вона дублює функцію повернення
            _buildMenuTile(
              icon: Icons.calendar_month_outlined,
              title: 'My Appointments',
              subtitle: 'Back to Dashboard',
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildMenuTile(
              icon: Icons.description_outlined,
              title: 'Prescriptions',
              subtitle: 'Medicines & Recipes',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Prescriptions feature coming soon!")));
              },
            ),
            _buildMenuTile(
              icon: Icons.analytics_outlined,
              title: 'Test Results',
              subtitle: 'Blood tests, X-rays, etc.',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            _buildSectionTitle('Settings & Support'),
            _buildMenuTile(
              icon: Icons.settings_outlined,
              title: 'General Settings',
              onTap: () {},
            ),
            _buildMenuTile(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {},
            ),
            _buildMenuTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade200),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text("Log Out"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- ВІДЖЕТИ UI ---

  Widget _buildProfileHeader(ThemeData theme) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Stack(
            children: [
              _buildAvatarWidget(),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _openAvatarAssetSelectionDialog,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary, // Помаранчевий
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _userName ?? 'User',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final primaryTeal = Theme.of(context).colorScheme.primary;
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey.shade100,
      backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('assets/')
          ? AssetImage(_avatarUrl!)
          : null,
      child: _avatarUrl == null || !_avatarUrl!.startsWith('assets/')
          ? Icon(Icons.person, size: 60, color: primaryTeal)
          : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blueGrey[700]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}