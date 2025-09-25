// lib/screens/appointment/appointment_list_screen.dart

import 'package:flutter/material.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Тимчасові дані для демонстрації
    final appointments = [
      {
        'doctorName': 'Доктор Олексій Іванов',
        'specialty': 'Терапевт',
        'date': '25 Жовтня, 2025',
        'time': '10:00',
        'status': 'Заплановано',
      },
      {
        'doctorName': 'Доктор Олена Ковальчук',
        'specialty': 'Кардіолог',
        'date': '18 Вересня, 2025',
        'time': '14:30',
        'status': 'Завершено',
      },
      {
        'doctorName': 'Доктор Андрій Петренко',
        'specialty': 'Дерматолог',
        'date': '05 Листопада, 2025',
        'time': '09:00',
        'status': 'Заплановано',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мої записи на прийом'),
      ),
      body: appointments.isEmpty
          ? const Center(
        child: Text(
          'У вас немає запланованих візитів.',
          style: TextStyle(color: Colors.white54),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return AppointmentCard(appointment: appointment);
        },
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context) {
    // Визначення кольору картки залежно від статусу
    Color statusColor = Colors.deepPurpleAccent;
    if (appointment['status'] == 'Завершено') {
      statusColor = Colors.green;
    } else if (appointment['status'] == 'Заплановано') {
      statusColor = Colors.orange;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.2),
                  child: Icon(Icons.person, color: statusColor),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment['doctorName'],
                        style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        appointment['specialty'],
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  appointment['status'] == 'Завершено' ? Icons.check_circle_outline : Icons.pending_actions,
                  color: statusColor,
                ),
              ],
            ),
            const Divider(height: 32, thickness: 1, color: Colors.grey),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoColumn(Icons.calendar_today, appointment['date']),
                _buildInfoColumn(Icons.access_time, appointment['time']),
                _buildInfoColumn(Icons.info_outline, appointment['status']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurpleAccent),
        const SizedBox(height: 4.0),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ],
    );
  }
}