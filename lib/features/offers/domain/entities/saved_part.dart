class SavedPart {
  const SavedPart({
    required this.id,
    required this.externalId,
    required this.url,
    required this.code,
    required this.component,
    required this.author,
    required this.note,
    required this.createdAt,
    this.vehicle,
    required this.kind,
  });
  final String id, externalId, code, component, author, note, kind;
  final String? url;
  final DateTime createdAt;
  final String? vehicle;
}
