import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/doctor/doctor_profile_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    // ... (код завантаження профілю без змін)
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
                // 🚀 1. ВИКЛИКАЄМО ОНОВЛЕНИЙ ВІДЖЕТ
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
    // ... (код без змін)
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
    // ... (код без змін, веде на ManageCalendarScreen)
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

  /// 🚀 2. ВІДЖЕТ ОНОВЛЕНО (був _buildTodaysSchedule)
  /// Тепер показує всі майбутні прийоми
  Widget _buildUpcomingAppointments(BuildContext context, ThemeData theme) {
    final String currentUserId = _auth.currentUser!.uid;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Future appointments', // 👈 Змінено заголовок
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('appointments')
              .where('doctorId', isEqualTo: currentUserId)
          // 👈 ЗМІНЕНО ЗАПИТ: 'isGreaterThanOrEqualTo'
              .where('date', isGreaterThanOrEqualTo: todayDate)
              .orderBy('date') // 👈 Додано сортування по даті
              .orderBy('slot')
              .snapshots(),
          builder: (context, snapshot) {
            // ... (обробка помилок та завантаження без змін)
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              // ⚠️ Помилка (ймовірно, просить індекс)
              return Text('Error occurred while trying to load the data: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildNoAppointmentsCard(context);
            }

            // Будуємо список
            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildAppointmentCard(
                    context: context,
                    patientName: data['patientName'] ?? 'Patient',
                    time: data['slot'] ?? '??:??',
                    // 🚀 Додаємо відображення дати у картці
                    date: data['date'] ?? '??-??',
                    reason: data['comment'] ?? 'No comment',
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentCard({
    required BuildContext context,
    required String patientName,
    required String time,
    required String reason,
    String? date, // 🚀 Додано поле дати
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // 🚀 Форматуємо дату, якщо вона є
    String displayTime = time;
    if (date != null) {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(date);
        // Показуємо дату, якщо це НЕ сьогодні
        if (!isSameDay(d, DateTime.now())) {
          displayTime = '${DateFormat('d MMM').format(d)}, $time';
        }
      } catch (e) { /* ігноруємо */ }
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
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                displayTime, // 👈 Відображаємо час (або час + дату)
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patientName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    reason,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.grey.shade400),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAppointmentsCard(BuildContext context) {
    // ... (код без змін)
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
              'No future appointments', // 👈 Змінено текст
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
    // ... (код без змін)
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
    // ... (код без змін)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
    );
    _loadProfileData();
  }

  Widget _buildHeader(BuildContext context) {
    // ... (код без змін)
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


// --- 🚀 3. ЕКРАН КЕРУВАННЯ КАЛЕНДАРЕМ (ОНОВЛЕНО) ---

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

  // 🚀 ОНОВЛЕНО: Два окремих списки
  Set<String> _availableSlots = {}; // Слоти, які лікар зробив доступними
  Set<String> _bookedSlots = {}; // Слоти, які ВЖЕ ЗАБРОНЬОВАНІ пацієнтами

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // 🚀 4. ВИКЛИКАЄМО ОНОВЛЕНУ ФУНКЦІЮ
    _loadDayData(_selectedDay!);
  }

  /// 🚀 5. ОНОВЛЕНА ФУНКЦІЯ
  /// Завантажує І вільні, І заброньовані слоти
  Future<void> _loadDayData(DateTime day) async {
    setState(() {
      _isLoading = true;
      _availableSlots = {}; // Скидаємо
      _bookedSlots = {};    // Скидаємо
    });

    if (_auth.currentUser == null) return;

    try {
      String doctorId = _auth.currentUser!.uid;
      String docId = DateFormat('yyyy-MM-dd').format(day);

      // 1. Отримати ВІЛЬНІ слоти (ті, що лікар зберіг)
      final availableDoc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .get();

      final availableForDay = Set<String>.from(availableDoc.data()?['slots'] ?? []);

      // 2. Отримати ЗАБРОНЬОВАНІ слоти (з appointments)
      final bookedSnapshot = await _firestore
          .collection('appointments')
          .where('doctorId', isEqualTo: doctorId)
          .where('date', isEqualTo: docId)
          .get();

      final bookedForDay = Set<String>.from(
          bookedSnapshot.docs.map((doc) => doc.data()['slot'] as String)
      );

      // 3. Оновити стан
      if (mounted) {
        setState(() {
          _availableSlots = availableForDay;
          _bookedSlots = bookedForDay;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Помилка завантаження даних дня: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  /// 🚀 6. ФУНКЦІЯ ЗБЕРЕЖЕННЯ (ОНОВЛЕНО)
  /// Тепер вона зберігає ТІЛЬКИ ті слоти, що не заброньовані
  Future<void> saveAvailability() async {
    if (_selectedDay == null) return;

    setState(() { _isLoading = true; });
    try {
      String doctorId = _auth.currentUser!.uid;
      String docId = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      // ВАЖЛИВО: Ми переконуємось, що не зберігаємо слоти,
      // які вже заброньовані (на випадок, якщо вони перетинаються)
      final finalAvailableSlots = _availableSlots.difference(_bookedSlots);

      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .set({ 'slots': finalAvailableSlots.toList() }); // Зберігаємо чистий список

      if (mounted) {
        setState(() {
          // Оновлюємо UI, щоб він відповідав збереженим даним
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
            SnackBar(content: Text('Error occurred while trying to update the schedule: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage your schedule'),
        actions: [
          // ... (кнопка "Зберегти" без змін)
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
            // --- Календар ---
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
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // 🚀 7. ВИКЛИКАЄМО ОНОВЛЕНУ ФУНКЦІЮ
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

            // --- Вибір слотів ---
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

            // --- 🚀 8. ОНОВЛЕНА ЛОГІКА ВІДОБРАЖЕННЯ СІТКИ ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _allTimeSlots.map((slot) {
                final bool isBooked = _bookedSlots.contains(slot);
                final bool isAvailable = _availableSlots.contains(slot);

                // --- 🆕 ЛОГІКА ПЕРЕВІРКИ ЧАСУ ---
                bool isPastTime = false;
                final now = DateTime.now();

                // Перевіряємо, чи обраний день - це СЬОГОДНІ
                if (_selectedDay != null && isSameDay(_selectedDay, now)) {
                  // Парсимо слот (наприклад "14:30")
                  final parts = slot.split(':');
                  final hour = int.parse(parts[0]);
                  final minute = int.parse(parts[1]);

                  // Створюємо об'єкт часу для цього слота сьогодні
                  final slotDateTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    hour,
                    minute,
                  );

                  // Якщо час слота менший за поточний час -> це минуле
                  if (slotDateTime.isBefore(now)) {
                    isPastTime = true;
                  }
                }
                // --------------------------------

                // --- 1. Слот вже ЗАБРОНЬОВАНИЙ ---
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

                // --- 2. Слот МИНУВ (НОВА УМОВА) ---
                if (isPastTime) {
                  return Chip(
                    label: Text(slot),
                    backgroundColor: Colors.grey.shade200, // Світліший сірий
                    avatar: Icon(Icons.history, size: 16, color: Colors.grey.shade500), // Іконка годинника
                    labelStyle: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  );
                }

                // --- 3. Слот ВІЛЬНИЙ (можна редагувати) ---
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