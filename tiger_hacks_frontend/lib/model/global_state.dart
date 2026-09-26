import 'package:flutter/foundation.dart';
import 'package:tiger_hacks_frontend/model/user.dart';

class GlobalState extends ChangeNotifier {
  User? _user;
  User? get user => _user;

  set user(User? user) {
    _user = user;
    notifyListeners();
  }
}
