import 'package:supabase_flutter/supabase_flutter.dart';

class ConfiguracionNegocioAdmin {
  final String nombreNegocio;
  final String telefonoWhatsApp;
  final String telefonoLlamadas;
  final String direccion;
  final double latitud;
  final double longitud;

  const ConfiguracionNegocioAdmin({
    required this.nombreNegocio,
    required this.telefonoWhatsApp,
    required this.telefonoLlamadas,
    required this.direccion,
    required this.latitud,
    required this.longitud,
  });

  factory ConfiguracionNegocioAdmin.fromJson(Map<String, dynamic> json) {
    double numero(dynamic value, double fallback) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return ConfiguracionNegocioAdmin(
      nombreNegocio: json['nombre_negocio']?.toString() ?? 'Pollos Arica',
      telefonoWhatsApp: json['telefono_whatsapp']?.toString() ?? '',
      telefonoLlamadas: json['telefono_llamadas']?.toString() ?? '',
      direccion: json['direccion']?.toString() ?? '',
      latitud: numero(json['latitud'], -17.8311294),
      longitud: numero(json['longitud'], -63.1341483),
    );
  }
}

class ConfiguracionNegocioAdminService {
  ConfiguracionNegocioAdminService._();

  static final ConfiguracionNegocioAdminService instance =
      ConfiguracionNegocioAdminService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ConfiguracionNegocioAdmin> obtener() async {
    final data = await _supabase
        .from('configuracion_negocio')
        .select(
          'id, nombre_negocio, telefono_whatsapp, telefono_llamadas, '
          'direccion, latitud, longitud',
        )
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (data == null) {
      throw Exception(
        'No existe un registro en configuracion_negocio. '
        'Agrega primero la configuración del restaurante en Supabase.',
      );
    }

    return ConfiguracionNegocioAdmin.fromJson(data);
  }

  Future<void> actualizar({
    required String nombreNegocio,
    required String telefonoWhatsApp,
    required String telefonoLlamadas,
    required String direccion,
    required double latitud,
    required double longitud,
  }) async {
    // Primero identificamos el registro único de configuración.
    // El filtro por id evita ejecutar un UPDATE sin WHERE.
    final registro = await _supabase
        .from('configuracion_negocio')
        .select('id')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (registro == null || registro['id'] == null) {
      throw Exception(
        'No existe un registro de configuración para actualizar. '
        'Verifica la tabla configuracion_negocio en Supabase.',
      );
    }

    final id = registro['id'];

    final respuesta = await _supabase
        .from('configuracion_negocio')
        .update({
          'nombre_negocio': nombreNegocio.trim(),
          'telefono_whatsapp': telefonoWhatsApp.trim(),
          'telefono_llamadas': telefonoLlamadas.trim(),
          'direccion': direccion.trim(),
          'latitud': latitud,
          'longitud': longitud,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('id');

    if (respuesta.isEmpty) {
      throw Exception(
        'Supabase no actualizó el registro. Comprueba que tu sesión '
        'tenga permisos de administrador y que la política RLS '
        'de UPDATE permita ejecutar public.es_admin_activo().',
      );
    }
  }
}
