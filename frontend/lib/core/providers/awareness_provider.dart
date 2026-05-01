import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../constants/api_constants.dart';

class AwarenessItem {
  final int id;
  final String title;
  final String body;
  final String contentType;
  final String? iconIdentifier;
  final String publishedAt;

  AwarenessItem({required this.id, required this.title, required this.body,
                 required this.contentType, this.iconIdentifier, required this.publishedAt});

  factory AwarenessItem.fromJson(Map<String, dynamic> j) => AwarenessItem(
        id: j['id'],
        title: j['title'],
        body: j['body'],
        contentType: j['contentType'],
        iconIdentifier: j['iconIdentifier'],
        publishedAt: j['publishedAt'],
      );
}

class AwarenessProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  List<AwarenessItem> _items = [];
  bool _loading = false;

  List<AwarenessItem> get items => _items;
  bool get isLoading => _loading;

  Future<void> loadItems({int page = 0}) async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.dio.get(ApiConstants.awareness,
          queryParameters: {'page': page, 'size': 20});
      final content = res.data['data']['content'] as List;
      _items = content.map((e) => AwarenessItem.fromJson(e)).toList();
    } catch (_) {
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
