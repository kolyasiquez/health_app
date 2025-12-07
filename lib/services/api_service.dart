import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole { patient, doctor, admin }

class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.patient: return 'patients';
      case UserRole.doctor: return 'doctors';
      case UserRole.admin: return 'admins';
    }
  }

  String _getCollectionForRoleString(String role) {
    switch (role) {
      case 'patient': return 'patients';
      case 'doctor':
      case 'pending_doctor': return 'doctors';
      case 'admin': return 'admins';
      default: throw Exception('Невідома роль: $role');
    }
  }

  Future<void> checkAdminLimit() async {
    final adminQuery = await _firestore.collection('admins').limit(2).get();
    if (adminQuery.docs.length >= 2) {
      throw Exception("Ліміт адміністраторів (2) вже досягнуто.");
    }
  }

  Future<void> createUserDocument(
      String uid,
      String email,
      String name,
      String phoneNumber,
      UserRole role, {
        String? bio,
        String? specialization,
        String? address, // 🚀 ОНОВЛЕНО: Нове поле адреси
      }) async {

    String defaultAvatarPath;
    if (role == UserRole.doctor) {
      defaultAvatarPath = 'assets/doctor_avatars/default_doctor.png';
    } else {
      defaultAvatarPath = 'assets/avatars/default_person.png';
    }

    final String collectionPath = _getCollectionForRole(role);

    String documentRole;
    if (role == UserRole.doctor) {
      documentRole = 'pending_doctor';
    } else if (role == UserRole.patient) {
      documentRole = 'patient';
    } else {
      documentRole = 'admin';
    }

    final userData = {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
      'avatarUrl': defaultAvatarPath,
      'age': null,
      'role': documentRole,
      // 🚀 Дані, специфічні для лікаря:
      'bio': (role == UserRole.doctor) ? bio : null,
      'specialization': (role == UserRole.doctor) ? specialization : null,
      'address': (role == UserRole.doctor) ? address : null, // 👈 Зберігаємо адресу
      'licenseUrl': null,
    };

    final batch = _firestore.batch();

    final userDocRef = _firestore.collection(collectionPath).doc(uid);
    batch.set(userDocRef, userData);

    final roleDocRef = _firestore.collection('user_roles').doc(uid);
    batch.set(roleDocRef, {'role': documentRole});

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final roleDoc = await _firestore.collection('user_roles').doc(user.uid).get();
      if (!roleDoc.exists) return null;

      final role = roleDoc.data()?['role'] as String?;
      if (role == null) return null;

      final collectionPath = _getCollectionForRoleString(role);
      final doc = await _firestore.collection(collectionPath).doc(user.uid).get();
      return doc.data();
    } catch (e) {
      log('Помилка під час отримання даних: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in.");
    if (data.isEmpty) return;

    try {
      final roleDoc = await _firestore.collection('user_roles').doc(user.uid).get();
      final role = roleDoc.data()?['role'] as String?;
      if (role == null) throw Exception('Role not found.');

      final collectionPath = _getCollectionForRoleString(role);
      await _firestore.collection(collectionPath).doc(user.uid).update(data);
    } catch (e) {
      log('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }

  // --- МЕТОДИ АДМІНА ---
  Future<QuerySnapshot> getPendingDoctors() {
    return _firestore.collection('doctors').where('role', isEqualTo: 'pending_doctor').get();
  }

  Future<QuerySnapshot> getDoctorsList() {
    return _firestore.collection('doctors').where('role', isEqualTo: 'doctor').get();
  }

  Future<void> approveDoctor(String uid) async {
    final batch = _firestore.batch();
    final docRef = _firestore.collection('doctors').doc(uid);
    batch.update(docRef, {'role': 'doctor'});
    final roleRef = _firestore.collection('user_roles').doc(uid);
    batch.update(roleRef, {'role': 'doctor'});
    await batch.commit();
  }

  Future<void> denyDoctor(String uid) async {
    final batch = _firestore.batch();
    final docRef = _firestore.collection('doctors').doc(uid);
    batch.delete(docRef);
    final roleRef = _firestore.collection('user_roles').doc(uid);
    batch.delete(roleRef);
    await batch.commit();
    log("Firestore data deleted for user $uid");
  }
}