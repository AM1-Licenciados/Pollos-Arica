class Clima {
  final double temperatura;
  final double sensacionTermica;
  final int humedad;
  final double viento;
  final int codigoClima;
  final bool esDeDia;
  final String descripcion;
  final String icono;

  const Clima({
    required this.temperatura,
    required this.sensacionTermica,
    required this.humedad,
    required this.viento,
    required this.codigoClima,
    required this.esDeDia,
    required this.descripcion,
    required this.icono,
  });

  factory Clima.fromJson(Map<String, dynamic> json) {
    final codigo = (json['weather_code'] as num?)?.toInt() ?? 0;
    final dia = (json['is_day'] as num?)?.toInt() == 1;
    final estado = _estadoClima(codigo, dia);

    return Clima(
      temperatura: (json['temperature_2m'] as num).toDouble(),
      sensacionTermica: (json['apparent_temperature'] as num?)?.toDouble()
          ?? (json['temperature_2m'] as num).toDouble(),
      humedad: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      viento: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0,
      codigoClima: codigo,
      esDeDia: dia,
      descripcion: estado.$1,
      icono: estado.$2,
    );
  }

  static (String, String) _estadoClima(int codigo, bool dia) {
    if (codigo == 0) return ('Despejado', dia ? '☀️' : '🌙');
    if (codigo == 1) return ('Mayormente despejado', dia ? '🌤️' : '☁️');
    if (codigo == 2) return ('Parcialmente nublado', '⛅');
    if (codigo == 3) return ('Nublado', '☁️');
    if ([45, 48].contains(codigo)) return ('Neblina', '🌫️');
    if ([51, 53, 55, 56, 57].contains(codigo)) return ('Llovizna', '🌦️');
    if ([61, 63, 65, 66, 67, 80, 81, 82].contains(codigo)) {
      return ('Lluvia', '🌧️');
    }
    if ([71, 73, 75, 77, 85, 86].contains(codigo)) return ('Nieve', '🌨️');
    if ([95, 96, 99].contains(codigo)) return ('Tormenta', '⛈️');
    return ('Condiciones variables', '🌡️');
  }
}
