import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/doctor/doctor_profile_screen.dart'; // 🚀 Імпортуємо профіль лікаря

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
  bool _isOnline = true; // 🚀 Стан для лікаря (онлайн/офлайн)

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Завантажує ім'я користувача та URL аватарки
  Future<void> _loadProfileData() async {
    // Невелика затримка для демонстрації
    await Future.delayed(const Duration(milliseconds: 100));
    // Припускаємо, що getUserData() повертає дані залогіненого юзера (лікаря)
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
    final theme = Theme.of(context);
    final accentOrange = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: _buildHeader(context), // 🚀 Використовуємо той самий хедер
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
                // 1. Привітання (Той самий стиль)
                _buildWelcomeMessage(theme),
                const SizedBox(height: 24),

                // 2. Статус лікаря (Новий віджет)
                _buildStatusSwitch(theme),
                const SizedBox(height: 30),

                // 3. Головна дія (MVP-версія для лікаря)
                _buildCalendarAction(context, theme),
                const SizedBox(height: 30),

                // 4. Пацієнти на сьогодні (MVP-версія для лікаря)
                _buildTodaysSchedule(context, theme),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Елементи MVP Лікаря ---

  Widget _buildWelcomeMessage(ThemeData theme) {
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
          _userName ?? 'Лікар', // Використовуємо завантажене ім'я
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 🚀 Новий віджет: Перемикач статусу
  Widget _buildStatusSwitch(ThemeData theme) {
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
                    // TODO: Додати виклик API для оновлення статусу
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

  /// 🚀 Головна дія лікаря
  Widget _buildCalendarAction(BuildContext context, ThemeData theme) {
    return _buildMainActionButton( // 🚀 Використовуємо той самий стиль кнопки
      context: context,
      title: 'Керувати календарем',
      subtitle: 'Відкрити слоти та графік',
      icon: Icons.calendar_month_outlined,
      color: Colors.orange,
      onTap: () {
        // TODO: Додати навігацію на екран керування календарем
      },
    );
  }

  /// 🚀 Секція "Сьогодні на прийомі"
  Widget _buildTodaysSchedule(BuildContext context, ThemeData theme) {
    // TODO: Тут має бути логіка завантаження списку пацієнтів на сьогодні
    // Зараз тут мок-дані для прикладу.
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

  /// 🚀 Картка прийому для лікаря
  Widget _buildAppointmentCard({
    required BuildContext context,
    required String patientName,
    required String time,
    required String reason,
  }) {
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
              onPressed: () {
                // TODO: Навігація на деталі прийому або профіль пацієнта
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🚀 Картка "Немає прийомів"
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
              'На сьогодні прийомів немає',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // --- Віджет кнопки (той самий, що у пацієнта) ---

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

  // --- AppBar та Навігація (як у пацієнта) ---

  /// 🚀 Навігація до профілю лікаря
  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DoctorProfileScreen()),
    );
    // Оновлюємо дані (наприклад, аватар) після повернення з екрану профілю
    _loadProfileData();
  }

  /// 🚀 Заголовок (той самий, що у пацієнта)
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Тільки аватар в AppBar
      children: [
        GestureDetector(
          onTap: _navigateToProfile, // Веде на профіль лікаря
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('assets/')
                ? AssetImage(_avatarUrl!)
                : null,
            child: _avatarUrl == null || !_avatarUrl!.startsWith('assets/')
                ? Icon(Icons.person_outline, color: primaryTeal, size: 30) // 🚀 Використовуємо іншу іконку для лікаря
                : null,
          ),
        ),
      ],
    );
  }
}