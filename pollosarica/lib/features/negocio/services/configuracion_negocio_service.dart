import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/configuracion_negocio.dart';

class ConfiguracionNegocioService {
  ConfiguracionNegocioService._();

  static final ConfiguracionNegocioService instance =
      ConfiguracionNegocioService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<ConfiguracionNegocio> obtenerConfiguracion() async {
    final respuesta = await _supabase
        .from('configuracion_negocio')
        .select(
          'nombre_negocio, telefono_whatsapp, telefono_llamadas, '
          'direccion, latitud, longitud',
        )
        .limit(1)
        .maybeSingle();

    if (respuesta == null) {
      throw Exception(
        'No se encontró la configuración del restaurante en Supabase.',
      );
    }

    return ConfiguracionNegocio.fromJson(respuesta);
  }
}
