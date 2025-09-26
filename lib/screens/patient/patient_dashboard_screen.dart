// lib/screens/patient/patient_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/patient/health_profile_screen.dart';
// Припускаємо, що у вас є маршрути у main.dart

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final _apiService = ApiService();
  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Завантажує ім'я користувача та URL аватарки з Firestore
  Future<void> _loadProfileData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _userName = userData?['name'] ?? 'Користувач';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;
    final accentOrange = theme.colorScheme.secondary;

    return Scaffold(
      // 🚀 Використовуємо світлий фон Scaffold
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildHeader(context),
        toolbarHeight: 100,
        backgroundColor: primaryTeal, // 🚀 Teal AppBar
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentOrange))
          : RefreshIndicator(
        onRefresh: _loadProfileData,
        color: accentOrange,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildDateSelector(),
                const SizedBox(height: 30),
                _buildServicesSection(context),
                const SizedBox(height: 30),
                _buildDailyUpdateSection(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Елементи дизайну ---

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Привіт,',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              _userName ?? 'Користувач',
              style: theme.textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthProfileScreen()),
            );
            _loadProfileData();
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            // ВИКОРИСТОВУЄМО AssetImage для локальних аватарок
            backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('assets/') ? AssetImage(_avatarUrl!) : null,
            child: _avatarUrl == null || !_avatarUrl!.startsWith('assets/')
                ? Icon(Icons.person, color: primaryTeal, size: 30) // 🚀 Teal іконка
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    // 🚀 Світлий пошук на світлому фоні
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Пошук послуг, лікарів...',
          hintStyle: theme.textTheme.bodySmall,
          border: InputBorder.none,
          icon: Icon(Icons.search, color: primaryTeal.withOpacity(0.7)),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDateSelector() {
    final theme = Theme.of(context);
    final accentOrange = theme.colorScheme.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Розклад прийомів',
          style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index));
              final isSelected = index == 1;

              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  // 🚀 Помаранчевий для вибраного, Білий для не вибраного
                  color: isSelected ? accentOrange : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.colorScheme.onBackground,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'][date.weekday - 1],
                      style: TextStyle(
                        color: isSelected ? Colors.white : theme.textTheme.bodySmall!.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final theme = Theme.of(context);
    final accentOrange = theme.colorScheme.secondary;

    final services = [
      {'icon': Icons.healing, 'label': 'Лікарі', 'route': '/doctors'},
      {'icon': Icons.local_hospital, 'label': 'Лікарні', 'route': '/hospitals'},
      {'icon': Icons.vaccines, 'label': 'Вакцини', 'route': '/vaccines'},
      {'icon': Icons.medical_services, 'label': 'Послуги', 'route': '/services'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ПОСЛУГИ',
              style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            TextButton(
              onPressed: () { /* Перехід до всіх послуг */ },
              child: Text('ВСІ', style: TextStyle(color: accentOrange)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: services.map((service) => _buildServiceIcon(context, service)).toList(),
        ),
      ],
    );
  }

  Widget _buildServiceIcon(BuildContext context, Map<String, dynamic> service) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () {
        if (service['route'] != null) {
          Navigator.pushNamed(context, service['route']);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryTeal, // 🚀 Бірюзовий фон іконки
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(service['icon'] as IconData, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 5),
          Text(
            service['label'] as String,
            style: theme.textTheme.bodyMedium, // Темний/Сірий текст
          ),
        ],
      ),
    );
  }

  Widget _buildDailyUpdateSection() {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ЩОДЕННЕ ОНОВЛЕННЯ',
          style: theme.textTheme.bodySmall!.copyWith(fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 15),
        Card(
          // 🚀 Card тепер білий (з теми)
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Симптоми грипу: на що звернути увагу',
                        style: theme.textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Оновлення від 09 Жовтня. 08:23 AM',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: primaryTeal.withOpacity(0.15),
                    child: Icon(Icons.info_outline, color: primaryTeal, size: 40),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}