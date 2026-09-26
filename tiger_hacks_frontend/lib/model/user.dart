enum UserRole { individual, caretaker }

class User {
  const User({required this.username, required this.id, required this.role});

  final String username;
  final int id;
  final UserRole role;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: UserRole.values.byName(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'role': role.name,
  };
}
