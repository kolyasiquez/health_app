import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/doctor/doctor_profile_screen.dart';

// 🚀 ВАЖЛИВО: Імпорт нового віджета деталей
import 'package:health_app/widgets/appointment_details_sheet.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _userName = userData?['name'] ?? 'Doctor';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentOrange = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildHeader(context),
        toolbarHeight: 80,
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        titleSpacing: 16.0,
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
                _buildWelcomeMessage(theme),
                const SizedBox(height: 24),
                _buildCalendarAction(context, theme),
                const SizedBox(height: 30),
                _buildUpcomingAppointments(context, theme),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Елементи ---
  Widget _buildWelcomeMessage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello,',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          _userName ?? 'Doctor',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarAction(BuildContext context, ThemeData theme) {
    return _buildMainActionButton(
      context: context,
      title: 'Manage your calendar',
      subtitle: 'Check your schedule',
      icon: Icons.calendar_month_outlined,
      color: Colors.orange,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageCalendarScreen()),
        );
      },
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context, ThemeData theme) {
    final String currentUserId = _auth.currentUser!.uid;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Future appointments',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('appointments')
              .where('doctorId', isEqualTo: currentUserId)
              .where('date', isGreaterThanOrEqualTo: todayDate)
              .orderBy('date')
              .orderBy('slot')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildNoAppointmentsCard(context);
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final String appointmentId = doc.id;
                // Беремо ID пацієнта для завантаження даних
                final String patientId = data['patientId'] ?? '';

                // 🚀 ОБГОРТАЄМО В GESTURE DETECTOR ДЛЯ ВІДКРИТТЯ ДЕТАЛЕЙ
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => AppointmentDetailsSheet(
                          appointmentId: appointmentId,
                          appointmentData: data,
                          isDoctor: true, // 👈 Лікар може редагувати результати
                        ),
                      );
                    },
                    child: _buildAppointmentCard(
                      context: context,
                      patientId: patientId, // Передаємо ID, щоб картка сама завантажила фото
                      time: data['slot'] ?? '??:??',
                      date: data['date'],
                      reason: data['comment'] ?? 'No comment',
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Картка з завантаженням даних пацієнта (Fix для червоного екрану)
  Widget _buildAppointmentCard({
    required BuildContext context,
    required String patientId,
    required String time,
    required String reason,
    String? date,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    String datePart = '';
    if (date != null) {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(date);
        if (d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day) {
          datePart = 'Today';
        } else {
          datePart = DateFormat('d MMM').format(d);
        }
      } catch (e) { datePart = date; }
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(patientId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator())));
        }

        Map<String, dynamic>? userData;
        if (snapshot.hasData && snapshot.data!.exists) {
          userData = snapshot.data!.data() as Map<String, dynamic>;
        }

        final String name = userData?['name'] ?? 'Unknown Patient';
        final String email = userData?['email'] ?? 'No email';
        final String? avatarUrl = userData?['avatarUrl'];

        ImageProvider? avatarImage;
        if (avatarUrl != null && avatarUrl.isNotEmpty) {
          if (avatarUrl.startsWith('http')) {
            avatarImage = NetworkImage(avatarUrl);
          } else {
            avatarImage = AssetImage(avatarUrl);
          }
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  backgroundImage: avatarImage,
                  child: (avatarImage == null)
                      ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
                  )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      if (reason.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            reason,
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87, fontStyle: FontStyle.italic),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 16),
                      ),
                    ),
                    if (datePart.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        datePart,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoAppointmentsCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green.shade500),
            const SizedBox(width: 12),
            Text(
              'No future appointments',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
    );
    _loadProfileData();
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GestureDetector(
          onTap: _navigateToProfile,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('assets/')
                ? AssetImage(_avatarUrl!)
                : null,
            child: _avatarUrl == null || !_avatarUrl!.startsWith('assets/')
                ? Icon(Icons.person_outline, color: primaryTeal, size: 30)
                : null,
          ),
        ),
      ],
    );
  }
}

// --- ЕКРАН КЕРУВАННЯ КАЛЕНДАРЕМ ---

