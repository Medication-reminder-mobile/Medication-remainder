import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthService? authService,
    SessionService? sessionService,
  })  : _auth = authService ?? AuthService(),
        _session = sessionService ?? SessionService();

  final AuthService _auth;
  final SessionService _session;

  UserModel? currentUser;
  bool isLoading = false;
  String? errorMessage;

  void setUser(UserModel? user) {
    currentUser = user;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      currentUser = await _session.getSession();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _auth.login(
        email,
        password,
        rememberMe: rememberMe,
      );
      if (user == null) {
        errorMessage = 'Invalid email or password';
      } else {
        currentUser = user;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String password, String role) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final user = await _auth.register(name, email, password, role);
      if (user == null) {
        errorMessage = 'Email already in use';
      } else {
        currentUser = user;
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _auth.logout();
      currentUser = null;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

