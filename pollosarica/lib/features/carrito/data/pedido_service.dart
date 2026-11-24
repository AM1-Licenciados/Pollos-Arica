
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cliente/services/cliente_local_service.dart';
import '../../cliente/services/autenticacion_service.dart';
import 'carrito_service.dart';

class PedidoCreado {
  final String id;
  final String codigo;
  final double total;
  final String metodoPago;
  final bool seguimientoGuardado;

  const PedidoCreado({
    required this.id,
    required this.codigo,
    required this.total,
    required this.metodoPago,
    this.seguimientoGuardado = true,
  });
}

class PedidoService {
  PedidoService._();

  static final PedidoService instance = PedidoService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<String?> obtenerQrActual() async {
    final respuesta = await _supabase
        .from('configuracion_negocio')
        .select('qr_imagen_url')
        .limit(1)
        .maybeSingle();

    return respuesta?['qr_imagen_url'] as String?;
  }


  static const String _bucketComprobantes = 'comprobantes-pago';

  Future<void> subirComprobanteQr({
    required String pedidoId,
    required XFile archivo,
  }) async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión para adjuntar el comprobante.');
    }

    final extension = archivo.name.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => null,
    };

    if (mime == null) {
      throw Exception('Formato no permitido. Usa JPG, PNG o WEBP.');
    }

    final bytes = await archivo.readAsBytes();
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw Exception('El comprobante debe pesar como máximo 5 MB.');
    }

    final pedido = await _supabase
        .from('pedidos')
        .select('id, metodo_pago, estado_pago')
        .eq('id', pedidoId)
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    if (pedido == null ||
        pedido['metodo_pago'] != 'qr' ||
        pedido['estado_pago'] != 'pendiente') {
      throw Exception('Este pedido ya no admite comprobantes.');
    }

    final ruta = '${usuario.id}/$pedidoId/comprobante';
    final storage = _supabase.storage.from(_bucketComprobantes);

    // Si el cliente reemplaza la imagen o reintenta tras un fallo de red,
    // se elimina el archivo anterior antes de subir el nuevo.
    try {
      await storage.remove([ruta]);
    } catch (_) {
      // No existe archivo anterior: continuamos con la primera carga.
    }

    await storage.uploadBinary(
      ruta,
      bytes,
      fileOptions: FileOptions(
        contentType: mime,
        upsert: false,
      ),
    );
  }

  Future<String?> obtenerUrlComprobanteQr(String authUserId, String pedidoId) async {
    if (_supabase.auth.currentUser == null) return null;
    final ruta = '$authUserId/$pedidoId/comprobante';
    try {
      return await _supabase.storage
          .from(_bucketComprobantes)
          .createSignedUrl(ruta, 300);
    } catch (_) {
      return null;
    }
  }

  Future<void> notificarPagoQr(String pedidoId) async {
    final usuario = _supabase.auth.currentUser;

    if (usuario == null) {
      throw Exception('Debes iniciar sesión para notificar el pago.');
    }

    final respuesta = await _supabase
        .from('pedidos')
        .update({
          'estado_pago': 'por_verificar',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', pedidoId)
        .eq('auth_user_id', usuario.id)
        .eq('metodo_pago', 'qr')
        .eq('estado_pago', 'pendiente')
        .select('id');

    if (respuesta.isEmpty) {
      // Hacer la operación idempotente: si la primera solicitud llegó
      // al servidor pero se perdió la respuesta, el cliente puede reintentar.
      final pedidoActual = await _supabase
          .from('pedidos')
          .select('estado_pago')
          .eq('id', pedidoId)
          .eq('auth_user_id', usuario.id)
          .eq('metodo_pago', 'qr')
          .maybeSingle();

      if (pedidoActual?['estado_pago'] == 'por_verificar' ||
          pedidoActual?['estado_pago'] == 'pagado') {
        return;
      }

      if (pedidoActual?['estado_pago'] == 'rechazado') {
        throw Exception('El pago de este pedido fue rechazado.');
      }

      throw Exception(
        'No se pudo notificar el pago. Verifica que el pedido '
        'pertenezca a tu cuenta y siga pendiente.',
      );
    }
  }

  Future<PedidoCreado> crearPedido({
    required String nombre,
    required String celular,
    required String metodoPago,
    required String tipoEntrega,
    required String momentoPreparacion,
    String? observaciones,
  }) async {
    if (!AutenticacionService.instance.estaAutenticado) {
      throw Exception('Debes iniciar sesión para realizar un pedido.');
    }

    final carrito = CarritoService.instance;

    final momentoFinal = tipoEntrega == 'retiro'
        ? 'inmediato'
        : momentoPreparacion;

    if (carrito.items.isEmpty) {
      throw Exception('Tu carrito está vacío.');
    }

    final items = carrito.items
        .map(
          (item) => {
            'producto_id': item.producto.id,
            'variante_id': item.variante.id,
            'cantidad': item.cantidad,
          },
        )
        .toList();

    final respuesta = await _supabase.rpc(
      'crear_pedido_con_seguimiento',
      params: {
        'p_nombre': nombre.trim(),
        'p_celular': celular.trim(),
        'p_metodo_pago': metodoPago,
        'p_items': items,
        'p_observaciones': observaciones?.trim().isEmpty == true
            ? null
            : observaciones?.trim(),
        'p_tipo_entrega': tipoEntrega,
        'p_momento_preparacion': momentoFinal,
      },
    );

    if (respuesta is! Map) {
      throw Exception('Supabase devolvió una respuesta inesperada.');
    }

    final data = Map<String, dynamic>.from(respuesta);

    if (data['exito'] != true) {
      throw Exception('No se pudo registrar el pedido.');
    }

    final pedidoId = data['pedido_id']?.toString();
    final codigo = data['codigo']?.toString();
    final total = data['total'];
    final token = data['seguimiento_token']?.toString();

    if (pedidoId == null ||
        pedidoId.isEmpty ||
        codigo == null ||
        codigo.isEmpty ||
        total is! num ||
        token == null ||
        token.isEmpty) {
      throw Exception(
        'El pedido se registró, pero Supabase no devolvió todos los datos de seguimiento.',
      );
    }

    // Intentamos guardar la credencial privada en el dispositivo.
    // Si falla el almacenamiento local, no repetimos la creación
    // del pedido ni dejamos el carrito listo para duplicarlo.
    var seguimientoGuardado = false;

    try {
      await ClienteLocalService.instance.guardarPedidoSeguimiento(
        pedidoId: pedidoId,
        seguimientoToken: token,
      );

      seguimientoGuardado = true;
    } catch (_) {
      seguimientoGuardado = false;
    }

    final pedido = PedidoCreado(
      id: pedidoId,
      codigo: codigo,
      total: total.toDouble(),
      metodoPago: metodoPago,
      seguimientoGuardado: seguimientoGuardado,
    );

    carrito.vaciar();

    return pedido;
  }
}
