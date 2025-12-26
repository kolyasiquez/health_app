import 'dart:async'; // Для таймера каруселі
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/patient/health_profile_screen.dart';
import 'package:health_app/widgets/appointment_details_sheet.dart';

// Переконайтеся, що шлях правильний
import 'package:health_app/screens/ai_assistant/ai_assistant_screen.dart';

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;

  // Змінна для спінера на кнопці ШІ
  bool _isAiLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _userName = userData?['name'] ?? 'Patient';
        _isLoading = false;
      });
    }
  }

  // --- ЛОГІКА ШІ: Збір історії та відкриття екрану ---
  Future<void> _openAIAssistantWithHistory() async {
    setState(() {
      _isAiLoading = true;
    });

    final userId = _auth.currentUser!.uid;
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // 1. Шукаємо минулі візити
      final querySnapshot = await _firestore
          .collection('appointments')
          .where('patientId', isEqualTo: userId)
          .where('date', isLessThanOrEqualTo: todayDate)
          .orderBy('date', descending: true)
          .limit(5)
          .get();

      // 2. Формуємо текст історії
      StringBuffer historyBuffer = StringBuffer();
      historyBuffer.writeln("Patient's Medical History (Last 5 visits):");

      if (querySnapshot.docs.isEmpty) {
        historyBuffer.writeln("No previous medical history recorded.");
      } else {
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final date = data['date'] ?? 'Unknown date';
          final doctor = data['doctorName'] ?? 'Unknown doctor';
          final results = data['visitResults'] ?? 'No notes provided by doctor.';

          historyBuffer.writeln("- Date: $date");
          historyBuffer.writeln("  Doctor: $doctor");
          historyBuffer.writeln("  Results/Notes: $results");
          historyBuffer.writeln("---");
        }
      }

      // 3. Відкриваємо екран ШІ
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AIAssistantScreen(
              medicalContext: historyBuffer.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
        });
      }
    }
  }

  // --- НАВІГАЦІЯ ---
  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthProfileScreen()),
    );
    _loadProfileData(); // Оновлюємо дані після повернення з профілю
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

                // Кнопка ШІ
                _buildAIAssistant(context, theme),
                const SizedBox(height: 8),

                // Кнопка запису до лікаря
                _buildBookAction(context, theme),
                const SizedBox(height: 30),

                // Список записів
                _buildMyAppointments(context, theme),
                const SizedBox(height: 30),

                // 👇 НОВИЙ ЕЛЕМЕНТ: Карусель порад
                const HealthTipsCarousel(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI ВІДЖЕТИ ---

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
                ? Icon(Icons.person, color: primaryTeal, size: 30)
                : null,
          ),
        ),
      ],
    );
  }

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
          _userName ?? 'Patient',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAIAssistant(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: _isAiLoading ? null : _openAIAssistantWithHistory,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                child: Icon(Icons.smart_toy, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Assistant',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isAiLoading ? 'Analyzing history...' : 'Ask AI based on your history',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              _isAiLoading
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookAction(BuildContext context, ThemeData theme) {
    return _buildMainActionButton(
      context: context,
      title: 'Make an appointment',
      subtitle: 'Find a doctor and book an appointment',
      icon: Icons.calendar_month_outlined,
      color: theme.colorScheme.primary,
      onTap: () {
        Navigator.pushNamed(context, '/book_appointment');
      },
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

  Widget _buildMyAppointments(BuildContext context, ThemeData theme) {
    final String currentUserId = _auth.currentUser!.uid;
    final String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My appointments',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('appointments')
              .where('patientId', isEqualTo: currentUserId)
              .where('date', isGreaterThanOrEqualTo: todayDate)
              .orderBy('date')
              .orderBy('slot')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error loading data: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildNoAppointmentsCard(context);
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

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
                          appointmentId: doc.id,
                          appointmentData: data,
                          isDoctor: false,
                        ),
                      );
                    },
                    child: _buildAppointmentCard(
                      context: context,
                      doctorName: data['doctorName'] ?? 'Doctor',
                      date: data['date'] ?? '??-??',
                      time: data['slot'] ?? '??:??',
                      status: data['status'] ?? 'pending',
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

  Widget _buildAppointmentCard({
    required BuildContext context,
    required String doctorName,
    required String date,
    required String time,
    required String status,
  }) {
    final theme = Theme.of(context);
    String formattedDate = '';
    try {
      formattedDate = DateFormat('d MMMM, yyyy').format(DateTime.parse(date));
    } catch (e) {
      formattedDate = date;
    }

    IconData statusIcon = Icons.pending_outlined;
    Color statusColor = Colors.orange;
    if (status == 'confirmed') {
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else if (status == 'cancelled') {
      statusIcon = Icons.cancel_outlined;
      statusColor = Colors.red;
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
            CircleAvatar(
              radius: 24,
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$formattedDate at $time',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
            Icon(Icons.calendar_today_outlined, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'You don\'t have any future appointments',
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 👇 НОВИЙ ВІДЖЕТ: КАРУСЕЛЬ КОРИСНИХ ПОРАД (Daily Tips)
// =========================================================
class HealthTipsCarousel extends StatefulWidget {
  const HealthTipsCarousel({super.key});

  @override
  State<HealthTipsCarousel> createState() => _HealthTipsCarouselState();
}

class _HealthTipsCarouselState extends State<HealthTipsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Локальна база порад
  final List<Map<String, dynamic>> _tips = [
    {
      "icon": Icons.local_drink,
      "color": Colors.blue.shade100,
      "text": "Drink at least 8 glasses of water a day to stay hydrated."
    },
    {
      "icon": Icons.directions_walk,
      "color": Colors.green.shade100,
      "text": "A 30-minute walk daily can significantly improve heart health."
    },
    {
      "icon": Icons.bedtime,
      "color": Colors.indigo.shade100,
      "text": "Good sleep (7-8 hours) improves immunity and mood."
    },
    {
      "icon": Icons.apple,
      "color": Colors.red.shade100,
      "text": "An apple a day... Eating fruits boosts your vitamin intake."
    },
    {
      "icon": Icons.self_improvement,
      "color": Colors.orange.shade100,
      "text": "Take deep breaths. Reducing stress is key to a healthy life."
    },
  ];

  @override
  void initState() {
    super.initState();
    // Автоматичне перемикання кожні 5 секунд
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_currentPage < _tips.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Daily Health Tips',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100, // Висота блоку
          child: PageView.builder(
            controller: _pageController,
            itemCount: _tips.length,
            onPageChanged: (int index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final tip = _tips[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: tip['color'],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.white.withOpacity(0.6),
                        child: Icon(tip['icon'], color: Colors.black54),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
                        child: Center(
                          child: Text(
                            tip['text'],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Індикатор сторінок (крапочки)
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _tips.length,
                (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: _currentPage == index ? 20 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}