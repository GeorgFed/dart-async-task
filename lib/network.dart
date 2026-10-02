import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class CoinApiException implements Exception {
  const CoinApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CoinGeckoClient {
  CoinGeckoClient({required http.Client client, String? apiKey})
    : _client = client,
      _apiKey = apiKey;

  final http.Client _client;
  final String? _apiKey;

  Future<Object?> get(String path, Map<String, String> query) async {
    final uri = Uri.https('api.coingecko.com', '/api/v3/$path', query);
    final key = _apiKey;
    try {
      final response = await _client
          .get(
            uri,
            headers: {
              if (key != null && key.isNotEmpty) 'x-cg-demo-api-key': key,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw CoinApiException('HTTP ${response.statusCode}');
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const CoinApiException('API не ответил за 15 секунд');
    } on http.ClientException {
      throw const CoinApiException('Ошибка подключения к API');
    } on FormatException {
      throw const CoinApiException('Повреждённый JSON');
    }
  }

  void close() => _client.close();
}
