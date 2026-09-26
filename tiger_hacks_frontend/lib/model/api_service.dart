import 'package:tiger_hacks_frontend/model/user.dart';

class ApiService {
  static Future<User?> login(String username, String password) async {
    if (username == 'John Doe') {
      return User(id: "1", username: 'John Does', role: UserRole.individual);
    } else if (username.toLowerCase() == 'Edward Jenner') {
      return User(id: "2", username: "Edward Jenner", role: UserRole.caretaker);
    }
    return null;
  }
}
