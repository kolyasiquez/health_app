import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Потрібно для QuerySnapshot

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _apiService = ApiService();

  // Додаємо стан завантаження
  bool _isLoading = true;

  // Списки, як і раніше, будуть List<String>
  List<String> _allDoctors = [];
  List<String> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDoctors);
    // Запускаємо асинхронне завантаження
    _loadDoctorsFromServer();
  }

  /// Новий метод для АСИНХРОННОГО завантаження
  Future<void> _loadDoctorsFromServer() async {
    try {
      final QuerySnapshot snapshot = await _apiService.getDoctorsList();

      // "Розпаковуємо" QuerySnapshot у List<String>
      final doctorsList = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        // Переконайтеся, що поле 'name' існує у ваших документах
        return data?['name'] as String? ?? 'Лікар без імені';
      }).toList();

      // Оновлюємо стан, коли дані прийшли
      if (mounted) {
        setState(() {
          _allDoctors = doctorsList;
          _filteredDoctors = doctorsList;
          _isLoading = false; // Завантаження завершено
        });
      }
    } catch (e) {
      print('Помилка завантаження лікарів: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Метод фільтрації (без змін)
  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final doctorLower = doctor.toLowerCase();
        return doctorLower.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDoctors);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Запис на прийом'),
      ),
      // Використовуємо _isLoading для показу індикатора
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- ВІДЖЕТ ПОШУКУ ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Пошук лікаря',
                hintText: 'Введіть ім\'я або прізвище...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),

          // --- СПИСОК ЛІКАРІВ ---
          Expanded(
            child: _filteredDoctors.isEmpty
                ? Center(
              child: Text(
                _allDoctors.isEmpty
                    ? 'Список лікарів порожній'
                    : 'Нічого не знайдено за запитом',
                style: const TextStyle(
                    fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index];
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(doctor.isNotEmpty &&
                        doctor.length > 3
                        ? doctor[3]
                        : '?'),
                  ),
                  title: Text(doctor),
                  // TODO: Завантажувати спеціалізацію разом з іменем
                  subtitle: const Text('Спеціалізація'),
                  trailing:
                  const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    print('Обрано лікаря: $doctor');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}