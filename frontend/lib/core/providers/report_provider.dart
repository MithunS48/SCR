import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';

class WasteReport {
  final int id;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final String? description;
  final String status;
  final String createdAt;

  WasteReport({required this.id, required this.imageUrl,
               required this.latitude, required this.longitude,
               this.description, required this.status, required this.createdAt});

  factory WasteReport.fromJson(Map<String, dynamic> j) => WasteReport(
        id: j['id'],
        imageUrl: j['imageUrl'],
        latitude: double.parse(j['latitude'].toString()),
        longitude: double.parse(j['longitude'].toString()),
        description: j['description'],
        status: j['status'],
        createdAt: j['createdAt'],
      );
}

class HeatmapPoint {
  final double lat;
  final double lng;
  final int weight;

  HeatmapPoint({required this.lat, required this.lng, required this.weight});

  factory HeatmapPoint.fromJson(Map<String, dynamic> j) => HeatmapPoint(
        lat: double.parse(j['latitude'].toString()),
        lng: double.parse(j['longitude'].toString()),
        weight: j['weight'],
      );
}

class ReportProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<WasteReport> _myReports = [];
  List<HeatmapPoint> _heatmapPoints = [];
  bool _loading = false;
  String? _error;

  List<WasteReport> get myReports     => _myReports;
  List<HeatmapPoint> get heatmapPoints => _heatmapPoints;
  bool get isLoading  => _loading;
  String? get error   => _error;

  Future<bool> submitReport({
    required String imagePath,
    required double latitude,
    required double longitude,
    String? description,
  }) async {
    _loading = true; notifyListeners();
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath),
        'latitude': latitude,
        'longitude': longitude,
        if (description != null) 'description': description,
      });
      await _api.dio.post(ApiConstants.reports, data: formData);
      await loadMyReports();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to submit report';
      notifyListeners();
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> loadMyReports({int page = 0}) async {
    try {
      final res = await _api.dio.get(ApiConstants.myReports,
          queryParameters: {'page': page, 'size': 20});
      final content = res.data['data']['content'] as List;
      _myReports = content.map((e) => WasteReport.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadHeatmap() async {
    try {
      final res = await _api.dio.get(ApiConstants.heatmap);
      final data = res.data['data'] as List;
      _heatmapPoints = data.map((e) => HeatmapPoint.fromJson(e)).toList();
      notifyListeners();
    } catch (_) {}
  }

  void clearError() { _error = null; notifyListeners(); }
}
