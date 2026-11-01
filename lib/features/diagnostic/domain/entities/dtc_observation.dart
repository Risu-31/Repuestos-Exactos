class DtcObservation {
  const DtcObservation({
    required this.code,
    required this.ecu,
    required this.kind,
  });
  final String code;
  final String ecu;
  final String kind;
  Map<String, String> toJson() => {'code': code, 'ecu': ecu, 'kind': kind};
}
