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

CoinRepository createRepository(http.Client client) => throw UnimplementedError(
  'Создайте реализацию CoinRepository и верните её здесь',
);

Future<void> main() async {
  final repository = createRepository(http.Client());
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
