/// Base type for every error the UI may need to show.
/// Lower layers throw these instead of raw http / parsing errors.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No connection, DNS failure or timeout.
class NetworkException extends AppException {
  const NetworkException([super.message = 'Network unavailable. Check your connection.']);
}

/// API answered 404.
class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Not found.']);
}

/// API answered with another non-2xx status.
class ServerException extends AppException {
  const ServerException(this.statusCode)
      : super('Server error ($statusCode). Try again later.');

  final int statusCode;
}

/// Response body was not the JSON shape we expected.
class ParsingException extends AppException {
  const ParsingException([super.message = 'Unexpected data from server.']);
}
