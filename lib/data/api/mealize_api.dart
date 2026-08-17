import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config.dart';

/// Клієнт до Laravel BFF (silpo-mcp-project/api). Дзеркалить його роути.
/// App → BFF → Silpo MCP. Токени Сільпо живуть server-side.
class MealizeApi {
  MealizeApi({http.Client? client, String? baseUrl})
      : _http = client ?? http.Client(),
        _base = baseUrl ?? AppConfig.apiBaseUrl;

  /// Єдиний екземпляр на застосунок (FL-4: один http.Client, без витоку).
  static final MealizeApi instance = MealizeApi();

  final http.Client _http;
  final String _base;

  static const _headers = {'Accept': 'application/json', 'Content-Type': 'application/json'};
  static const _timeout = Duration(seconds: 20); // FL-1: не висіти вічно

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_base/api$path').replace(queryParameters: query);

  Future<http.Response> _get(String path, [Map<String, String>? query]) =>
      _http.get(_uri(path, query), headers: _headers).timeout(_timeout);

  Future<http.Response> _post(String path, [Object? body]) => _http
      .post(_uri(path), headers: _headers, body: body != null ? jsonEncode(body) : null)
      .timeout(_timeout);

  /// GET /api/me — профіль + статус підключення Сільпо.
  Future<Map<String, dynamic>> me() async => _decode(await _get('/me'));

  /// GET /api/home — акції + патерн дня тижня.
  Future<Map<String, dynamic>> home({String? branchId}) async =>
      _decode(await _get('/home', branchId != null ? {'branch_id': branchId} : null));

  /// GET /api/branches — філії Сільпо.
  Future<List<dynamic>> branches() async {
    final json = _decode(await _get('/branches'));
    return (json['data'] as List<dynamic>?) ?? const [];
  }

  /// POST /api/meal-plans — старт генерації (202 + id).
  Future<Map<String, dynamic>> createMealPlan(Map<String, dynamic> body) async =>
      _decode(await _post('/meal-plans', body));

  /// GET /api/meal-plans/{id} — статус + меню + кошик.
  Future<Map<String, dynamic>> mealPlan(int id) async => _decode(await _get('/meal-plans/$id'));

  /// POST /api/meal-plans/{id}/items/{item}/swap.
  Future<Map<String, dynamic>> swap(int planId, int itemId, String sku) async =>
      _decode(await _post('/meal-plans/$planId/items/$itemId/swap', {'sku': sku}));

  /// POST /api/meal-plans/{id}/checkout — checkout-лінк Сільпо.
  Future<Map<String, dynamic>> checkout(int planId) async =>
      _decode(await _post('/meal-plans/$planId/checkout'));

  /// GET /api/analytics — агрегати для сторінки «Аналітика».
  Future<Map<String, dynamic>> analytics() async {
    final json = _decode(await _get('/analytics'));
    return (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// POST /api/food-logs — записати з'їдену порцію (подія щоденника).
  Future<void> logFood({
    required String title, required int kcal,
    int grams = 0, int protein = 0, int fat = 0, int carbs = 0,
  }) async {
    await _post('/food-logs', {
      'title': title, 'kcal': kcal, 'grams': grams,
      'protein': protein, 'fat': fat, 'carbs': carbs,
    });
  }

  /// POST /api/purchases — записати подію покупки (замовлення + позиції).
  Future<void> recordPurchase({
    required int total, required List<Map<String, dynamic>> items,
    int saved = 0, String store = 'Сільпо', int? mealPlanId,
  }) async {
    await _post('/purchases', {
      'store': store, 'total': total, 'saved': saved,
      'meal_plan_id': ?mealPlanId,
      'items': items,
    });
  }

  /// POST /api/assistant — повідомлення до Зоряни (Claude) → текстова відповідь.
  Future<String> assistant(String message) async {
    final json = _decode(await _post('/assistant', {'message': message}));
    return (json['reply'] ?? '').toString();
  }

  /// Згенерувати меню і дочекатися ready|failed (полінг).
  /// Генерація (агент + матчинг) триває ~30-60с → чекаємо до ~90с.
  Future<Map<String, dynamic>> generateAndWait(Map<String, dynamic> body, {int tries = 45}) async {
    final created = await createMealPlan(body);
    final id = (created['data']?['id']) as int?;
    if (id == null) return created;

    for (var i = 0; i < tries; i++) {
      final plan = await mealPlan(id);
      final status = plan['data']?['status'];
      if (status == 'ready' || status == 'failed') return plan;
      await Future<void>.delayed(const Duration(milliseconds: 1500));
    }
    return mealPlan(id);
  }

  /// Швидка перевірка звʼязку з BFF.
  Future<bool> ping() async {
    try {
      await me();
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> _decode(http.Response r) {
    final dynamic body = r.body.isNotEmpty ? jsonDecode(r.body) : <String, dynamic>{};
    if (r.statusCode >= 400) {
      final msg = body is Map && body['message'] != null ? body['message'].toString() : 'HTTP ${r.statusCode}';
      throw ApiException(r.statusCode, msg);
    }
    return body is Map<String, dynamic> ? body : <String, dynamic>{'data': body};
  }
}

class ApiException implements Exception {
  ApiException(this.status, this.message);
  final int status;
  final String message;
  @override
  String toString() => message;
}
