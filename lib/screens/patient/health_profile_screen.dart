// lib/screens/patient/health_profile_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _apiService = ApiService();
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userData = await _apiService.getUserData();
    if (userData != null) {
      setState(() {
        _avatarUrl = userData['avatarUrl'];
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      await _apiService.uploadAvatar(imageFile);
      await _loadProfileData(); // Оновлюємо екран після завантаження
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мій профіль'),
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickAndUploadImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.deepPurpleAccent,
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null
                    ? const Icon(Icons.camera_alt, color: Colors.white, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _pickAndUploadImage,
              child: const Text('Змінити фото'),
            ),
            // ... інші елементи профілю ...
          ],
        ),
      ),
    );
  }
}