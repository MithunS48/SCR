import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';

class EventModel {
  final int id;
  final String title;
  final String? description;
  final String locationName;
  final double latitude;
  final double longitude;
  final String eventDatetime;
  final String status;
  final int participantCount;
  final bool registeredByCurrentUser;
  final String organizerDisplayName;

  EventModel({
    required this.id, required this.title, this.description,
    required this.locationName, required this.latitude, required this.longitude,
    required this.eventDatetime, required this.status,
    required this.participantCount, required this.registeredByCurrentUser,
    required this.organizerDisplayName,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) => EventModel(
        id: j['id'],
        title: j['title'],
        description: j['description'],
        locationName: j['locationName'],
        latitude: double.parse(j['latitude'].toString()),
        longitude: double.parse(j['longitude'].toString()),
        eventDatetime: j['eventDatetime'],
        status: j['status'],
        participantCount: j['participantCount'],
        registeredByCurrentUser: j['registeredByCurrentUser'] ?? false,
        organizerDisplayName: j['organizerDisplayName'] ?? '',
      );
}

class EventProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<EventModel> _events = [];
  bool _loading = false;
  String? _error;

  List<EventModel> get events => _events;
  bool get isLoading  => _loading;
  String? get error   => _error;

  Future<void> loadEvents({int page = 0}) async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.events,
          queryParameters: {'page': page, 'size': 20});
      final content = res.data['data']['content'] as List;
      _events = content.map((e) => EventModel.fromJson(e)).toList();
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to load events';
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> createEvent(Map<String, dynamic> data) async {
    _loading = true; notifyListeners();
    try {
      await _api.dio.post(ApiConstants.events, data: data);
      await loadEvents();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to create event';
      notifyListeners();
      return false;
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<bool> register(int eventId) async {
    try {
      await _api.dio.post('${ApiConstants.events}/$eventId/register');
      await loadEvents();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to register';
      notifyListeners();
      return false;
    }
  }

  Future<bool> cancelRegistration(int eventId) async {
    try {
      await _api.dio.delete('${ApiConstants.events}/$eventId/register');
      await loadEvents();
      return true;
    } on DioException catch (e) {
      _error = e.response?.data?['message'] ?? 'Failed to cancel';
      notifyListeners();
      return false;
    }
  }

  void clearError() { _error = null; notifyListeners(); }
}
