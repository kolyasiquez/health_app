import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/constants/constants.dart';
// 👇 1. Додано імпорт екрану зміни пароля
import 'package:health_app/screens/auth/change_password_screen.dart';

// 🚀 ОНОВЛЕНИЙ СПИСОК (нова папка)
const List<String> kDoctorAvatarPaths = [
  'assets/doctor_avatars/doctor_1.png',
  'assets/doctor_avatars/doctor_2.png',
  'assets/doctor_avatars/doctor_3.png',
  'assets/doctor_avatars/doctor_4.png',
  'assets/doctor_avatars/doctor_5.png',
  'assets/doctor_avatars/doctor_6.png',
  'assets/doctor_avatars/doctor_7.png',
  'assets/doctor_avatars/doctor_8.png',
  'assets/doctor_avatars/doctor_9.png',
  'assets/doctor_avatars/doctor_10.png',
  'assets/doctor_avatars/doctor_11.png',
  'assets/doctor_avatars/doctor_12.png',
];

// Заглушка
const String kDefaultPlaceholderPath = 'assets/doctor_avatars/doctor_1.png';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String? _selectedSpecialization;
  String? _avatarUrl;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final userData = await _apiService.getUserData();
      if (mounted && userData != null) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _bioController.text = userData['bio'] ?? '';

          _avatarUrl = userData['avatarUrl'] ?? kDefaultPlaceholderPath;

          String? currentSpec = userData['specialization'];
          if (currentSpec != null && kSpecializations.contains(currentSpec)) {
            _selectedSpecialization = currentSpec;
          } else {
            _selectedSpecialization = kSpecializations.isNotEmpty ? kSpecializations.first : null;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAvatarSelectionDialog() {
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              Text('Select Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: kDoctorAvatarPaths.length,
                  itemBuilder: (context, index) {
                    final assetPath = kDoctorAvatarPaths[index];
                    final isSelected = _avatarUrl == assetPath;

                    return GestureDetector(
                      onTap: () {
                        setState(() { _avatarUrl = assetPath; });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: primaryColor, width: 3)
                              : Border.all(color: Colors.grey.shade300, width: 1),
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
    setState(() { _isLoading = true; });

    try {
      await _apiService.updateUserProfile({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialization': _selectedSpecialization,
        'avatarUrl': _avatarUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performSignOut();
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performSignOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context, rootNavigator: true)
            .pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _confirmSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _avatarUrl != null
                        ? AssetImage(_avatarUrl!)
                        : const AssetImage(kDefaultPlaceholderPath),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _openAvatarSelectionDialog,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedSpecialization,
              decoration: InputDecoration(
                labelText: 'Specialization',
                prefixIcon: const Icon(Icons.medical_services_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: kSpecializations.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedSpecialization = newValue;
                });
              },
            ),

            const SizedBox(height: 20),

            _buildTextField(
              controller: _bioController,
              label: 'Bio / Description',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),

            const SizedBox(height: 30),

            // 👇 2. Додано секцію Security
            Text(
              'SECURITY',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // 👇 3. Кнопка Change Password (стилізована під інпути)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey.shade500), // Колір рамки як у TextField
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: Colors.black54),
                title: const Text('Change Password', style: TextStyle(fontSize: 16)),
                subtitle: const Text('Update your login credentials', style: TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }
}