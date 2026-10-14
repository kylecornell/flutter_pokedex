abstract final class ApiConstants {
  /// Trailing slash matters: relative paths are resolved against it.
  static const String baseUrl = 'https://pokeapi.co/api/v2/';

  static const Duration requestTimeout = Duration(seconds: 15);
}
