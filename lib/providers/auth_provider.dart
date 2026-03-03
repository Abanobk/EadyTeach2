import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? address;
  final String? location;
  final String? avatarUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.address,
    this.location,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      phone: json['phone'],
      address: json['address'],
      location: json['location'],
      avatarUrl: json['avatarUrl'],
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isTechnician => role == 'technician';
  bool get isClient => role == 'user';
}

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;
  String? get error => _error;

  Future<void> checkAuth() async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await ApiService.query('auth.me');
      if (result['data'] != null) {
        _user = UserModel.fromJson(result['data']);
      } else {
        _user = null;
      }
    } catch (_) {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await ApiService.mutate('auth.logout');
    } catch (_) {}
    await ApiService.clearCookie();
    _user = null;
    notifyListeners();
  }

  void setUser(UserModel user) {
    _user = user;
    _isLoading = false;
    notifyListeners();
  }

  String getLoginUrl() {
    return '${ApiService.baseUrl}/api/oauth/login?returnTo=/';
  }
}
