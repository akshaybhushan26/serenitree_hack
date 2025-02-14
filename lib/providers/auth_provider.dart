import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;

  void login(String email) {
    _isAuthenticated = true;
    _userEmail = email;
    notifyListeners();
  }

  void logout() {
    _isAuthenticated = false;
    _userEmail = null;
    notifyListeners();
  }
}
