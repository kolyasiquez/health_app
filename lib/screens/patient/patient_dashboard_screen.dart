import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/patient/health_profile_screen.dart';
// Припускаємо, що ви маєте маршрути у main.dart,
// інакше додайте заглушки для /doctors, /hospitals і т.д.

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
    // Встановлення затримки на 100мс, щоб уникнути можливих race conditions при hot reload
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
    // *** ВИДАЛЕНО НЕПРАВИЛЬНИЙ БЛОК КОДУ, ЩО СПРИЧИНИВ ЗБІЙ ***

    return Scaffold(
      backgroundColor: Colors.deepPurple.shade900, // Темний фон для всього екрану
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildHeader(context),
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
        onRefresh: _loadProfileData,
        color: Colors.deepOrangeAccent,
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
                const SizedBox(height: 30), // Додано простір внизу
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Елементи дизайну ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Привіт,',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            Text(
              _userName ?? 'Користувач',
              style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            // Переходимо на екран профілю і чекаємо, доки користувач повернеться
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthProfileScreen()),
            );
            // Після повернення, оновлюємо дані, щоб показати нову аватарку
            _loadProfileData();
          },
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
            child: _avatarUrl == null
                ? const Icon(Icons.person, color: Colors.deepPurple, size: 30)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade700, // Змінено на темніший фіолетовий
        borderRadius: BorderRadius.circular(10),
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Пошук послуг, лікарів...',
          hintStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Розклад прийомів',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
                  color: isSelected ? Colors.deepOrangeAccent : Colors.deepPurple.shade700, // Акцент кольору
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      ['ПН', 'ВТ', 'СР', 'ЧТ', 'ПТ', 'СБ', 'НД'][date.weekday - 1],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade400,
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
              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            TextButton(
              onPressed: () { /* Перехід до всіх послуг */ },
              child: const Text('ВСІ', style: TextStyle(color: Colors.deepOrangeAccent)),
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
    return GestureDetector(
      onTap: () {
        // Замініть на реальні маршрути
        if (service['route'] != null) {
          Navigator.pushNamed(context, service['route']);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(service['icon'] as IconData, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 5),
          Text(
            service['label'] as String,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyUpdateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ЩОДЕННЕ ОНОВЛЕННЯ',
          style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 15),
        Card(
          color: Colors.deepPurple.shade700, // Змінено на темніший фіолетовий
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Симптоми грипу: на що звернути увагу',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Оновлення від 09 Жовтня. 08:23 AM',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.deepPurple,
                    child: const Icon(Icons.info_outline, color: Colors.white, size: 40),
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