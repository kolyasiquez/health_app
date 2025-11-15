import 'package:flutter/material.dart';
// Переконайтеся, що цей шлях до вашого ApiService правильний
import 'package:health_app/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🚀 ДОДАНО

// --- КЛАС DOCTOR ---
class Doctor {
  final String id;
  final String name;
  final String specialization;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
  });

  factory Doctor.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
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

  /// Завантажує список лікарів
  Future<void> _loadDoctorsFromServer() async {
    try {
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
      if (mounted) { setState(() { _isLoading = false; }); }
    }
  }

  /// Фільтрує список лікарів
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

  /// Викликає вспливаюче вікно
  void _showBookingSheet(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
  // Стан календаря
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Стан слотів
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _areSlotsLoading = true;
  List<String> _availableSlots = [];
  String? _selectedSlot;

  // 🚀 Стан бронювання
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isBooking = false;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAvailableSlots(_focusedDay);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
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
      String docId = DateFormat('yyyy-MM-dd').format(day);

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
        _availableSlots = [];
      }
    } catch (e) {
      print('Error loading slots: $e');
      _availableSlots = [];
    } finally {
      if (mounted) {
        setState(() {
          _areSlotsLoading = false;
        });
      }
    }
  }

  /// 🚀 ГОЛОВНА ЛОГІКА: Бронювання прийому
  Future<void> _bookAppointment() async {
    if (_selectedDay == null || _selectedSlot == null) {
      // ... (перевірка)
      return;
    }

    setState(() { _isBooking = true; });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String patientId = user.uid;
      // TODO: Отримайте ім'я пацієнта з його профілю
      final String patientName = user.displayName ?? user.email ?? 'Patient';

      final String doctorId = widget.doctor.id;
      final String docDateId = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      final doctorSlotRef = _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docDateId);

      final newAppointmentRef = _firestore.collection('appointments').doc();

      final appointmentData = {
        'doctorId': doctorId,
        'doctorName': widget.doctor.name,
        'patientId': patientId,
        'patientName': patientName,
        'date': docDateId,
        'slot': _selectedSlot,
        'comment': _commentController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // --- 🚀 Атомна Транзакція ---
      await _firestore.runTransaction((transaction) async {
        // 1. Читаємо поточні слоти
        final slotDoc = await transaction.get(doctorSlotRef);

        if (!slotDoc.exists) {
          throw Exception("Doctor's schedule not found.");
        }

        List<String> currentSlots = List<String>.from(slotDoc.data()!['slots'] ?? []);

        // 2. Перевіряємо, чи слот ще там
        if (!currentSlots.contains(_selectedSlot!)) {
          throw Exception("Slot just became unavailable. Please refresh.");
        }

        // 3. Видаляємо слот
        currentSlots.remove(_selectedSlot!);

        // 4. Оновлюємо графік лікаря
        transaction.update(doctorSlotRef, {'slots': currentSlots});

        // 5. Створюємо новий запис
        transaction.set(newAppointmentRef, appointmentData);
      });
      // --- Кінець Транзакції ---

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Закриваємо вікно
      }

    } catch (e) {
      print('Error booking appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isBooking = false; });
      }
    }
  }

  /// Будує UI для часових слотів
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
              // --- 1. Інфо про лікаря ---
              Text(
                widget.doctor.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                widget.doctor.specialization,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Divider(height: 32),
              // --- 2. Календар ---
              Text('Select a day', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              TableCalendar(
                locale: 'en_US',
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _loadAvailableSlots(selectedDay);
                },
                // enabledDayPredicate: (day) {
                //   if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
                //     return false;
                //   }
                //   return true;
                // },
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
              // --- 3. Вибір часу ---
              const Text('Select a time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTimeSlots(),
              const SizedBox(height: 24),
              // --- 4. Коментар ---
              TextField(
                controller: _commentController, // 🚀 ПІДКЛЮЧЕНО
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
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: (_selectedSlot == null || _isBooking)
                      ? null // Неактивна
                      : _bookAppointment, // Активна
                  child: _isBooking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
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