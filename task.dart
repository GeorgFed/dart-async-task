import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// TODO: Создайте модель Coin для десериализации JSON
// Должна содержать: id, name, symbol, current_price, market_cap
class Coin {
  // TODO: Добавьте конструктор и fromJson метод
}

// TODO: Создайте модель CoinDetails для детальной информации о монете
// Должна содержать: id, name, symbol, description, market_cap_rank, price_change_24h
class CoinDetails {
  // TODO: Добавьте конструктор и fromJson метод
}

// TODO: Реализуйте репозиторий для работы с CoinGecko API
class CoinGeckoRepository {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';
  
  // TODO: Реализуйте метод для получения топ криптовалют
  // Используйте эндпоинт: /coins/markets?vs_currency=usd&order=market_cap_desc&per_page={limit}
  Future<List<Coin>> getTopCoins(int limit) async {
    // TODO: Сделайте HTTP запрос и десериализуйте JSON
    throw UnimplementedError('Реализуйте метод getTopCoins');
  }
  
  // TODO: Реализуйте метод для получения детальной информации о монете
  // Используйте эндпоинт: /coins/{id}?localization=false
  Future<CoinDetails> getCoinDetails(String coinId) async {
    // TODO: Сделайте HTTP запрос и десериализуйте JSON
    throw UnimplementedError('Реализуйте метод getCoinDetails');
  }
  
  // TODO: Реализуйте Stream, который эмитит монеты по одной с задержкой
  // Используйте async* и yield для создания стрима
  Stream<Coin> getCoinsStream(List<String> coinIds) async* {
    // TODO: Для каждой coinId получите детали и эмитьте с задержкой
    // Используйте Future.delayed для задержки
    throw UnimplementedError('Реализуйте метод getCoinsStream');
  }
  
  // * ОПЦИОНАЛЬНО: Реализуйте стрим для периодического обновления цен
  // Используйте Stream.periodic для создания стрима с интервалом
  Stream<List<Coin>> pollPrices(List<String> coinIds, Duration interval) async* {
    // TODO: Создайте периодический стрим, который получает актуальные цены
    throw UnimplementedError('Реализуйте опциональный метод pollPrices');
  }
  
  // * ОПЦИОНАЛЬНО: Добавьте фильтрацию и трансформацию стрима
  Stream<Coin> getFilteredCoinsStream(List<String> coinIds, double minPrice) async* {
    // TODO: Фильтруйте монеты по минимальной цене
    throw UnimplementedError('Реализуйте опциональный метод getFilteredCoinsStream');
  }
}

void main() async {
  final repository = CoinGeckoRepository();
  
  print('Начинаем работу с CoinGecko API...\n');
  
  try {
    // TODO: Получите топ 5 криптовалют и выведите их
    print('Топ 5 криптовалют по рыночной капитализации:');
    // final topCoins = await repository.getTopCoins(5);
    // for (final coin in topCoins) {
    //   print('${coin.name} (${coin.symbol}): \$${coin.current_price}');
    // }
    
    print('\n' + '='*50 + '\n');
    
    // TODO: Получите детальную информацию о Bitcoin
    print('Детальная информация о Bitcoin:');
    // final btcDetails = await repository.getCoinDetails('bitcoin');
    // print('Название: ${btcDetails.name}');
    // print('Описание: ${btcDetails.description.substring(0, 100)}...');
    // print('Изменение за 24ч: ${btcDetails.price_change_24h}%');
    
    print('\n' + '='*50 + '\n');
    
    // TODO: Используйте стрим для получения информации о монетах
    print('Получение информации через стрим:');
    // final coinIds = ['bitcoin', 'ethereum', 'cardano'];
    // await for (final coin in repository.getCoinsStream(coinIds)) {
    //   print('Получена монета: ${coin.name} - \$${coin.current_price}');
    // }
    
    // * ОПЦИОНАЛЬНО: Используйте стрим с периодическим обновлением
    // print('\nПериодическое обновление цен (каждые 5 секунд):');
    // final subscription = repository.pollPrices(['bitcoin', 'ethereum'], Duration(seconds: 5))
    //     .take(3) // Ограничиваем 3 обновлениями
    //     .listen((coins) {
    //   print('Обновление: ${DateTime.now()}');
    //   for (final coin in coins) {
    //     print('  ${coin.name}: \$${coin.current_price}');
    //   }
    //   print('');
    // });
    
    // await subscription.asFuture();
    
  } catch (e) {
    print('Ошибка: $e');
  }
  
  print('\nПрограмма завершена!');
}
