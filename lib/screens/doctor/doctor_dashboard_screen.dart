import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/doctor/doctor_profile_screen.dart';

// 🚀 1. ДОДАНО НЕОБХІДНІ ІМПОРТИ
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
  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Завантажує ім'я користувача та URL аватарки
  Future<void> _loadProfileData() async {
    // ... (ваш код без змін)
    await Future.delayed(const Duration(milliseconds: 100));
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _userName = userData?['name'] ?? 'Лікар';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (ваш build метод без змін) ...
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
                _buildStatusSwitch(theme),
                const SizedBox(height: 30),
                _buildCalendarAction(context, theme), // <-- Ця кнопка тепер працює
                const SizedBox(height: 30),
                _buildTodaysSchedule(context, theme),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Елементи MVP Лікаря (без змін) ---
  Widget _buildWelcomeMessage(ThemeData theme) {
    // ... (ваш код без змін)
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Вітаємо,',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          _userName ?? 'Лікар',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch(ThemeData theme) {
    // ... (ваш код без змін)
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  _isOnline ? Icons.check_circle_outline : Icons.pause_circle_outline,
                  color: _isOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Text(
                  'Ваш статус',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Transform.scale(
              scale: 0.9,
              child: Switch(
                value: _isOnline,
                onChanged: (value) {
                  setState(() {
                    _isOnline = value;
                  });
                },
                activeColor: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚀 Головна дія лікаря (ОНОВЛЕНО)
  Widget _buildCalendarAction(BuildContext context, ThemeData theme) {
    return _buildMainActionButton(
      context: context,
      title: 'Керувати календарем',
      subtitle: 'Відкрити слоти та графік',
      icon: Icons.calendar_month_outlined,
      color: Colors.orange,
      onTap: () {
        // 🚀 2. ДОДАНО НАВІГАЦІЮ НА НОВИЙ ЕКРАН
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ManageCalendarScreen()),
        );
      },
    );
  }

  Widget _buildTodaysSchedule(BuildContext context, ThemeData theme) {
    // ... (ваш код без змін)
    bool hasAppointments = true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Сьогодні на прийомі',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        hasAppointments
            ? Column(
          children: [
            _buildAppointmentCard(
              context: context,
              patientName: 'Маркоува Денисовна',
              time: '14:30',
              reason: 'Загальний огляд',
            ),
            const SizedBox(height: 12),
            _buildAppointmentCard(
              context: context,
              patientName: 'Олена Іванова',
              time: '15:00',
              reason: 'Консультація',
            ),
          ],
        )
            : _buildNoAppointmentsCard(context),
      ],
    );
  }

  Widget _buildAppointmentCard({
    required BuildContext context,
    required String patientName,
    required String time,
    required String reason,
  }) {
    // ... (ваш код без змін)
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

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
                time,
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
    // ... (ваш код без змін)
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
              'На сьогодні прийомів немає',
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
    // ... (ваш код без змін)
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
    // ... (ваш код без змін)
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
    );
    _loadProfileData();
  }

  Widget _buildHeader(BuildContext context) {
    // ... (ваш код без змін)
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


// --- 🚀 3. ДОДАНО НОВИЙ ЕКРАН КЕРУВАННЯ КАЛЕНДАРЕМ ---

class ManageCalendarScreen extends StatefulWidget {
  const ManageCalendarScreen({super.key});

  @override
  State<ManageCalendarScreen> createState() => _ManageCalendarScreenState();
}

class _ManageCalendarScreenState extends State<ManageCalendarScreen> {
  // --- 1. Firebase та Стан ---
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Всі можливі слоти, які лікар може обрати
  final List<String> _allTimeSlots = [
    '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30',
    '15:00', '15:30', '16:00', '16:30', '17:00',
  ];

  // Слоти, які лікар обрав для цього дня (використовуємо Set)
  Set<String> _selectedSlots = {};

  bool _isLoading = true; // Для завантаження/збереження

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Завантажуємо вже збережені слоти для сьогодні
    _loadSavedSlots(_selectedDay!);
  }

  /// 🚀 Завантажує збережені слоти, щоб лікар бачив свій графік
  Future<void> _loadSavedSlots(DateTime day) async {
    setState(() { _isLoading = true; });
    try {
      String doctorId = _auth.currentUser!.uid;
      String docId = DateFormat('yyyy-MM-dd').format(day);

      final doc = await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        setState(() {
          _selectedSlots = Set<String>.from(doc.data()!['slots'] ?? []);
        });
      } else {
        setState(() {
          _selectedSlots = {}; // Немає збережених слотів
        });
      }
    } catch (e) {
      print("Помилка завантаження слотів: $e");
      setState(() {
        _selectedSlots = {};
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  /// 🚀 4. ФУНКЦІЯ ЗБЕРЕЖЕННЯ (яку ви питали)
  Future<void> saveAvailability() async {
    if (_selectedDay == null) return;

    setState(() { _isLoading = true; });
    try {
      String doctorId = _auth.currentUser!.uid;
      String docId = DateFormat('yyyy-MM-dd').format(_selectedDay!);

      await _firestore
          .collection('doctors')
          .doc(doctorId)
          .collection('availability')
          .doc(docId)
          .set({
        // Зберігаємо обрані слоти як список
        'slots': _selectedSlots.toList()
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Графік на $docId оновлено!'), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Помилка збереження: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Керування графіком'),
        // Кнопка "Зберегти" в AppBar
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : TextButton(
              onPressed: saveAvailability, // Викликаємо збереження
              child: Text(
                'Зберегти',
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
                  locale: 'en_US', // Ви можете змінити на 'uk_UA'
                  firstDay: DateTime.now().subtract(const Duration(days: 30)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // Завантажуємо слоти для нового обраного дня
                    _loadSavedSlots(selectedDay);
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
              'Доступні години',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _selectedDay != null
                  ? DateFormat('d MMMM, yyyy').format(_selectedDay!)
                  : '',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // --- Сітка з ChoiceChip ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _allTimeSlots.map((slot) {
                final isSelected = _selectedSlots.contains(slot);
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    // Додаємо або видаляємо слот з набору
                    setState(() {
                      if (selected) {
                        _selectedSlots.add(slot);
                      } else {
                        _selectedSlots.remove(slot);
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primary.withOpacity(0.8),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
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