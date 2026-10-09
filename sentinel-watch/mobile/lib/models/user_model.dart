class UserModel {
  final int id;
  final String username;
  final String email;
  final String? fullName;
  final String role;
  final String? organization;
  final String? agentKey;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
    this.organization,
    this.agentKey,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? 'Utilisateur',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      role: json['role'] as String? ?? 'ADMIN',
      organization: json['organization'] as String?,
      agentKey: json['agent_key'] as String?,
    );
  }
}
