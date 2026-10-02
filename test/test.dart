import 'dart:async';
import 'dart:convert';

import 'package:dart_async_task/main.dart' as app;
import 'package:dart_async_task/main.dart' hide main;
import 'package:fake_async/fake_async.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

http.Response response(
  String body,
  int status, {
  Map<String, String>? headers,
}) => http.Response(
  body,
  status,
  headers: {...?headers, 'content-type': 'application/json; charset=utf-8'},
);

const markets =
    '[{"id":"bitcoin","name":"Bitcoin","current_price":65000},{"id":"ethereum","name":"Ethereum","current_price":3200.5}]';

String details(String name, {double? change = 2.5}) => jsonEncode({
  'name': name,
  'description': {'en': 'Описание $name'},
  'market_data': {'price_change_percentage_24h': change},
});

class RecordingClient extends MockClient {
  RecordingClient(super.handler);
  bool closed = false;
  @override
  void close() {
    closed = true;
    super.close();
  }
}

CoinRepository repository(
  Future<http.Response> Function(http.Request) handler,
) => createRepository(MockClient(handler));

void main() {
  test('CLI без API: все пять демонстраций', () async {
    final output = <String>[];
    final api = createRepository(createDemoClient());
    try {
      await runZoned(
        () => app.runDemo(api, interval: const Duration(milliseconds: 1)),
        zoneSpecification: ZoneSpecification(
          print: (self, parent, zone, line) {
            output.add(line);
            parent.print(zone, line);
          },
        ),
      );
      final text = output.join('\n');
      for (final title in [
        'Топ монет:',
        'Bitcoin:',
        'Поток деталей:',
        'Два обновления цен:',
        'Монеты с ростом цены:',
      ]) {
        expect(text, contains(title));
      }
      expect(output.last, 'Bitcoin');
    } finally {
      api.close();
    }
  });

  group('Модели', () {
    test('Coin читает три поля, включая целочисленную цену', () {
      final coin = Coin.fromJson({
        'id': 'bitcoin',
        'name': 'Bitcoin',
        'current_price': 65000,
      });
      expect(coin.id, 'bitcoin');
      expect(coin.name, 'Bitcoin');
      expect(coin.priceUsd, 65000.0);
    });
    test('Coin читает дробную цену', () {
      expect(
        Coin.fromJson({'id': 'x', 'name': 'X', 'current_price': 1.25}).priceUsd,
        1.25,
      );
    });
    test('Цена может отсутствовать', () {
      expect(Coin.fromJson({'id': 'x', 'name': 'X'}).priceUsd, isNull);
    });
    test('CoinDetails читает имя, английское описание и проценты', () {
      final coin = CoinDetails.fromJson(
        jsonDecode(details('Bitcoin')) as Map<String, dynamic>,
      );
      expect(coin.name, 'Bitcoin');
      expect(coin.description, 'Описание Bitcoin');
      expect(coin.changePercent, 2.5);
    });
    test('CoinDetails не требует необязательных вложенных полей', () {
      final coin = CoinDetails.fromJson({'name': 'New'});
      expect(coin.description, '');
      expect(coin.changePercent, isNull);
    });
    test('CoinDetails читает целое число процентов', () {
      expect(
        CoinDetails.fromJson({
          'name': 'X',
          'market_data': {'price_change_percentage_24h': 3},
        }).changePercent,
        3.0,
      );
    });
  });

  group('Запросы', () {
    test('Реализация используется через интерфейс', () {
      final CoinRepository api = repository(
        (_) async => response(markets, 200),
      );
      expect(api, isA<CoinRepository>());
      api.close();
    });
    test('Список: правильные URI/параметры и модели', () async {
      final api = repository((r) async {
        expect(r.url.host, 'api.coingecko.com');
        expect(r.url.path, '/api/v3/coins/markets');
        expect(r.url.queryParameters, containsPair('vs_currency', 'usd'));
        expect(r.url.queryParameters, containsPair('order', 'market_cap_desc'));
        expect(r.url.queryParameters, containsPair('per_page', '2'));
        expect(r.url.queryParameters, containsPair('page', '1'));
        return response(markets, 200);
      });
      addTearDown(api.close);
      expect((await api.getTopCoins(2)).map((coin) => coin.id), [
        'bitcoin',
        'ethereum',
      ]);
    });
    test('limit вне 1–250 отклоняется до HTTP-запроса', () async {
      var calls = 0;
      final api = repository((_) async {
        calls++;
        return response('[]', 200);
      });
      addTearDown(api.close);
      for (final limit in [0, -1, 251]) {
        await expectLater(
          Future.sync(() => api.getTopCoins(limit)),
          throwsArgumentError,
        );
      }
      expect(calls, 0);
    });
    test('Детали: endpoint, localization и вложенный JSON', () async {
      final api = repository((r) async {
        expect(r.url.path, '/api/v3/coins/bitcoin');
        expect(r.url.queryParameters['localization'], 'false');
        return response(
          details('Bitcoin'),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      addTearDown(api.close);
      final coin = await api.getCoinDetails('bitcoin');
      expect(coin.name, 'Bitcoin');
      expect(coin.description, 'Описание Bitcoin');
    });
    test('Зависший запрос завершается ошибкой через 15 секунд', () {
      fakeAsync((time) {
        Object? error;
        final pending = Completer<http.Response>();
        final api = repository((_) => pending.future);
        api
            .getTopCoins(2)
            .then<void>(
              (_) {},
              onError: (Object value) {
                error = value;
              },
            );
        time.flushMicrotasks();
        time.elapse(const Duration(seconds: 14));
        expect(error, isNull);
        time.elapse(const Duration(seconds: 1));
        time.flushMicrotasks();
        expect(error, isA<Exception>());
        api.close();
      });
    });
    for (final status in [404, 429, 500]) {
      test('HTTP $status даёт понятную ошибку', () async {
        final api = repository((_) async => response('error', status));
        addTearDown(api.close);
        await expectLater(
          api.getCoinDetails('bitcoin'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('$status'),
            ),
          ),
        );
      });
    }
    test('Повреждённый JSON', () async {
      final api = repository((_) async => response('{broken', 200));
      addTearDown(api.close);
      await expectLater(api.getTopCoins(2), throwsA(isA<Exception>()));
    });
    test('Вместо списка пришёл объект', () async {
      final api = repository((_) async => response('{}', 200));
      addTearDown(api.close);
      await expectLater(api.getTopCoins(2), throwsA(isA<Exception>()));
    });
    test('Вместо деталей пришёл список', () async {
      final api = repository((_) async => response('[]', 200));
      addTearDown(api.close);
      await expectLater(
        api.getCoinDetails('bitcoin'),
        throwsA(isA<Exception>()),
      );
    });
    test('Ошибка сети', () async {
      final api = repository(
        (_) async => throw http.ClientException('offline'),
      );
      addTearDown(api.close);
      await expectLater(api.getTopCoins(2), throwsA(isA<Exception>()));
    });
    test('close закрывает переданный клиент', () {
      final client = RecordingClient((_) async => response('[]', 200));
      final api = createRepository(client);
      api.close();
      expect(client.closed, isTrue);
    });
  });

  group('Stream', () {
    test('Последовательные запросы в порядке id, затем done', () async {
      final requested = <String>[];
      final api = repository((r) async {
        final id = r.url.pathSegments.last;
        requested.add(id);
        return response(details(id), 200);
      });
      addTearDown(api.close);
      await expectLater(
        api.getCoinsStream(['ethereum', 'bitcoin']).map((c) => c.name),
        emitsInOrder(['ethereum', 'bitcoin', emitsDone]),
      );
      expect(requested, ['ethereum', 'bitcoin']);
    });
    test(
      'Нет запроса до подписки; события приходят по мере загрузки',
      () async {
        final second = Completer<http.Response>();
        final firstEvent = Completer<void>();
        final names = <String>[];
        final api = repository(
          (r) async => r.url.pathSegments.last == 'bitcoin'
              ? response(details('Bitcoin'), 200)
              : second.future,
        );
        addTearDown(api.close);
        final stream = api.getCoinsStream(['bitcoin', 'ethereum']);
        final finished = Completer<void>();
        final subscription = stream.listen(
          (c) {
            names.add(c.name);
            if (!firstEvent.isCompleted) firstEvent.complete();
          },
          onError: (Object error, StackTrace stack) {
            if (!firstEvent.isCompleted) firstEvent.completeError(error, stack);
            if (!finished.isCompleted) finished.completeError(error, stack);
          },
          onDone: finished.complete,
        );
        addTearDown(subscription.cancel);
        await firstEvent.future;
        expect(names, ['Bitcoin']);
        second.complete(response(details('Ethereum'), 200));
        await finished.future;
        expect(names, ['Bitcoin', 'Ethereum']);
      },
    );
    test('Пустой список завершает поток без HTTP', () async {
      var calls = 0;
      final api = repository((_) async {
        calls++;
        return response('{}', 200);
      });
      addTearDown(api.close);
      expect(await api.getCoinsStream([]).toList(), isEmpty);
      expect(calls, 0);
    });
    test('Ошибка останавливает поток и последующие запросы', () async {
      final requested = <String>[];
      final api = repository((r) async {
        final id = r.url.pathSegments.last;
        requested.add(id);
        return response(
          id == 'missing' ? 'error' : details(id),
          id == 'missing' ? 404 : 200,
        );
      });
      addTearDown(api.close);
      await expectLater(
        api
            .getCoinsStream(['bitcoin', 'missing', 'ethereum'])
            .map((c) => c.name),
        emitsInOrder(['bitcoin', emitsError(isA<Exception>()), emitsDone]),
      );
      expect(requested, ['bitcoin', 'missing']);
    });
  });

  group('Поллинг', () {
    test('Сразу, затем interval; новые цены и остановка после take', () {
      fakeAsync((time) {
        var calls = 0;
        final values = <double?>[];
        var done = false;
        final api = repository((r) async {
          expect(r.url.path, '/api/v3/coins/markets');
          expect(r.url.queryParameters['ids'], 'bitcoin,ethereum');
          expect(r.url.queryParameters['vs_currency'], 'usd');
          calls++;
          return response(
            '[{"id":"bitcoin","name":"Bitcoin","current_price":$calls}]',
            200,
          );
        });
        api
            .pollPrices(['bitcoin', 'ethereum'], const Duration(seconds: 10))
            .take(2)
            .listen(
              (coins) => values.add(coins.single.priceUsd),
              onDone: () => done = true,
            );
        time.flushMicrotasks();
        expect(calls, 1);
        expect(values, [1.0]);
        time.elapse(const Duration(seconds: 9));
        expect(calls, 1);
        time.elapse(const Duration(seconds: 1));
        expect(values, [1.0, 2.0]);
        expect(done, isTrue);
        time.elapse(const Duration(minutes: 1));
        expect(calls, 2);
        api.close();
      });
    });
    test('Нет запросов без подписки', () {
      var calls = 0;
      final api = repository((_) async {
        calls++;
        return response('[]', 200);
      });
      api.pollPrices(['bitcoin'], const Duration(seconds: 1));
      expect(calls, 0);
      api.close();
    });
    test('Запросы не перекрываются; interval отсчитывается после ответа', () {
      fakeAsync((time) {
        var calls = 0;
        final first = Completer<http.Response>();
        final api = repository((_) {
          calls++;
          return calls == 1 ? first.future : Future.value(response('[]', 200));
        });
        api
            .pollPrices(['bitcoin'], const Duration(seconds: 1))
            .take(2)
            .listen((_) {});
        time.flushMicrotasks();
        time.elapse(const Duration(seconds: 3));
        expect(calls, 1);
        first.complete(response('[]', 200));
        time.flushMicrotasks();
        expect(calls, 1);
        time.elapse(const Duration(seconds: 1));
        expect(calls, 2);
        api.close();
      });
    });
    test('Нулевой и отрицательный interval отклоняются', () async {
      final api = repository((_) async => response('[]', 200));
      addTearDown(api.close);
      for (final interval in [Duration.zero, const Duration(seconds: -1)]) {
        await expectLater(
          api.pollPrices(['bitcoin'], interval),
          emitsError(isArgumentError),
        );
      }
    });
    test('Пустой список id завершает polling без HTTP', () async {
      var calls = 0;
      final api = repository((_) async {
        calls++;
        return response('[]', 200);
      });
      addTearDown(api.close);
      expect(
        await api.pollPrices([], const Duration(seconds: 1)).toList(),
        isEmpty,
      );
      expect(calls, 0);
    });
    test('Ошибка завершает polling без повторов', () {
      fakeAsync((time) {
        var calls = 0;
        Object? error;
        var done = false;
        final api = repository((_) async {
          calls++;
          return response('error', 429);
        });
        api
            .pollPrices(['bitcoin'], const Duration(seconds: 1))
            .listen(
              (_) {},
              onError: (Object e) => error = e,
              onDone: () => done = true,
            );
        time.flushMicrotasks();
        expect(error, isA<Exception>());
        expect(done, isTrue);
        time.elapse(const Duration(seconds: 10));
        expect(calls, 1);
        api.close();
      });
    });
  });

  group('Преобразование', () {
    test('Фильтр роста и имена, порядок сохраняется', () async {
      final changes = <String, double?>{
        'positive': 2,
        'negative': -1,
        'zero': 0,
        'missing': null,
        'also-positive': 1,
      };
      final api = repository((r) async {
        final id = r.url.pathSegments.last;
        return response(details(id, change: changes[id]), 200);
      });
      addTearDown(api.close);
      expect(await api.getGrowingCoinNames(changes.keys.toList()).toList(), [
        'positive',
        'also-positive',
      ]);
    });
    test('Преобразованный поток передаёт ошибку', () async {
      final api = repository((_) async => response('error', 500));
      addTearDown(api.close);
      await expectLater(
        api.getGrowingCoinNames(['bitcoin']),
        emitsError(isA<Exception>()),
      );
    });
  });
}

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
