import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String _activeRole = 'kasir'; // Default to cashier
  bool _isLoggedIn = false;
  String _adminPin = '1234'; // Default Admin PIN

  String get activeRole => _activeRole;
  bool get isLoggedIn => _isLoggedIn;
  bool get isAdmin => _activeRole == 'admin' && _isLoggedIn;
  bool get isCashier => _activeRole == 'kasir';

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _adminPin = prefs.getString('admin_pin') ?? '1234';
    _activeRole = prefs.getString('active_role') ?? 'kasir';
    _isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    notifyListeners();
  }

  Future<bool> loginAsAdmin(String pin) async {
    if (pin == _adminPin) {
      _activeRole = 'admin';
      _isLoggedIn = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_role', 'admin');
      await prefs.setBool('is_logged_in', true);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> loginAsCashier() async {
    _activeRole = 'kasir';
    _isLoggedIn = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_role', 'kasir');
    await prefs.setBool('is_logged_in', true);
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _activeRole = 'kasir';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.setString('active_role', 'kasir');
    notifyListeners();
  }

  Future<bool> changeAdminPin(String oldPin, String newPin) async {
    if (oldPin == _adminPin && newPin.length == 4) {
      _adminPin = newPin;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_pin', newPin);
      notifyListeners();
      return true;
    }
    return false;
  }
}
