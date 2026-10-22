class SecurityException implements Exception {
  final String message;
  final String? code;

  const SecurityException(this.message, {this.code});

  @override
  String toString() => 'SecurityException: $message${code != null ? ' (Code: $code)' : ''}';
}
