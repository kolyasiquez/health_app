// lib/screens/patient/health_profile_screen.dart (Виправлений код)
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:health_app/services/api_service.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final ApiService _apiService = ApiService();
  String? _avatarUrl;
  bool _isLoading = true;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  Future<void> _loadAvatarUrl() async {
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Спочатку оберіть фото.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // *** ВИПРАВЛЕНО: uploadAvatar тепер повертає String? (URL) ***
      final url = await _apiService.uploadAvatar(_imageFile!);

      // *** ВИПРАВЛЕНО ПОМИЛКУ void та неіснуючий метод ***
      if (url != null) {
        // Оновлюємо посилання в Firestore, використовуючи метод updateUserProfile
        await _apiService.updateUserProfile({'avatarUrl': url});

        if (mounted) {
          setState(() {
            _avatarUrl = url;
            _imageFile = null; // Очистити обраний файл
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Фото профілю успішно оновлено!')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Помилка: Не вдалося отримати URL завантаженого фото.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка завантаження: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш профіль'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Оновлення фото профілю',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildAvatarWidget(),
              const SizedBox(height: 30),
              _buildImageButtons(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 50),
              const Text(
                'Тут будуть інші поля профілю (ім\'я, дата народження, тощо)...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget() {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_avatarUrl != null) {
      imageProvider = NetworkImage(_avatarUrl!);
    }

    return Center(
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.deepPurple.shade100,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? const Icon(Icons.person, size: 80, color: Colors.deepPurple)
            : null,
      ),
    );
  }

  Widget _buildImageButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text('Обрати фото'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _uploadImage,
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Завантажити'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrangeAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }
}