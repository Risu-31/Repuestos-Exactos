class ObdException implements Exception {
  const ObdException(this.message);
  final String message;
  @override
  String toString() => message;
}
