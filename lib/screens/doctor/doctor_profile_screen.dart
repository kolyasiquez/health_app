// lib/screens/doctor/doctor_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/constants/constants.dart'; // 🚀 ІМПОРТУЄМО СПИСОК

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _selectedSpecialization;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userData = await _apiService.getUserData();
    if (mounted && userData != null) {
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _bioController.text = userData['bio'] ?? '';

        // Перевіряємо, чи поточна спеціалізація є в нашому глобальному списку
        String? currentSpec = userData['specialization'];

        if (currentSpec != null && kSpecializations.contains(currentSpec)) {
          _selectedSpecialization = currentSpec;
        } else {
          // Якщо ні (або не вибрано), ставимо першу зі списку
          _selectedSpecialization = kSpecializations.first;
        }

        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() { _isLoading = true; });

    try {
      await _apiService.updateUserProfile({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'specialization': _selectedSpecialization, // Зберігаємо вибір
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Dr. House',
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 20),

            // 🚀 Випадаючий список (бере дані з constants.dart)
            const Text('Specialization', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSpecialization,
                  isExpanded: true,
                  hint: const Text("Select specialization"),
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
              ),
            ),

            const SizedBox(height: 20),

            const Text('Bio / Description', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tell about your experience...',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}