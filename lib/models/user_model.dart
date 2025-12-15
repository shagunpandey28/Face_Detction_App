class UserModel {
  final String id;
  final String name;
  final String email;

  UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> j) {
    return UserModel(
      id: j['id']?.toString() ?? '',
      name: j['name'] ?? '',
      email: j['email'] ?? '',
    );
  }
}
