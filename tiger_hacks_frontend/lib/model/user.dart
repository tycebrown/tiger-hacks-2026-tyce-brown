enum UserRole { individual, caretaker }

class User {
  const User({required this.username, required this.id, required this.role});

  final String username;
  final String id;
  final UserRole role;
}
