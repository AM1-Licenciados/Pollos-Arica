import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/clima.dart';

class ClimaService {
  ClimaService._();

  static final ClimaService instance = ClimaService._();

  static const double _latitudSantaCruz = -17.8311294;
  static const double _longitudSantaCruz = -63.1341483;
  static const Duration _tiempoLimite = Duration(seconds: 12);

  Future<Clima> obtenerClima({
    double latitud = _latitudSantaCruz,
    double longitud = _longitudSantaCruz,
  }) async {
    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitud.toString(),
        'longitude': longitud.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'is_day,precipitation,weather_code,wind_speed_10m',
        'timezone': 'America/La_Paz',
      },
    );

    try {
      final respuesta = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(_tiempoLimite);

      if (respuesta.statusCode != 200) {
        throw ClimaException(
          'El servicio del clima respondió con código '
          '${respuesta.statusCode}.',
        );
      }

      final decoded = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['current'] is! Map<String, dynamic>) {
        throw const ClimaException(
          'La respuesta del clima no tiene el formato esperado.',
        );
      }

      return Clima.fromJson(
        decoded['current'] as Map<String, dynamic>,
      );
    } on TimeoutException {
      throw const ClimaException(
        'El servicio del clima tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw const ClimaException(
        'No se pudo conectar con el servicio del clima.',
      );
    } on FormatException {
      throw const ClimaException(
        'No se pudo interpretar la respuesta del clima.',
      );
    } on ClimaException {
      rethrow;
    } catch (_) {
      throw const ClimaException(
        'Ocurrió un problema al consultar el clima.',
      );
    }
  }
}

class ClimaException implements Exception {
  final String mensaje;

  const ClimaException(this.mensaje);

  @override
  String toString() => mensaje;
}
