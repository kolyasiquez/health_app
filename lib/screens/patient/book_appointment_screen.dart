import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_app/constants/constants.dart'; // Переконайтеся, що шлях правильний

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
    final spec = data['specialization'] as String? ??
        data['bio'] as String? ??
        'General Practitioner';

    return Doctor(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Doctor',
      specialization: spec,
    );
  }
}

// --- ГОЛОВНИЙ ЕКРАН ---
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

  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_US';
    _searchController.addListener(_filterDoctors);
    _loadDoctorsFromServer();
  }

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

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final nameMatches = doctor.name.toLowerCase().contains(query);
        final specMatches = _selectedSpecialization == null ||
            doctor.specialization == _selectedSpecialization;
        return nameMatches && specMatches;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterDoctors);
    _searchController.dispose();
    super.dispose();
  }

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book an Appointment'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // --- БЛОК ПОШУКУ ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search doctor',
                    hintText: 'Enter name...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Фільтр
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSpecialization,
                      hint: Row(
                        children: const [
                          Icon(Icons.filter_list, color: Colors.grey),
                          SizedBox(width: 8),
                          Text("Filter by Specialization"),
                        ],
                      ),
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedSpecialization = newValue;
                          _filterDoctors();
                        });
                      },
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text("All Specializations", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...kSpecializations.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- СПИСОК ЛІКАРІВ ---
          Expanded(
            child: _filteredDoctors.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_search, size: 60, color: Colors.grey),
                  const SizedBox(height: 10),
                  Text(
                    _allDoctors.isEmpty
                        ? 'No doctors available yet.'
                        : 'No doctors found matching criteria.',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 25,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 20
                        ),
                      ),
                    ),
                    title: Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doctor.specialization,
                        style: TextStyle(color: Colors.grey.shade800, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    trailing: Icon(Icons.calendar_today, color: theme.colorScheme.secondary),
                    onTap: () {
                      _showBookingSheet(context, doctor);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- ВМІСТ ШТОРКИ БРОНЮВАННЯ ---
class _BookingSheetContent extends StatefulWidget {
  final Doctor doctor;
  const _BookingSheetContent({required this.doctor});

  @override
  State<_BookingSheetContent> createState() => _BookingSheetContentState();
}

class _BookingSheetContentState extends State<_BookingSheetContent> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _areSlotsLoading = true;
  List<String> _availableSlots = [];
  String? _selectedSlot;

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
        _availableSlots.sort();
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

  // 🚀 ГОЛОВНА ЛОГІКА БРОНЮВАННЯ + ДІАЛОГ
  Future<void> _bookAppointment() async {
    if (_selectedDay == null || _selectedSlot == null) return;

    setState(() { _isBooking = true; });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String patientId = user.uid;
      // Спроба взяти ім'я або email, якщо ім'я пусте
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
        'status': 'pending', // ⚠️ Статус за замовчуванням
        'createdAt': FieldValue.serverTimestamp(),
      };

      // --- Транзакція ---
      await _firestore.runTransaction((transaction) async {
        final slotDoc = await transaction.get(doctorSlotRef);
        if (!slotDoc.exists) throw Exception("Doctor's schedule not found.");

        List<String> currentSlots = List<String>.from(slotDoc.data()!['slots'] ?? []);
        if (!currentSlots.contains(_selectedSlot!)) {
          throw Exception("Slot just became unavailable.");
        }

        currentSlots.remove(_selectedSlot!);
        transaction.update(doctorSlotRef, {'slots': currentSlots});
        transaction.set(newAppointmentRef, appointmentData);
      });

      if (mounted) {
        // 🚀 НОВЕ: Показуємо гарний діалог замість простого SnackBar
        await showDialog(
          context: context,
          barrierDismissible: false, // Користувач мусить натиснути кнопку
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 10),
                Text("Request Sent!", textAlign: TextAlign.center),
              ],
            ),
            content: const Text(
              "Thank you for your reservation.\n\n"
                  "Your appointment status is currently PENDING.\n"
                  "Please wait for the doctor to confirm the visit. "
                  "You can check the status in 'My Appointments'.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // Закрити діалог
                    Navigator.pop(context); // Закрити шторку бронювання (повернутися на список)
                  },
                  child: const Text("OK, Got it"),
                ),
              ),
            ],
          ),
        );
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

              const Text('Select time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildTimeSlots(),
              const SizedBox(height: 24),

              TextField(
                controller: _commentController,
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

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: (_selectedSlot == null || _isBooking)
                      ? null
                      : _bookAppointment,
                  child: _isBooking
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                      : const Text(
                    'Book Appointment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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