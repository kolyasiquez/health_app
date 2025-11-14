// lib/services/api_service.dart

import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🚀 ВИЗНАЧАЄМО РОЛІ КОРИСТУВАЧІВ
enum UserRole { patient, doctor, admin }

class ApiService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 헬 Допоміжний метод для отримання шляху до колекції на основі ролі
  String _getCollectionForRole(UserRole role) {
    switch (role) {
      case UserRole.patient:
        return 'patients';
      case UserRole.doctor:
        return 'doctors';
      case UserRole.admin:
        return 'admins';
    }
  }

  // 헬 Допоміжний метод для отримання шляху до колекції з текстової назви ролі
  String _getCollectionForRoleString(String role) {
    switch (role) {
      case 'patient':
        return 'patients';
      case 'doctor':
      case 'pending_doctor': // 🚀 ОБИДВІ РОЛІ ЖИВУТЬ В КОЛЕКЦІЇ 'doctors'
        return 'doctors';
      case 'admin':
        return 'admins';
      default:
        throw Exception('Невідома роль: $role');
    }
  }

  // 🚀 ОБМЕЖЕННЯ ДЛЯ АДМІНІВ
  Future<void> checkAdminLimit() async {
    final adminQuery = await _firestore.collection('admins').limit(2).get();
    if (adminQuery.docs.length >= 2) {
      throw Exception("Ліміт адміністраторів (2) вже досягнуто.");
    }
  }

  // 🚀 ОНОВЛЕНО: Тепер приймає 'bio' (для лікарів) одразу
  Future<void> createUserDocument(String uid, String email, String name, UserRole role, {String? bio}) async {
    const String defaultAvatarPath = 'assets/images/default_person.png';
    final String collectionPath = _getCollectionForRole(role);

    // 🚀 Визначаємо роль для запису в БД
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
      'createdAt': FieldValue.serverTimestamp(),
      'avatarUrl': defaultAvatarPath,
      'age': null,
      'role': documentRole, // 🚀 ЗБЕРІГАЄМО НОВУ РОЛЬ
      'bio': (role == UserRole.doctor) ? bio : null, // 🚀 ЗБЕРІГАЄМО БІО ОДРАЗУ
      'licenseUrl': null, // (Ми більше не використовуємо це, але лишаємо для структури)
    };

    // Використовуємо пакетний запис (batch) для атомарності
    final batch = _firestore.batch();

    // 1. Створюємо профіль користувача у відповідній колекції
    final userDocRef = _firestore.collection(collectionPath).doc(uid);
    batch.set(userDocRef, userData);

    // 2. Створюємо "довідковий" запис про роль
    final roleDocRef = _firestore.collection('user_roles').doc(uid);
    batch.set(roleDocRef, {'role': documentRole});

    await batch.commit();
  }

  // 🚀 ОНОВЛЕНИЙ МЕТОД ОТРИМАННЯ ДАНИХ
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Отримуємо роль користувача з довідкової колекції
      final roleDoc = await _firestore.collection('user_roles').doc(user.uid).get();
      if (!roleDoc.exists) {
        log('Помилка: Не знайдено документ ролі для користувача ${user.uid}');
        return null;
      }

      final role = roleDoc.data()?['role'] as String?;
      if (role == null) {
        log('Помилка: Документ ролі порожній для користувача ${user.uid}');
        return null;
      }

      // 2. Отримуємо дані профілю з відповідної колекції
      final collectionPath = _getCollectionForRoleString(role);
      final doc = await _firestore.collection(collectionPath).doc(user.uid).get();
      return doc.data();

    } catch (e) {
      log('Помилка під час отримання даних користувача: $e');
      return null;
    }
  }

  // 🚀 ОНОВЛЕНИЙ МЕТОД ОНОВЛЕННЯ ПРОФІЛЮ
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Користувач не ввійшов у систему.");
    }
    if (data.isEmpty) return;

    try {
      // 1. Отримуємо роль користувача
      final roleDoc = await _firestore.collection('user_roles').doc(user.uid).get();
      if (!roleDoc.exists) {
        throw Exception('Помилка: Не знайдено документ ролі.');
      }
      final role = roleDoc.data()?['role'] as String?;
      if (role == null) {
        throw Exception('Помилка: Документ ролі порожній.');
      }

      // 2. Оновлюємо документ у відповідній колекції
      final collectionPath = _getCollectionForRoleString(role);
      await _firestore.collection(collectionPath).doc(user.uid).update(data);

    } catch (e) {
      log('Помилка під час оновлення профілю: $e');
      throw Exception('Не вдалося оновити профіль: $e');
    }
  }

  // --- МЕТОДИ ДЛЯ АДМІНА ---

  // Метод для Адміна: Отримати список лікарів на верифікацію
  Future<QuerySnapshot> getPendingDoctors() {
    return _firestore
        .collection('doctors')
        .where('role', isEqualTo: 'pending_doctor')
        .get();
  }

  Future<QuerySnapshot> getDoctorsList() {
    return _firestore
        .collection('doctors')
        .where('role', isEqualTo: 'doctor')
        .get();
  }

  // Метод для Адміна: Схвалити лікаря
  Future<void> approveDoctor(String uid) async {
    final batch = _firestore.batch();
    final docRef = _firestore.collection('doctors').doc(uid);
    batch.update(docRef, {'role': 'doctor'});
    final roleRef = _firestore.collection('user_roles').doc(uid);
    batch.update(roleRef, {'role': 'doctor'});
    await batch.commit();
  }

  // 🚀🚀🚀 ПОВЕРТАЄМО МЕТОД denyDoctor З ВИДАЛЕННЯМ ДАНИХ 🚀🚀🚀
  // Метод для Адміна: Відхилити лікаря (видаляє тільки з БД)
  Future<void> denyDoctor(String uid) async {
    // ⚠️ ВАЖЛИВО: Цей метод не видаляє акаунт з Firebase Auth.

    final batch = _firestore.batch();

    // Видаляємо профіль з колекції 'doctors'
    final docRef = _firestore.collection('doctors').doc(uid);
    batch.delete(docRef);

    // Видаляємо запис про роль з 'user_roles'
    final roleRef = _firestore.collection('user_roles').doc(uid);
    batch.delete(roleRef);

    await batch.commit();
    log("Firestore data deleted for user $uid. Remember to delete from Authentication manually.");
  }
// 🚀🚀🚀 КІНЕЦЬ ПОВЕРНЕНОГО МЕТОДУ 🚀🚀🚀

}