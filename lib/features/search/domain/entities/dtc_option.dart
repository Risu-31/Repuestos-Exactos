class DtcOption {
  const DtcOption({
    required this.code,
    required this.description,
    required this.severity,
    required this.componentCount,
  });
  final String code;
  final String description;
  final String severity;
  final int componentCount;
}
