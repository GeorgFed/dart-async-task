import 'package:http/http.dart' as http;

import 'network.dart';

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
