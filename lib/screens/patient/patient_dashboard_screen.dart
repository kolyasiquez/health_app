import 'package:flutter/material.dart';
import 'package:health_app/services/api_service.dart';
import 'package:health_app/screens/patient/health_profile_screen.dart';
import 'package:health_app/screens/patient/book_appointment_screen.dart';
// Припускаємо, що у вас є маршрути у main.dart

class PatientDashboardScreen extends StatefulWidget {
  const PatientDashboardScreen({super.key});

  @override
  State<PatientDashboardScreen> createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  final _apiService = ApiService();
  String? _avatarUrl;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// Завантажує ім'я користувача та URL аватарки
  Future<void> _loadProfileData() async {
    // Невелика затримка для демонстрації
    await Future.delayed(const Duration(milliseconds: 100));
    final userData = await _apiService.getUserData();
    if (mounted) {
      setState(() {
        _avatarUrl = userData?['avatarUrl'];
        _userName = userData?['name'] ?? 'Користувач';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentOrange = theme.colorScheme.secondary;

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Чистий білий фон
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
                // 1. Привітання (Збережено)
                _buildWelcomeMessage(theme),
                const SizedBox(height: 30),

                // 2. Головні дії (MVP-версія)
                _buildMvpActions(context, theme),
                const SizedBox(height: 30),

                // 3. Майбутній візит (MVP-версія)
                _buildNextAppointment(context, theme),
                const SizedBox(height: 30),

                // 4. Порада дня (Повертаємо)
                _buildTipOfTheDay(context, theme),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Елементи MVP ---

  Widget _buildWelcomeMessage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Вітаємо в HealthApp,',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w300,
          ),
        ),
        Text(
          _userName ?? 'Користувач', // Використовуємо завантажене ім'я
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 🚀 Нова секція: Головні дії (MVP)
  Widget _buildMvpActions(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Кнопки на всю ширину
      children: [
        _buildMainActionButton(
          context: context,
          title: 'AI Асистент',
          subtitle: 'Запитати про здоров\'я',
          icon: Icons.chat_bubble_outline,
          color: Colors.blue,
          onTap: () {
            // TODO: Додати навігацію на екран чату з AI
          },
        ),
        const SizedBox(height: 16),
        _buildMainActionButton(
          context: context,
          title: 'Записатись на прийом',
          subtitle: 'Знайти вашого лікаря',
          icon: Icons.medical_services_outlined,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const BookAppointmentScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 🚀 Новий, простіший віджет для головних кнопок MVP
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
        side: BorderSide(color: Colors.grey.shade200), // Тонка рамка
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Збільшені відступи
          child: Row(
            children: [
              CircleAvatar(
                radius: 24, // Більша іконка
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

  /// 🚀 Нова секція: Майбутній візит (MVP)
  Widget _buildNextAppointment(BuildContext context, ThemeData theme) {
    // TODO: Тут має бути логіка завантаження *одного* найближчого візиту
    // Якщо візитів немає, можна показати інший віджет.
    // Зараз тут мок-дані для прикладу.
    bool hasAppointment = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ваш наступний візит',
          style: theme.textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        hasAppointment
            ? _buildAppointmentCard(
          context: context,
          doctorName: 'Др. Олена Коваль',
          specialty: 'Кардіолог',
          date: '20 січня 2024',
          time: '14:30',
        )
            : _buildNoAppointmentCard(context),
      ],
    );
  }

  Widget _buildAppointmentCard({
    required BuildContext context,
    required String doctorName,
    required String specialty,
    required String date,
    required String time,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: primaryColor.withOpacity(0.05), // Легкий фон кольору
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: primaryColor.withOpacity(0.1),
                  child: Icon(Icons.person_outline, color: primaryColor),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doctorName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(specialty, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoChip(context, Icons.calendar_month_outlined, date),
                _buildInfoChip(context, Icons.access_time_outlined, time),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoAppointmentCard(BuildContext context) {
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
            Text(
              'У вас немає майбутніх візитів',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoChip(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
        ),
      ],
    );
  }

  // --- Повертаємо Пораду Дня ---

  Widget _buildTipOfTheDay(BuildContext context, ThemeData theme) {
    // 🚀 Колір можна винести в тему, але для MVP підійде і так
    final tipColor = Colors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: tipColor.shade800, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Порада дня',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold, color: tipColor.shade900),
                ),
                const SizedBox(height: 4),
                // TODO: Поради також можна завантажувати з API
                Text(
                  'Пам\'ятайте про регулярне пиття води. Випивайте щонайменше 8 склянок води щодня для оптимальної гідратації.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: tipColor.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // --- Збережені елементи (AppBar та навігація) ---

  /// 🚀 Навігація до профілю
  Future<void> _navigateToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HealthProfileScreen()),
    );
    // Оновлюємо дані (наприклад, аватар) після повернення з екрану профілю
    _loadProfileData();
  }

  /// 🚀 Заголовок перенесено в AppBar
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final primaryTeal = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Тільки аватар в AppBar
      children: [
        GestureDetector(
          onTap: _navigateToProfile, // Зберігаємо перехід до профілю
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200, // Фон для аватара
            // ВИКОРИСТОВУЄМО AssetImage для локальних аватарок
            backgroundImage: _avatarUrl != null && _avatarUrl!.startsWith('assets/')
                ? AssetImage(_avatarUrl!)
                : null,
            child: _avatarUrl == null || !_avatarUrl!.startsWith('assets/')
                ? Icon(Icons.person, color: primaryTeal, size: 30) // Teal іконка
                : null,
          ),
        ),
      ],
    );
  }
}