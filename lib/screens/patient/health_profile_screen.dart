// lib/screens/patient/health_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
// import '../../constants/avatars.dart'; // Припускаємо, що цей файл існує

// Приклад kDefaultPlaceholderPath, якщо він не визначений:
const String kDefaultPlaceholderPath = 'assets/avatars/placeholder.png';
// Приклад kDefaultAvatarPaths, якщо він не визначений:
const List<String> kDefaultAvatarPaths = [
  'assets/avatars/avatar1.png',
  'assets/avatars/avatar2.png',
  'assets/avatars/avatar3.png',
  'assets/avatars/avatar4.png',
];

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final ApiService _apiService = ApiService();

  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatarUrl();
  }

  Future<void> _loadAvatarUrl() async {
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'] ?? kDefaultPlaceholderPath;
        _isLoading = false;
      });
    }
  }

  // Метод для відкриття діалогу вибору стандартної аватарки
  void _openAvatarAssetSelectionDialog() {
    final primaryTeal = Theme.of(context).colorScheme.primary;

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
                        _avatarUrl = assetPath;
                      });
                      _saveProfile();
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: primaryTeal.withOpacity(0.15),
                      child: ClipOval(
                        child: Image.asset(
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш профіль'),
        // 🚀 Використовує AppBarTheme (Teal)
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Ваша аватарка',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
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
              Text(
                'Тут будуть інші поля профілю (ім\'я, дата народження, тощо)...',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium, // Сірий
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
    final primaryTeal = Theme.of(context).colorScheme.primary;

    if (_avatarUrl != null && _avatarUrl!.startsWith('assets/')) {
      imageWidget = Image.asset(_avatarUrl!, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 80, color: primaryTeal));
    } else {
      imageWidget = Icon(Icons.person, size: 80, color: primaryTeal);
    }

    return Center(
      child: CircleAvatar(
        radius: 80,
        backgroundColor: primaryTeal.withOpacity(0.15),
        child: ClipOval(
          child: imageWidget,
        ),
      ),
    );
  }

  // Кнопка для вибору стандартної аватарки
  Widget _buildImageButtons() {
    // 🚀 Використовує ElevatedButtonTheme (Помаранчевий)
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _openAvatarAssetSelectionDialog,
      icon: const Icon(Icons.emoji_people),
      label: const Text('Обрати стандартну аватарку'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}