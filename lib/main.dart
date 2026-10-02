import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Coin {
  // id, name и nullable priceUsd из current_price.
  const Coin({required this.id, required this.name, required this.priceUsd});

  final String id;
  final String name;
  final double? priceUsd;

  factory Coin.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('Coin.fromJson');
}

class CoinDetails {
  // name, description из description.en, nullable changePercent из market_data.
  const CoinDetails({
    required this.name,
    required this.description,
    required this.changePercent,
  });

  final String name;
  final String description;
  final double? changePercent;

  factory CoinDetails.fromJson(Map<String, dynamic> json) =>
      throw UnimplementedError('CoinDetails.fromJson');
}

abstract interface class CoinRepository {
  /// /coins/markets: USD, market_cap_desc, per_page=limit (1–250), page=1.
  Future<List<Coin>> getTopCoins(int limit);

  /// /coins/{id}?localization=false; описание по умолчанию пустое.
  Future<CoinDetails> getCoinDetails(String coinId);

  /// Детали последовательно в порядке id; первая ошибка завершает поток.
  Stream<CoinDetails> getCoinsStream(List<String> coinIds);

  /// /coins/markets с ids: сразу, затем interval после ответа; до отмены.
  Stream<List<Coin>> pollPrices(List<String> coinIds, Duration interval);

  /// Имена из getCoinsStream: только changePercent > 0; where + map.
  Stream<String> getGrowingCoinNames(List<String> coinIds);

  /// Закрыть переданный HTTP-клиент после завершения работы.
  void close();
}

class HttpCoinRepository implements CoinRepository {
  HttpCoinRepository({required http.Client client, String? apiKey})
    : _api = CoinGeckoClient(client: client, apiKey: apiKey);

  final CoinGeckoClient _api;

  @override
  Future<List<Coin>> getTopCoins(int limit) =>
      throw UnimplementedError('getTopCoins');

  @override
  Future<CoinDetails> getCoinDetails(String coinId) =>
      throw UnimplementedError('getCoinDetails');

  @override
  Stream<CoinDetails> getCoinsStream(List<String> coinIds) =>
      throw UnimplementedError('getCoinsStream');

  @override
  Stream<List<Coin>> pollPrices(List<String> coinIds, Duration interval) =>
      throw UnimplementedError('pollPrices');

  @override
  Stream<String> getGrowingCoinNames(List<String> coinIds) =>
      throw UnimplementedError('getGrowingCoinNames');

  @override
  void close() => throw UnimplementedError('close');
}

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

Future<void> main() async {
  final CoinRepository repository = HttpCoinRepository(
    client: http.Client(),
    apiKey: Platform.environment['COINGECKO_DEMO_API_KEY'],
  );
  try {
    await runDemo(repository);
  } catch (error) {
    stderr.writeln('Ошибка: $error');
    exitCode = 1;
  } finally {
    repository.close();
  }
}

Future<void> runDemo(
  CoinRepository repository, {
  Duration interval = const Duration(seconds: 30),
}) async {
  await showTopCoins(repository);
  await showCoinDetails(repository);
  await showCoinsStream(repository);
  await showPolling(repository, interval);
  await showGrowingCoins(repository);
}

Future<void> showTopCoins(CoinRepository repository) async {
  print('\nТоп монет:');
  for (final coin in await repository.getTopCoins(2)) {
    print('${coin.id}: ${coin.name} — ${coin.priceUsd ?? "нет цены"} USD');
  }
}

Future<void> showCoinDetails(CoinRepository repository) async {
  final coin = await repository.getCoinDetails('bitcoin');
  print('\n${coin.name}: ${coin.changePercent ?? "нет данных"}% за 24 часа');
  final description = coin.description;
  print(
    description.length <= 150
        ? description
        : '${description.substring(0, 150)}…',
  );
}

Future<void> showCoinsStream(CoinRepository repository) async {
  print('\nПоток деталей:');
  await for (final coin in repository.getCoinsStream(['ethereum', 'bitcoin'])) {
    print(coin.name);
  }
}

Future<void> showPolling(CoinRepository repository, Duration interval) async {
  print('\nДва обновления цен:');
  await for (final coins
      in repository.pollPrices(['bitcoin', 'ethereum'], interval).take(2)) {
    print(coins.map((coin) => '${coin.name}: ${coin.priceUsd} USD').join(', '));
  }
}

Future<void> showGrowingCoins(CoinRepository repository) async {
  print('\nМонеты с ростом цены:');
  await for (final name in repository.getGrowingCoinNames([
    'ethereum',
    'bitcoin',
  ])) {
    print(name);
  }
}
