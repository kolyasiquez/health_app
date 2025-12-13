import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 👇 1. Імпортуємо твій файл з деталями (перевір шлях!)
import 'package:health_app/widgets/appointment_details_sheet.dart';

class AppointmentsListScreen extends StatefulWidget {
  final bool isDoctor;

  const AppointmentsListScreen({super.key, required this.isDoctor});

  @override
  State<AppointmentsListScreen> createState() => _AppointmentsListScreenState();
}

class _AppointmentsListScreenState extends State<AppointmentsListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Змінив список на змінну, щоб можна було легко оновлювати
  List<DocumentSnapshot> _appointments = [];
  bool _isLoading = false;
  bool _hasMore = true;
  final int _documentLimit = 10;
  DocumentSnapshot? _lastDocument;

  @override
  void initState() {
    super.initState();
    _getAppointments();
  }

  // Функція для оновлення списку (наприклад, після скасування запису в шторці)
  Future<void> _refreshList() async {
    setState(() {
      _appointments = [];
      _lastDocument = null;
      _hasMore = true;
    });
    await _getAppointments();
  }

  Future<void> _getAppointments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final userId = _auth.currentUser!.uid;

    try {
      final String searchField = widget.isDoctor ? 'doctorId' : 'patientId';

      Query query = _firestore
          .collection('appointments')
          .where(searchField, isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(_documentLimit);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.length < _documentLimit) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _appointments.addAll(querySnapshot.docs);
      }
    } catch (e) {
      debugPrint("Error loading appointments: $e");
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // --- ВІДЖЕТ ОДНОГО ЗАПИСУ ---
  Widget _buildAppointmentItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final date = data['date'] ?? 'Unknown Date';
    final time = data['slot'] ?? '--:--';
    final status = data['status'] ?? 'pending';

    final String titleName = widget.isDoctor
        ? (data['patientName'] ?? 'Patient')
        : (data['doctorName'] ?? 'Doctor');

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
      child: InkWell( // 👇 Додали InkWell для клікабельності
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          // 👇 2. ВІДКРИВАЄМО ТВОЮ ШТОРКУ ТУТ
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true, // Щоб шторка могла підніматися на весь екран
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (context) => AppointmentDetailsSheet(
              appointmentId: doc.id,     // Передаємо ID документа
              appointmentData: data,     // Передаємо дані
              isDoctor: widget.isDoctor, // Передаємо роль
            ),
          );

          // Коли шторка закриється, оновлюємо список (щоб побачити новий статус)
          _refreshList();
        },
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
          trailing: const Icon(Icons.chevron_right, color: Colors.grey), // Стрілочка
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
      body: RefreshIndicator( // 👇 Додав можливість потягнути вниз, щоб оновити
        onRefresh: _refreshList,
        child: Column(
          children: [
            Expanded(
              child: _appointments.isEmpty && !_isLoading
                  ? Center(
                child: SingleChildScrollView( // Щоб працював RefreshIndicator на пустому екрані
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      Icon(Icons.calendar_month_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      Text(
                        widget.isDoctor ? "No appointments found" : "No visit history",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(), // Важливо для RefreshIndicator
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
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    if (!_hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("End of list", style: TextStyle(color: Colors.grey))),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

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