class ManageCalendarScreen extends StatefulWidget {
  const ManageCalendarScreen({super.key});

  @override
  State<ManageCalendarScreen> createState() => _ManageCalendarScreenState();
}

class _ManageCalendarScreenState extends State<ManageCalendarScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> _allTimeSlots = [
    '08:00','09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00','17:30','18:00','18:30',
    '19:00', '19:30', '20:00', '20:30', '21:00', '21:30',
  ];

  Set<String> _availableSlots = {};
  Set<String> _bookedSlots = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadDayData(_selectedDay!);
  }

  Future<void> _loadDayData(DateTime day) async {
    setState(() {
      _isLoading = true;
      _availableSlots = {};
      _bookedSlots = {};
    });

    if (_auth.currentUser == null) return;

    try {
      String doctorId = _auth.currentUser!.uid;
      String docId = DateFormat('yyyy-MM-dd').format(day);

      final availableDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .get();

      final availableForDay = Set<String>.from(availableDoc.data()?['slots'] ?? []);

      final bookedSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: docId)
          .get();

      final bookedForDay = Set<String>.from(
          bookedSnapshot.docs
              .where((doc){
                final data = doc.data();
                return data['status'] != 'cancelled';
          })
          .map((doc) => doc.data()['slot'] as String)
      );

      if (mounted) {
        setState(() {
          _availableSlots = availableForDay;
          _bookedSlots = bookedForDay;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading day data: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> saveAvailability() async {
    if (_selectedDay == null) return;

    setState(() { _isLoading = true; });
    try {
      String doctorId = _auth.currentUser!.uid;
      String docId = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      final finalAvailableSlots = _availableSlots.difference(_bookedSlots);

      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .set({ 'slots': finalAvailableSlots.toList() });

      if (mounted) {
        setState(() {
          _availableSlots = finalAvailableSlots;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$docId\'s schedule updated!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage your schedule'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isLoading
                ? const Center(child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0),
            ))
                : TextButton(
              onPressed: saveAvailability,
              child: Text(
                'Save',
                style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold
                ),
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TableCalendar(
                  locale: 'en_US',
                  firstDay: DateTime.now().subtract(const Duration(days: 1)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _loadDayData(selectedDay);
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
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Available hours',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedDay != null
                  ? DateFormat('d MMMM, yyyy', 'en_US').format(_selectedDay!)
                  : '',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _allTimeSlots.map((slot) {
                final bool isBooked = _bookedSlots.contains(slot);
                final bool isAvailable = _availableSlots.contains(slot);

                // --- ЛОГІКА ПЕРЕВІРКИ ЧАСУ (БЛОКУВАННЯ МИНУЛОГО) ---
                bool isPastTime = false;
                final now = DateTime.now();

                if (_selectedDay != null && isSameDay(_selectedDay, now)) {
                  final parts = slot.split(':');
                  final hour = int.parse(parts[0]);
                  final minute = int.parse(parts[1]);
                  final slotDateTime = DateTime(now.year, now.month, now.day, hour, minute);

                  if (slotDateTime.isBefore(now)) {
                    isPastTime = true;
                  }
                }
                // --------------------------------

                if (isBooked) {
                  return Chip(
                    label: Text(slot),
                    backgroundColor: Colors.grey.shade400,
                    avatar: Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade800),
                    labelStyle: TextStyle(
                      color: Colors.grey.shade800,
                      decoration: TextDecoration.lineThrough,
                    ),
                  );
                }

                if (isPastTime) {
                  return Chip(
                    label: Text(slot),
                    backgroundColor: Colors.grey.shade200,
                    avatar: Icon(Icons.history, size: 16, color: Colors.grey.shade500),
                    labelStyle: TextStyle(color: Colors.grey.shade500),
                  );
                }

                return ChoiceChip(
                  label: Text(slot),
                  selected: isAvailable,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _availableSlots.add(slot);
                      } else {
                        _availableSlots.remove(slot);
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primary.withOpacity(0.8),
                  labelStyle: TextStyle(
                    color: isAvailable ? Colors.white : Colors.black,
                  ),
                  backgroundColor: Colors.grey[100],
                );

              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}