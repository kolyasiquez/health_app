// lib/screens/patient/health_profile_screen.dart

// ВИДАЛЕНО: import 'dart:io';
// ВИДАЛЕНО: import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import '../../constants/avatars.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final ApiService _apiService = ApiService();

  // _avatarUrl зберігає шлях до локального асету
  String? _avatarUrl;
  bool _isLoading = true;
  // ВИДАЛЕНО: File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  Future<void> _loadAvatarUrl() async {
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        // Зчитуємо збережений шлях. Якщо його немає, ставимо шлях до заповнювача.
        _avatarUrl = userData?['avatarUrl'] ?? kDefaultPlaceholderPath;
        _isLoading = false;
      });
    }
  }

  // Метод для відкриття діалогу вибору стандартної аватарки
  void _openAvatarAssetSelectionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Оберіть стандартну аватарку', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: kDefaultAvatarPaths.length,
                itemBuilder: (context, index) {
                  final assetPath = kDefaultAvatarPaths[index];
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _avatarUrl = assetPath; // Зберігаємо локальний шлях
                      });
                      _saveProfile(); // Одразу зберігаємо зміну в профілі
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.deepPurple.shade100,
                      child: ClipOval(
                        child: Image.asset( // ВИКОРИСТОВУЄМО Image.asset
                          assetPath,
                          fit: BoxFit.cover,
                          width: 70,
                          height: 70,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Метод для збереження змін (для стандартної аватарки)
  Future<void> _saveProfile() async {
    if (_avatarUrl != null) {
      setState(() { _isLoading = true; });

      try {
        // Зберігаємо локальний шлях до асету у Firestore
        await _apiService.updateUserProfile({'avatarUrl': _avatarUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Аватарку успішно оновлено!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка збереження: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  // ВИДАЛЕНО: _pickImage()
  // ВИДАЛЕНО: _uploadImage()


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
                'Ваша аватарка',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildAvatarWidget(),
              const SizedBox(height: 30),
              _buildImageButtons(), // Викликаємо оновлену секцію з єдиною кнопкою
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

  // Віджет для відображення аватарки (завжди використовує Image.asset)
  Widget _buildAvatarWidget() {
    Widget imageWidget;

    if (_avatarUrl != null && _avatarUrl!.startsWith('assets/')) {
      // Збережено шлях до локального асету
      imageWidget = Image.asset(_avatarUrl!, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 80, color: Colors.deepPurple));
    } else {
      // Заповнювач за замовчуванням
      imageWidget = const Icon(Icons.person, size: 80, color: Colors.deepPurple);
    }

    return Center(
      child: CircleAvatar(
        radius: 80,
        backgroundColor: Colors.deepPurple.shade100,
        child: ClipOval(
          child: imageWidget,
        ),
      ),
    );
  }

  // Кнопка для вибору стандартної аватарки
  Widget _buildImageButtons() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _openAvatarAssetSelectionDialog,
      icon: const Icon(Icons.emoji_people),
      label: const Text('Обрати стандартну аватарку'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}