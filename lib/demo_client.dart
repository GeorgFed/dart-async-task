import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Client createDemoClient() => MockClient((request) async {
  await Future<void>.delayed(const Duration(milliseconds: 20));
  final coins = [
    {'id': 'bitcoin', 'name': 'Bitcoin', 'current_price': 65000},
    {'id': 'ethereum', 'name': 'Ethereum', 'current_price': 3200},
  ];
  if (request.url.path.endsWith('/coins/markets')) {
    final ids = request.url.queryParameters['ids']?.split(',');
    final limit = int.parse(request.url.queryParameters['per_page'] ?? '250');
    final selected = coins.where(
      (coin) => ids == null || ids.contains(coin['id']),
    );
    return http.Response(jsonEncode(selected.take(limit).toList()), 200);
  }
  final id = request.url.pathSegments.last;
  final selected = coins.where((coin) => coin['id'] == id);
  if (selected.isEmpty) return http.Response('{"error":"not found"}', 404);
  return http.Response(
    jsonEncode({
      'name': selected.first['name'],
      'description': {'en': 'Учебное описание монеты.'},
      'market_data': {
        'price_change_percentage_24h': id == 'bitcoin' ? 2.5 : -1.0,
      },
    }),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
});
