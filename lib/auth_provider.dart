import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;

  User? get user => _user;

  AuthProvider() {
    _authService.user.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    try {
      User? user = await _authService.signInWithGoogle();
      return user != null;
    } catch (e) {
      print('Error in provider: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}