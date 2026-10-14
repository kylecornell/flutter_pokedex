import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/app_exception.dart';

/// Thin wrapper over `http.Client`: builds URLs, applies a timeout and turns
/// every failure into an [AppException].
class ApiClient {
  ApiClient({
    http.Client? client,
    String baseUrl = ApiConstants.baseUrl,
    this._timeout = ApiConstants.requestTimeout,
  })  : _client = client ?? http.Client(),
        _baseUri = Uri.parse(baseUrl);

  final http.Client _client;
  final Uri _baseUri;
  final Duration _timeout;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _baseUri.resolve(path).replace(queryParameters: query);

    final http.Response response;
    try {
      response = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw const NetworkException('Request timed out.');
    } on http.ClientException {
      throw const NetworkException();
    }

    if (response.statusCode == 404) throw const NotFoundException();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ServerException(response.statusCode);
    }

    try {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw const ParsingException();
    } on TypeError {
      throw const ParsingException();
    }
  }

  void close() => _client.close();
}
