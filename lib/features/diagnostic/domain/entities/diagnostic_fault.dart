class DiagnosticFault {
  const DiagnosticFault({
    required this.code,
    this.ecu,
    this.kind,
    this.description,
  });
  final String code;
  final String? ecu;
  final String? kind;
  final String? description;
}
