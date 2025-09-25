class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? avatarUrl; // Додаємо поле для URL аватарки

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
  });

  // Метод для створення об'єкта з Firebase
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      name: data['name'],
      role: data['role'],
      avatarUrl: data['avatarUrl'],
    );
  }

  // Метод для перетворення в Map для Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
    };
  }
}