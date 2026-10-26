class JsonReader {
  static Map<String, dynamic> object(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Respuesta JSON inválida.');
    }
    return value;
  }

  static String text(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Campo requerido inválido.');
    }
    return value;
  }

  static double number(Map<String, dynamic> json, String key) {
    final value = json[key];
    final parsed = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value)
        : null;
    if (parsed == null || !parsed.isFinite || parsed < 0) {
      throw const FormatException('Campo numérico inválido.');
    }
    return parsed;
  }
}
