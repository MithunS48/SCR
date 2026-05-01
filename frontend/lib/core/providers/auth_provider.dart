import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';
import '../models/user_model.dart';

/// Manages authentication state — login, register, logout, token persistence.
class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  UserModel? _user;
  bool _loading = false;
  String? _error;

  UserModel? get user      => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading       => _loading;
  String? get error        => _error;
  bool get isAdmin         => _user?.isAdmin ?? false;

  /// Try to restore session from stored tokens on app start.
  Future<void> tryRestoreSession() async {
    final token = await _api.getAccessToken();
    if (token != null) {
      try {
        final res = await _api.dio.get(ApiConstants.profile);
        _user = UserModel.fromJson(res.data['data']);
        notifyListeners();
      } catch (_) {
        await _api.clearTokens();
      }
    }
  }

  Future<bool> register({
    required String email,
    required String displayName,
    required String password,
    String role = 'USER',
  }) async {
    _setLoading(true);
    try {
      final res = await _api.dio.post(ApiConstants.register, data: {
        'email': email,
        'displayName': displayName,
        'password': password,
        'role': role,
      });
      await _handleAuthResponse(res.data['data']);
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final res = await _api.dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      await _handleAuthResponse(res.data['data']);
      return true;
    } on DioException catch (e) {
      _error = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _api.clearTokens();
    _user = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _handleAuthResponse(Map<String, dynamic> data) async {
    await _api.saveTokens(data['accessToken'], data['refreshToken']);
    _user = UserModel.fromJson(data);
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  String _extractError(DioException e) {
    return e.response?.data?['message'] ?? 'An error occurred. Please try again.';
  }
}
