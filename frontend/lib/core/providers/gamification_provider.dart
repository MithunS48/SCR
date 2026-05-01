import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';

class BadgeModel {
  final int id;
  final String badgeName;
  final String awardedAt;

  BadgeModel({required this.id, required this.badgeName, required this.awardedAt});

  factory BadgeModel.fromJson(Map<String, dynamic> j) => BadgeModel(
        id: j['id'],
        badgeName: j['badgeName'],
        awardedAt: j['awardedAt'],
      );
}

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String displayName;
  final int totalPoints;
  final int badgeCount;

  LeaderboardEntry({required this.rank, required this.userId,
                    required this.displayName, required this.totalPoints,
                    required this.badgeCount});

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'],
        userId: j['userId'],
        displayName: j['displayName'],
        totalPoints: j['totalPoints'],
        badgeCount: j['badgeCount'],
      );
}

class GamificationProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  int _totalPoints = 0;
  int _rank = 0;
  List<BadgeModel> _badges = [];
  List<LeaderboardEntry> _leaderboard = [];
  bool _loading = false;

  int get totalPoints => _totalPoints;
  int get rank        => _rank;
  List<BadgeModel> get badges          => _badges;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  bool get isLoading  => _loading;

  Future<void> loadProfile() async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.profile);
      final data = res.data['data'];
      _totalPoints = data['totalPoints'];
      _rank = data['leaderboardRank'];
      _badges = (data['badges'] as List).map((e) => BadgeModel.fromJson(e)).toList();
    } catch (_) {
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadLeaderboard() async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.leaderboard);
      final data = res.data['data'] as List;
      _leaderboard = data.map((e) => LeaderboardEntry.fromJson(e)).toList();
    } catch (_) {
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
