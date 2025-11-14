import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart'; // Перевірте шлях
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// --- КЛАС DOCTOR (без змін) ---
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
    return Doctor(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Doctor', // <-- (теж переклав)
      specialization:
      data['specialization'] as String? ?? 'No specialization', // <-- (теж переклав)
    );
  }
}
// --- КІНЕЦЬ КЛАСУ DOCTOR ---

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
    // 1. ЗМІНЮЄМО ЛОКАЛЬ ЗА ЗАМОВЧУВАННЯМ
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
      print('Error loading doctors: $e'); // <-- (переклав)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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

  void _showBookingSheet(BuildContext context, Doctor doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder( // <-- Тут виправлено 's'
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
        // 2. ПЕРЕКЛАДАЄМО ТЕКСТ
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
                // 3. ПЕРЕКЛАДАЄМО ТЕКСТ
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
                    ? 'Doctor list is empty' // 4. ПЕРЕКЛАДАЄМО
                    : 'Nothing found for your query', // 5. ПЕРЕКЛАДАЄМО
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
                  subtitle: Text(doctor.specialization),
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

// --- ВІДЖЕТ ДЛЯ ВМІСТУ MODAL SHEET ---
class _BookingSheetContent extends StatefulWidget {
  final Doctor doctor;
  const _BookingSheetContent({required this.doctor});

  @override
  State<_BookingSheetContent> createState() => _BookingSheetContentState();
}

class _BookingSheetContentState extends State<_BookingSheetContent> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
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
              // Handle
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

              // --- 1. Doctor Info ---
              Text(
                widget.doctor.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                widget.doctor.specialization,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Divider(height: 32),

              // --- 2. Calendar ---
              Text(
                // 6. ПЕРЕКЛАДАЄМО
                'Select a day',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TableCalendar(
                // 7. ЗМІНЮЄМО ЛОКАЛЬ КАЛЕНДАРЯ
                locale: 'en_US',
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                calendarFormat: CalendarFormat.month,
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: CalendarStyle(
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

              // --- 3. Time Slots ---
              const Text(
                // 8. ПЕРЕКЛАДАЄМО
                'Select a time',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Placeholder chips (can be left as is)
              const Wrap(
                spacing: 8.0,
                children: [
                  Chip(label: Text('10:00')),
                  Chip(label: Text('10:30')),
                  Chip(label: Text('11:00')),
                ],
              ),
              const SizedBox(height: 24),

              // --- 4. Comment field ---
              TextField(
                decoration: InputDecoration(
                  // 9. ПЕРЕКЛАДАЄМО
                  labelText: 'Comment (optional)',
                  hintText: 'E.g., "high blood pressure"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // --- 5. Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    print(
                        'Booked appointment with ${widget.doctor.name} (ID: ${widget.doctor.id}) on $_selectedDay');
                    Navigator.pop(context);
                  },
                  child: const Text(
                    // 10. ПЕРЕКЛАДАЄМО
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