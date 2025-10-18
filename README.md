# Задание по асинхронному программированию на Dart с CoinGecko API

- Работа с `Future` и `async/await`
- Создание и использование `Stream`
- HTTP-запросы с помощью пакета `http`
- Десериализация JSON в Dart-объекты
- Реализация паттерна Repository
- Обработка ошибок в асинхронном коде

## Установка зависимостей

### Основные пакеты

```bash
# Добавление пакета http для HTTP-запросов
dart pub add http

# Альтернативно, можно использовать dio (более мощный HTTP-клиент)
dart pub add dio
```

### Опциональные пакеты для продвинутой работы

```bash
# Freezed для создания immutable моделей с автогенерацией
dart pub add freezed_annotation
dart pub add --dev build_runner
dart pub add --dev freezed

# Дополнительные пакеты для работы с JSON
dart pub add json_annotation
dart pub add --dev json_serializable
```

## Структура проекта

- `task.dart` - Заготовка кода с TODO для выполнения
- `pubspec.yaml` - Файл зависимостей

## Задачи

### Обязательные задачи

1. **Создание моделей данных**
   - `Coin` - базовая информация о криптовалюте
   - `CoinDetails` - детальная информация

2. **Реализация Repository**
   - `getTopCoins(int limit)` - получение топ криптовалют
   - `getCoinDetails(String coinId)` - детальная информация о монете
   - `getCoinsStream(List<String> coinIds)` - стрим с монетами

3. **CLI-интерфейс**
   - Вывод отформатированной информации в консоль

### Опциональные задачи (*)
1. Использовать json_serializable (можно с freezed) для создания моделей

2. **Периодическое обновление**
   - `pollPrices()` - стрим с периодическим обновлением цен

3. **Трансформации стримов**
   - Фильтрация по цене
   - Извлечение только названий

## API Endpoints

Используется бесплатный API CoinGecko:

- **Топ криптовалют**: `GET /api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page={limit}`
- **Детали монеты**: `GET /api/v3/coins/{id}?localization=false`

Базовый URL: `https://api.coingecko.com`

## Запуск

```bash
# Установка зависимостей
dart pub get

# Запуск
dart run task.dart

## Ожидаемый вывод

```
Начинаем работу с CoinGecko API...

Топ 5 криптовалют по рыночной капитализации:
1. Bitcoin (btc): $45000.00
2. Ethereum (eth): $3000.00
3. Cardano (ada): $0.50
...

Детальная информация о Bitcoin:
Название: Bitcoin
Символ: btc
Ранг по капитализации: 1
Изменение за 24ч: 2.50%
...

Получение информации через стрим:
Получена монета: Bitcoin (btc)
Получена монета: Ethereum (eth)
...
```

## Полезные ресурсы

- [Dart Async Programming](https://dart.dev/codelabs/async-await)
- [Stream API в Dart](https://dart.dev/tutorials/language/streams)
- [HTTP Package](https://pub.dev/packages/http)
- [JSON Serialization](https://dart.dev/guides/json)
- [CoinGecko API Documentation](https://www.coingecko.com/en/api/documentation)

## Советы по выполнению

1. Начните с создания простых моделей данных
2. Реализуйте HTTP-запросы по одному
3. Добавьте обработку ошибок
4. Создайте стримы после освоения Future

## Критерии оценки

- **Базовый уровень**: Работающие HTTP-запросы и десериализация
- **Средний уровень**: Корректная работа со стримами
- **Продвинутый уровень**: Реализация всех опциональных задач
