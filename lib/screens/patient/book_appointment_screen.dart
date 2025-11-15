import 'package:flutter/material.dart';
// Переконайтеся, що цей шлях до вашого ApiService правильний
import 'package:health_app/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// --- КЛАС DOCTOR ---
// Модель для представлення даних про лікаря
class Doctor {
  final String id;
  final String name;
  final String specialization;
  // Ви можете додати сюди 'bio', 'avatarUrl' тощо, якщо потрібно

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
  });

  // Factory-конструктор для легкого створення об'єкта з DocumentSnapshot
  factory Doctor.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Використовуємо 'bio' як 'specialization', якщо 'specialization' немає
    // Ви можете змінити це на будь-яке поле, яке у вас є
    final spec = data['specialization'] as String? ?? data['bio'] as String? ?? 'No specialization provided';

    return Doctor(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Doctor',
      specialization: spec,
    );
  }
}
// --- КІНЕЦЬ КЛАСУ DOCTOR ---


// --- 1. ГОЛОВНИЙ ВІДЖЕТ ЕКРАНУ ---
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = true;
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_US';
    _searchController.addListener(_filterDoctors);
    _loadDoctorsFromServer();
  }

  /// Завантажує список лікарів з вашого ApiService
  Future<void> _loadDoctorsFromServer() async {
    try {
      // Припускаємо, що _apiService.getDoctorsList() повертає QuerySnapshot
      final QuerySnapshot snapshot = await _apiService.getDoctorsList();

      final doctorsList =
      snapshot.docs.map((doc) => Doctor.fromSnapshot(doc)).toList();

      if (mounted) {
        setState(() {
          _allDoctors = doctorsList;
          _filteredDoctors = doctorsList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading doctors: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Фільтрує список лікарів на основі тексту пошуку
  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final doctorLower = doctor.name.toLowerCase();
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

  /// Початкова функція, що викликає вспливаюче вікно
  void _showBookingSheet(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder( // <-- Виправлено! (без 's')
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Передаємо обраного лікаря у віджет вікна
        return _BookingSheetContent(doctor: doctor);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book an Appointment'),
      ),
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
                labelText: 'Search doctor',
                hintText: 'Enter name or surname...',
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
                    ? 'Doctor list is empty'
                    : 'Nothing found for your query',
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
                    child: Text(doctor.name.isNotEmpty
                        ? doctor.name[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(doctor.name),
                  subtitle: Text(
                    doctor.specialization,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () {
                    _showBookingSheet(context, doctor);
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


// --- 2. ВІДЖЕТ ДЛЯ ВМІСТУ ВСІЛИВАЮЧОГО ВІКНА ---
class _BookingSheetContent extends StatefulWidget {
  final Doctor doctor;
  const _BookingSheetContent({required this.doctor});

  @override
  State<_BookingSheetContent> createState() => _BookingSheetContentState();
}

class _BookingSheetContentState extends State<_BookingSheetContent> {
  // Стан для календаря
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Стан для завантаження слотів
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _areSlotsLoading = true;
  List<String> _availableSlots = [];
  String? _selectedSlot;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Завантажуємо слоти для сьогоднішнього дня при відкритті
    _loadAvailableSlots(_focusedDay);
  }

  /// Асинхронно завантажує вільні слоти з Firestore
  Future<void> _loadAvailableSlots(DateTime day) async {
    setState(() {
      _areSlotsLoading = true;
      _availableSlots = [];
      _selectedSlot = null;
    });

    try {
      String doctorId = widget.doctor.id;
      String docId = DateFormat('yyyy-MM-dd').format(day); // '2025-11-20'

      final doc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _availableSlots = List<String>.from(data['slots'] ?? []);
      } else {
        // Якщо документа немає = слотів немає
        _availableSlots = [];
      }
    } catch (e) {
      print('Error loading slots: $e');
      _availableSlots = []; // На випадок помилки
    } finally {
      if (mounted) {
        setState(() {
          _areSlotsLoading = false;
        });
      }
    }
  }

  /// Будує UI для часових слотів (Завантажувач / Повідомлення / Чіпи)
  Widget _buildTimeSlots() {
    if (_areSlotsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availableSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            'No available slots for this day.',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _availableSlots.map((slot) {
        final bool isSelected = _selectedSlot == slot;
        return ChoiceChip(
          label: Text(slot),
          selected: isSelected,
          onSelected: (bool selected) {
            setState(() {
              _selectedSlot = selected ? slot : null;
            });
          },
          selectedColor: Theme.of(context).primaryColor,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
          backgroundColor: Colors.grey[100],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 90% висоти екрану
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "Ручка"
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 1. Інформація про лікаря ---
              Text(
                widget.doctor.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.doctor.specialization,
                maxLines: 2, // На випадок, якщо це 'bio'
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Divider(height: 32),

              // --- 2. Календар ---
              Text(
                'Select a day',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TableCalendar(
                locale: 'en_US',
                firstDay: DateTime.now(), // Не можна обрати минулі дні
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  // При виборі нового дня -> завантажуємо слоти для нього
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadAvailableSlots(selectedDay);
                },
                // --- Обмеження: вимикаємо вихідні (Сб та Нд) ---
                enabledDayPredicate: (day) {
                  if (day.weekday == DateTime.saturday ||
                      day.weekday == DateTime.sunday) {
                    return false;
                  }
                  return true;
                },
                // --- Стилі ---
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: CalendarStyle(
                  disabledTextStyle: TextStyle(color: Colors.grey.shade400),
                  todayDecoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. Вибір часу (динамічний блок) ---
              const Text(
                'Select a time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildTimeSlots(), // Викликаємо наш новий віджет
              const SizedBox(height: 24),

              // --- 4. Коментар ---
              TextField(
                decoration: InputDecoration(
                  labelText: 'Comment (optional)',
                  hintText: 'E.g., "high blood pressure"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- 5. Кнопка "Забронювати" ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    // Використовуємо колір з вашої теми (accentOrange)
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    // TODO: Додати логіку бронювання
                    if (_selectedDay == null || _selectedSlot == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a day and a time slot.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    print(
                        'Booked appointment with ${widget.doctor.name} (ID: ${widget.doctor.id}) on $_selectedDay at $_selectedSlot');
                    Navigator.pop(context); // Закриваємо вікно
                  },
                  child: const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}