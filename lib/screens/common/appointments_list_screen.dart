import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppointmentsListScreen extends StatefulWidget {
  final bool isDoctor; // Головний перемикач: true = Лікар, false = Пацієнт

  const AppointmentsListScreen({super.key, required this.isDoctor});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<DocumentSnapshot> _appointments = [];
  bool _isLoading = false;
  bool _hasMore = true; // Чи є ще записи на сервері
  final int _documentLimit = 10; // Скільки вантажити за раз
  DocumentSnapshot? _lastDocument; // Курсор для пагінації

  @override
  void initState() {
    super.initState();
    _getAppointments();
  }

  // --- ЛОГІКА ЗАВАНТАЖЕННЯ ДАНИХ ---
  Future<void> _getAppointments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final userId = _auth.currentUser!.uid;

    try {
      // Визначаємо, по якому полю шукати
      // Якщо я лікар -> шукаю свої записи по doctorId
      // Якщо я пацієнт -> шукаю свої записи по patientId
      final String searchField = widget.isDoctor ? 'doctorId' : 'patientId';

      Query query = _firestore
          .collection('appointments')
          .where(searchField, isEqualTo: userId)
          .orderBy('date', descending: true) // Спочатку нові
          .limit(_documentLimit);

      // Якщо це дозавантаження (сторінка 2, 3...), починаємо після останнього
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      // Якщо прийшло менше ліміту, значить це кінець списку
      if (querySnapshot.docs.length < _documentLimit) {
        _hasMore = false;
      }

      // Додаємо нові записи до списку
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _appointments.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint("Error loading appointments: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- UI ЕЛЕМЕНТ ОДНОГО ЗАПИСУ ---
  Widget _buildAppointmentItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final date = data['date'] ?? 'Unknown Date';
    final time = data['slot'] ?? '--:--';
    final status = data['status'] ?? 'pending';

    // АДАПТИВНИЙ ЗАГОЛОВОК:
    // Лікарю показуємо ім'я пацієнта. Пацієнту - ім'я лікаря.
    final String titleName = widget.isDoctor
        ? (data['patientName'] ?? 'Patient')
        : (data['doctorName'] ?? 'Doctor');

    // Налаштування кольорів статусу
    Color statusColor = Colors.orange;
    IconData statusIcon = Icons.access_time;

    if (status == 'confirmed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    } else if (status == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel_outlined;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(titleName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('$date at $time'),
              ],
            ),
            const SizedBox(height: 6),
            // Бейдж зі статусом
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.isDoctor ? 'My Patients Schedule' : 'My Visits History'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: _appointments.isEmpty && !_isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_month_outlined, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  Text(
                    widget.isDoctor ? "No appointments found" : "No visit history",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.builder(
              // +1 додає місце для кнопки "Load More" внизу
              itemCount: _appointments.length + 1,
              itemBuilder: (context, index) {
                if (index == _appointments.length) {
                  return _buildLoadMoreButton();
                }
                return _buildAppointmentItem(_appointments[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    // Якщо більше немає даних
    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("End of list", style: TextStyle(color: Colors.grey))),
      );
    }

    // Якщо йде завантаження
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Кнопка "Завантажити ще"
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: OutlinedButton(
        onPressed: _getAppointments,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: const Text("Load More"),
      ),
    );
  }
}