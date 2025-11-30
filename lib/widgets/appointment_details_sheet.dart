import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsSheet extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> appointmentData;
  final bool isDoctor;

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
    _resultsController.text = widget.appointmentData['visitResults'] ?? '';
  }

  @override
  void dispose() {
    _resultsController.dispose();
    super.dispose();
  }

  // НОВЕ: Метод показу діалогу для лікаря (щоб ввести повідомлення)
  void _showActionDialog(String status) {
    final TextEditingController messageController = TextEditingController();
    final bool isConfirming = status == 'confirmed';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isConfirming ? 'Confirm Appointment' : 'Decline Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isConfirming
                ? 'You can add a note for the patient (optional):'
                : 'Please specify the reason for cancellation:'),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isConfirming ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Закриваємо діалог
              // Викликаємо оновлення статусу з повідомленням
              _updateStatus(status, messageController.text.trim());
            },
            child: Text(isConfirming ? 'Confirm' : 'Decline'),
          ),
        ],
      ),
    );
  }

  // ОНОВЛЕНО: Тепер приймає message
  Future<void> _updateStatus(String newStatus, String? message) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointmentId)
          .update({
        'status': newStatus,
        // Зберігаємо повідомлення лікаря (якщо воно є)
        'statusMessage': message,
      });

      if (mounted) {
        setState(() {
          widget.appointmentData['status'] = newStatus;
          if (message != null) widget.appointmentData['statusMessage'] = message;
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'confirmed' ? 'Appointment Confirmed!' : 'Appointment Declined'),
            backgroundColor: newStatus == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Results saved!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    final status = data['status'] ?? 'pending';
    final statusMessage = data['statusMessage']; // Повідомлення від лікаря

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
          bottom: MediaQuery.of(context).viewInsets.bottom + 20
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
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.isDoctor ? 'Patient Details' : 'Appointment Details',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),

            _buildInfoRow(Icons.person, widget.isDoctor ? 'Patient' : 'Doctor',
                widget.isDoctor ? (data['patientName'] ?? 'Unknown') : (data['doctorName'] ?? 'Unknown')),
            _buildInfoRow(Icons.calendar_today, 'Date', formattedDate),
            _buildInfoRow(Icons.access_time, 'Time', data['slot']),

            if (data['comment'] != null && data['comment'].toString().isNotEmpty)
              _buildInfoRow(Icons.comment, 'Complaint / Reason', data['comment']),

            const SizedBox(height: 20),

            // --- НОВЕ: СТАТУС ДЛЯ ПАЦІЄНТА ---
            if (!widget.isDoctor) ...[
              if (status == 'pending')
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty, color: Colors.orange),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Thank you for booking! Please wait for the doctor to confirm.',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

              if (status != 'pending')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status == 'confirmed' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: status == 'confirmed' ? Colors.green : Colors.red),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            status == 'confirmed' ? Icons.check_circle : Icons.cancel,
                            color: status == 'confirmed' ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status == 'confirmed' ? 'Appointment Confirmed' : 'Appointment Declined',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'confirmed' ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      // Показуємо повідомлення від лікаря, якщо воно є
                      if (statusMessage != null && statusMessage.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Doctor\'s note: $statusMessage',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ]
                    ],
                  ),
                ),
            ],

            const SizedBox(height: 10),

            // --- БЛОК ДІЙ ЛІКАРЯ (ОНОВЛЕНО) ---
            if (widget.isDoctor) ...[
              const Text(
                'Action Required',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),

              if (status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        // Викликаємо діалог замість миттєвої дії
                        onPressed: _isSaving ? null : () => _showActionDialog('cancelled'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        // Викликаємо діалог замість миттєвої дії
                        onPressed: _isSaving ? null : () => _showActionDialog('confirmed'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Confirm'),
                      ),
                    ),
                  ],
                )
              else
              // Відображення статусу для лікаря (історія)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: status == 'confirmed'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: status == 'confirmed' ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            status == 'confirmed' ? Icons.check_circle : Icons.cancel,
                            color: status == 'confirmed' ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status == 'confirmed' ? 'Confirmed' : 'Cancelled',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: status == 'confirmed' ? Colors.green : Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (statusMessage != null && statusMessage.toString().isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text('Note: $statusMessage', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ]
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
            ],

            // --- БЛОК РЕЗУЛЬТАТІВ ---
            Text(
              'Visit Results',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _resultsController,
              maxLines: 5,
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