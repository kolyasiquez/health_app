import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:health_app/constants/constants.dart';

// --- КЛАС DOCTOR ---
class Doctor {
  final String id;
  final String name;
  final String specialization;
  final double rating;
  final int reviewCount;
  final String? avatarUrl; // 🚀 НОВЕ ПОЛЕ

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.rating,
    required this.reviewCount,
    this.avatarUrl,
  });

  factory Doctor.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final spec = data['specialization'] as String? ??
        data['bio'] as String? ??
        'General Practitioner';

    final double ratingVal = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
    final int reviewsVal = (data['reviewCount'] is num) ? (data['reviewCount'] as num).toInt() : 0;

    // 🚀 Зчитуємо аватарку
    final String? avatar = data['avatarUrl'] as String?;

    return Doctor(
      id: doc.id,
      name: data['name'] as String? ?? 'Unnamed Doctor',
      specialization: spec,
      rating: ratingVal,
      reviewCount: reviewsVal,
      avatarUrl: avatar,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];

  List<String> _favoriteDoctorIds = [];
  bool _showFavoritesOnly = false;
  String? _selectedSpecialization;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'en_US';
    _searchController.addListener(_filterDoctors);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadDoctorsFromServer(),
      _loadFavorites(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadFavorites() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('patients').doc(user.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('favoriteDoctors')) {
        setState(() {
          _favoriteDoctorIds = List<String>.from(doc.data()!['favoriteDoctors']);
        });
        _filterDoctors();
      }
    } catch (e) {
      print("Error loading favorites: $e");
    }
  }

  Future<void> _toggleFavorite(String doctorId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final isFavorite = _favoriteDoctorIds.contains(doctorId);

    setState(() {
      if (isFavorite) {
        _favoriteDoctorIds.remove(doctorId);
      } else {
        _favoriteDoctorIds.add(doctorId);
      }
      _filterDoctors();
    });

    final userRef = _firestore.collection('patients').doc(user.uid);

    try {
      if (isFavorite) {
        await userRef.update({
          'favoriteDoctors': FieldValue.arrayRemove([doctorId])
        });
      } else {
        await userRef.set({
          'favoriteDoctors': FieldValue.arrayUnion([doctorId])
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print("Error toggling favorite: $e");
    }
  }

  Future<void> _loadDoctorsFromServer() async {
    try {
      final QuerySnapshot snapshot = await _apiService.getDoctorsList();
      final doctorsList = snapshot.docs.map((doc) => Doctor.fromSnapshot(doc)).toList();

      if (mounted) {
        setState(() {
          _allDoctors = doctorsList;
          _filteredDoctors = doctorsList;
        });
      }
    } catch (e) {
      print('Error loading doctors: $e');
    }
  }

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredDoctors = _allDoctors.where((doctor) {
        final nameMatches = doctor.name.toLowerCase().contains(query);
        final specMatches = _selectedSpecialization == null ||
            doctor.specialization == _selectedSpecialization;
        final favoriteMatches = !_showFavoritesOnly || _favoriteDoctorIds.contains(doctor.id);

        return nameMatches && specMatches && favoriteMatches;
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
      appBar: AppBar(title: const Text('Book an Appointment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                ),
                const SizedBox(height: 12),
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

                const SizedBox(height: 12),

                Container(
                  decoration: BoxDecoration(
                    color: _showFavoritesOnly ? Colors.red.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _showFavoritesOnly ? Colors.red.withOpacity(0.3) : Colors.transparent
                    ),
                  ),
                  child: SwitchListTile(
                    title: const Text(
                      "Show Favorites Only",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    secondary: Icon(
                      _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    value: _showFavoritesOnly,
                    activeColor: Colors.red,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onChanged: (bool value) {
                      setState(() {
                        _showFavoritesOnly = value;
                        _filterDoctors();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _filteredDoctors.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                      _showFavoritesOnly ? Icons.favorite_border : Icons.person_search,
                      size: 60,
                      color: Colors.grey[300]
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _showFavoritesOnly
                        ? "No favorite doctors found."
                        : "No doctors match your criteria.",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _filteredDoctors.length,
              itemBuilder: (context, index) {
                final doctor = _filteredDoctors[index];
                final isFavorite = _favoriteDoctorIds.contains(doctor.id);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      // 🚀 ЛОГІКА ВІДОБРАЖЕННЯ АВАТАРКИ
                      backgroundImage: (doctor.avatarUrl != null && doctor.avatarUrl!.isNotEmpty)
                          ? (doctor.avatarUrl!.startsWith('assets/')
                          ? AssetImage(doctor.avatarUrl!) as ImageProvider
                          : NetworkImage(doctor.avatarUrl!))
                          : null,
                      child: (doctor.avatarUrl == null || doctor.avatarUrl!.isEmpty)
                          ? Text(
                        doctor.name.isNotEmpty ? doctor.name[0].toUpperCase() : '?',
                        style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 24),
                      )
                          : null,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),

                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(doctor.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(doctor.specialization, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                        const SizedBox(height: 6),

                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              doctor.rating > 0 ? doctor.rating.toStringAsFixed(1) : "New",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            Text("(${doctor.reviewCount} reviews)", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
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

        final now = DateTime.now();
        final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

        if (isToday){
          _availableSlots.removeWhere((slot){
            try {
              final parts = slot.split(':');
              final hour = int.parse(parts[0]);
              final minute = int.parse(parts[1]);
              final slotTime = DateTime(now.year, now.month, now.day, hour, minute);
              return slotTime.isBefore(now);
            } catch (e) {
              return false;
            }
          });
        }
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

  Future<void> _bookAppointment() async {
    if (_selectedDay == null || _selectedSlot == null) return;

    setState(() { _isBooking = true; });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final String patientId = user.uid;
      final String patientName = user.displayName ?? user.email ?? 'Patient';

      final String doctorId = widget.doctor.id;
      final String docDateId = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      final doctorSlotRef = _firestore.collection('doctors').doc(doctorId).collection('availability').doc(docDateId);
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
        await showDialog(
          context: context,
          barrierDismissible: false,
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
                    Navigator.pop(context);
                    Navigator.pop(context);
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

              // 🚀 АВАТАРКА В ШТОРЦІ (оновлено)
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    backgroundImage: (widget.doctor.avatarUrl != null && widget.doctor.avatarUrl!.isNotEmpty)
                        ? (widget.doctor.avatarUrl!.startsWith('assets/')
                        ? AssetImage(widget.doctor.avatarUrl!) as ImageProvider
                        : NetworkImage(widget.doctor.avatarUrl!))
                        : null,
                    child: (widget.doctor.avatarUrl == null || widget.doctor.avatarUrl!.isEmpty)
                        ? Text(
                      widget.doctor.name.isNotEmpty ? widget.doctor.name[0].toUpperCase() : '?',
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 24),
                    )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start, // 👈 Щоб вирівняти по верху
                          children: [
                            Expanded(
                              child: Text(
                                widget.doctor.specialization,
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                                // Ми прибрали maxLines і overflow - тепер текст переноситься сам
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Блок рейтингу залишається праворуч
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            Text(
                              widget.doctor.rating > 0
                                  ? " ${widget.doctor.rating.toStringAsFixed(1)}"
                                  : " New",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
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