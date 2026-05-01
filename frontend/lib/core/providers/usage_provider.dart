import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';

class UsageEntry {
  final int id;
  final String entryDate;
  final String itemCategory;
  final int quantity;

  UsageEntry({required this.id, required this.entryDate,
              required this.itemCategory, required this.quantity});

  factory UsageEntry.fromJson(Map<String, dynamic> j) => UsageEntry(
        id: j['id'],
        entryDate: j['entryDate'],
        itemCategory: j['itemCategory'],
        quantity: j['quantity'],
      );
}

class UsageProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<UsageEntry> _history = [];
  Map<String, dynamic>? _dailyStats;
  Map<String, dynamic>? _weeklyStats;
  Map<String, dynamic>? _monthlyStats;
  double? _reductionPct;
  String? _reductionMsg;
  bool _loading = false;
  String? _error;

  List<UsageEntry> get history     => _history;
  Map<String, dynamic>? get dailyStats   => _dailyStats;
  Map<String, dynamic>? get weeklyStats  => _weeklyStats;
  Map<String, dynamic>? get monthlyStats => _monthlyStats;
  double? get reductionPct  => _reductionPct;
  String? get reductionMsg  => _reductionMsg;
  bool get isLoading        => _loading;
  String? get error         => _error;

  Future<bool> logUsage(String category, int quantity) async {
    _loading = true; notifyListeners();
    try {
      await _api.dio.post(ApiConstants.usage,
          data: {'itemCategory': category, 'quantity': quantity});
      await loadHistory();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to log usage';
      notifyListeners();
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadHistory({int page = 0}) async {
    try {
      final res = await _api.dio.get(ApiConstants.usageHistory,
          queryParameters: {'page': page, 'size': 20});
      final content = res.data['data']['content'] as List;
      _history = content.map((e) => UsageEntry.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadDailyStats(String date) async {
    try {
      final res = await _api.dio.get(ApiConstants.usageDaily,
          queryParameters: {'date': date});
      _dailyStats = res.data['data'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadWeeklyStats(int year, int week) async {
    try {
      final res = await _api.dio.get(ApiConstants.usageWeekly,
          queryParameters: {'year': year, 'week': week});
      _weeklyStats = res.data['data'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadMonthlyStats(int year, int month) async {
    try {
      final res = await _api.dio.get(ApiConstants.usageMonthly,
          queryParameters: {'year': year, 'month': month});
      _monthlyStats = res.data['data'];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadReduction(String period, String ref) async {
    try {
      final res = await _api.dio.get(ApiConstants.usageReduction,
          queryParameters: {'period': period, 'ref': ref});
      final data = res.data['data'];
      _reductionPct = data['reductionPercentage']?.toDouble();
      _reductionMsg = data['reductionMessage'];
      notifyListeners();
    } catch (_) {}
  }

  void clearError() { _error = null; notifyListeners(); }
}
