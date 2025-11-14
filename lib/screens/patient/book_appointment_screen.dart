import 'package:flutter/material.dart';

// 1. Конвертуємо у StatefulWidget, щоб керувати станом (текст пошуку, список)
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  // 2. Контролер для керування текстом у полі пошуку
  final TextEditingController _searchController = TextEditingController();

  // 3. Повний список лікарів (у реальному додатку це б прийшло з API)
  final List<String> _allDoctors = [
    'Олександр Петренко',
    'Ірина Ковальчук',
    'Василь Сидоренко',
    'Олена Мельник',
    'Андрій Шевченко',
    'Наталія Бойко',
    'Сергій Лисенко',
    'Тетяна Кравченко',
    'Михайло Захаренко',
    'Вікторія Поліщук',
    'Yebiwe Lesnoe',
    'Osla Harmoshka',
    'Hz CheNapisat'
  ];

  // 4. Список, який ми будемо реально показувати (фільтрований)
  List<String> _filteredDoctors = [];

  // 5. Ініціалізуємо стан віджета
  @override
  void initState() {
    super.initState();
    // На початку, відфільтрований список = повний список
    _filteredDoctors = _allDoctors;
    // Додаємо "слухача" до контролера, щоб реагувати на введення тексту
    _searchController.addListener(_filterDoctors);
  }

  // 6. Метод, який буде викликатись при кожній зміні тексту в полі пошуку
  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    // Використовуємо setState, щоб Flutter перебудував UI з новими даними
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        // Проста логіка пошуку: чи містить ім'я лікаря введений текст
        final doctorLower = doctor.toLowerCase();
        return doctorLower.contains(query);
      }).toList();
    });
  }

  // 7. Важливо очистити контролер, коли віджет видаляється
  @override
  void dispose() {
    _searchController.removeListener(_filterDoctors);
    _searchController.dispose();
    super.dispose();
  }

  // 8. Будуємо сам інтерфейс
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book an appointment'),
      ),
      // Використовуємо Column, щоб розмістити віджети один під одним
      body: Column(
        children: [
          // --- ВІДЖЕТ ПОШУКУ ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController, // Прив'язуємо контролер
              decoration: InputDecoration(
                labelText: 'Пошук лікаря',
                hintText: 'Введіть ім\'я або прізвище...',
                prefixIcon: const Icon(Icons.search), // Іконка пошуку
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),

          // --- СПИСОК ЛІКАРІВ ---
          // Expanded, щоб список зайняв увесь простір, що залишився
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDoctors.length, // Кількість елементів = довжина списку
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index]; // Беремо конкретного лікаря

                // Використовуємо ListTile для гарного відображення
                return ListTile(
                  leading: CircleAvatar( // Аватарка-заглушка
                    child: Text(doctor[0]), // Перша буква імені
                  ),
                  title: Text(doctor),
                  subtitle: const Text('Терапевт'), // Можна додати спеціалізацію
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    // Обробка натискання на лікаря
                    print('Обрано лікаря: $doctor');
                    // Тут можна, наприклад, перейти на екран деталей про лікаря
                    // Navigator.push(...);
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