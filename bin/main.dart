import 'dart:io';

import 'package:dart_async_task/coin_api.dart';
import 'package:dart_async_task/demo_client.dart';
import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final live = args.contains('--live');
  final CoinRepository repository = HttpCoinRepository(
    client: live ? http.Client() : createDemoClient(),
    apiKey: Platform.environment['COINGECKO_DEMO_API_KEY'],
  );
  print(live ? 'CoinGecko API' : 'Учебные данные, без API');
  try {
    await showTopCoins(repository);
    await showCoinDetails(repository);
    await showCoinsStream(repository);
    await showPolling(
      repository,
      live ? const Duration(seconds: 30) : const Duration(milliseconds: 100),
    );
    await showGrowingCoins(repository);
  } catch (error) {
    stderr.writeln('Ошибка: $error');
    exitCode = 1;
  } finally {
    repository.close();
  }
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
