class UserModel {
  final int id;
  final String email;
  final String displayName;
  final String role;
  final int points;

  const UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.points,
  });

  bool get isAdmin => role == 'ADMIN';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['userId'] ?? json['id'],
        email: json['email'],
        displayName: json['displayName'],
        role: json['role'],
        points: json['totalPoints'] ?? json['points'] ?? 0,
      );
}
