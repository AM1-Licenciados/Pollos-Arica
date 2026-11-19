class ConfiguracionNegocio {
  final String nombreNegocio;
  final String telefonoWhatsApp;
  final String telefonoLlamadas;
  final String direccion;
  final double latitud;
  final double longitud;

  const ConfiguracionNegocio({
    required this.nombreNegocio,
    required this.telefonoWhatsApp,
    required this.telefonoLlamadas,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });

  factory ConfiguracionNegocio.fromJson(Map<String, dynamic> json) {
    return ConfiguracionNegocio(
      nombreNegocio: json['nombre_negocio']?.toString() ?? 'Pollos Arica',
      telefonoWhatsApp: json['telefono_whatsapp']?.toString() ?? '',
      telefonoLlamadas: json['telefono_llamadas']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      latitud: _toDouble(json['latitud'], -17.8311294),
      longitud: _toDouble(json['longitud'], -63.1341483),
    );
  }

  static double _toDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
