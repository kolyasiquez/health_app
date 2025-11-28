import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsSheet extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final bool isDoctor; // 👈 Головний перемикач логіки

  const AppointmentDetailsSheet({
    super.key,
    required this.appointmentId,
    required this.appointmentData,
    required this.isDoctor,
  });

  @override
  State<AppointmentDetailsSheet> createState() => _AppointmentDetailsSheetState();
}

class _AppointmentDetailsSheetState extends State<AppointmentDetailsSheet> {
  final TextEditingController _resultsController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Завантажуємо існуючі результати, якщо вони є
    _resultsController.text = widget.appointmentData['visitResults'] ?? '';
  }

  @override
  void dispose() {
    _resultsController.dispose();
    super.dispose();
  }

  Future<void> _saveResults() async {
    setState(() { _isSaving = true; });

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'visitResults': _resultsController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context); // Закриваємо вікно
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Результати збережено!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.appointmentData;

    // Форматування дати
    String formattedDate = data['date'];
    try {
      final date = DateFormat('yyyy-MM-dd').parse(data['date']);
      formattedDate = DateFormat('d MMMM yyyy').format(date);
    } catch (_) {}

    return Container(
      padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20 // Для клавіатури
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Ручка"
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            // Заголовок
            Text(
              widget.isDoctor ? 'Patient Details' : 'Appointment Details',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),

            // Інформація про учасників
            _buildInfoRow(Icons.person, widget.isDoctor ? 'Patient' : 'Doctor',
                widget.isDoctor ? (data['patientName'] ?? 'Unknown') : (data['doctorName'] ?? 'Unknown')),
            _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', data['slot']),

            // Коментар пацієнта (скарга)
            if (data['comment'] != null && data['comment'].toString().isNotEmpty)
              _buildInfoRow(Icons.comment, 'Complaint / Reason', data['comment']),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // --- БЛОК РЕЗУЛЬТАТІВ ВІЗИТУ ---
            Text(
              'Visit Results / Doctor Notes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _resultsController,
              maxLines: 5,
              // 🚀 Якщо це лікар - можна редагувати. Якщо пацієнт - тільки читати.
              readOnly: !widget.isDoctor,
              decoration: InputDecoration(
                hintText: widget.isDoctor
                    ? 'Enter diagnosis, prescription or notes here...'
                    : 'No results added yet.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: widget.isDoctor ? Colors.white : Colors.grey[100],
              ),
            ),

            const SizedBox(height: 20),

            // --- КНОПКА ЗБЕРЕЖЕННЯ (Тільки для лікаря) ---
            if (widget.isDoctor)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveResults,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save Results'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}