abstract interface class ObdTransport {
  bool get supported;
  Stream<List<int>> get bytes;
  Future<void> connect();
  Future<void> write(List<int> bytes);
  Future<void> disconnect();
  Future<void> dispose();
}
