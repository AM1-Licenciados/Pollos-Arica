import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class QrPagoAdminService {
  QrPagoAdminService._();

  static final QrPagoAdminService instance = QrPagoAdminService._();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucket = 'pagos-qr';
  static const int _maxBytes = 5 * 1024 * 1024;

  Future<String?> obtenerUrlActual() async {
    final registro = await _supabase
        .from('configuracion_negocio')
        .select('qr_imagen_url')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return registro?['qr_imagen_url']?.toString();
  }

  Future<String> actualizarQr(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > _maxBytes) {
      throw Exception('La imagen del QR debe pesar como máximo 5 MB.');
    }

    final registro = await _supabase
        .from('configuracion_negocio')
        .select('id')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    final id = registro?['id'];
    if (id == null) {
      throw Exception('No existe la configuración del negocio en Supabase.');
    }

    // Usamos un nombre nuevo por actualización para evitar caché y conservar
    // la imagen anterior si hay clientes con una pantalla de pago abierta.
    final marcaTiempo = DateTime.now().toUtc().millisecondsSinceEpoch;
    final ruta = 'qr-negocio/qr_\$marcaTiempo.png';
    final storage = _supabase.storage.from(_bucket);

    await storage.uploadBinary(
      ruta,
      bytes,
      fileOptions: const FileOptions(
        contentType: 'image/png',
        cacheControl: '3600',
        upsert: false,
      ),
    );

    final url = storage.getPublicUrl(ruta);
    try {
      final respuesta = await _supabase
          .from('configuracion_negocio')
          .update({
            'qr_imagen_url': url,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id)
          .select('id');

      if (respuesta.isEmpty) {
        throw Exception(
          'La imagen se subió, pero no se pudo actualizar la configuración. '
          'Comprueba que tu usuario sea administrador activo.',
        );
      }
    } catch (_) {
      // La imagen se conserva como archivo no referenciado para no arriesgar
      // borrar un QR anterior que aún pueda estar usando un cliente.
      rethrow;
    }

    return url;
  }
}
