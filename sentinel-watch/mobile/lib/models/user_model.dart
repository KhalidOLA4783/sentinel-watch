class UserModel {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String role;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? 'admin',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'ADMIN',
    );
  }
}
