import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  String? _token;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> tryAutoLogin() async {
    final token = await StorageService.getToken();
    if (token == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final user = await AuthService.getPerfil(token);
      _token = token;
      _user = user;
      _status = AuthStatus.authenticated;
    } catch (_) {
      await StorageService.clear();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final data = await AuthService.login(email: email, password: password);
    _token = data['token'] as String;
    final userData = data['utilizador'] as Map<String, dynamic>? ?? {};
    _user = UserModel.fromJson(userData);
    await StorageService.saveToken(_token!);
    await StorageService.saveUserInfo(_user!.id, _user!.nome);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> registar(String nome, String email, String password) async {
    final data = await AuthService.registar(nome: nome, email: email, password: password);
    _token = data['token'] as String;
    final userData = data['utilizador'] as Map<String, dynamic>? ?? {};
    _user = UserModel.fromJson(userData);
    await StorageService.saveToken(_token!);
    await StorageService.saveUserInfo(_user!.id, _user!.nome);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await StorageService.clear();
    _token = null;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
