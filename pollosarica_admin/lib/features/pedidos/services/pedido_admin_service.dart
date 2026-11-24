
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pedido.dart';

class PedidoAdminService {
  PedidoAdminService._();

  static final PedidoAdminService instance =
      PedidoAdminService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Pedido>> obtenerPedidos() async {
    // 1. Consultar pedidos.
    final respuestaPedidos = await _supabase
        .from('pedidos')
        .select()
        .order('created_at', ascending: false);

    final pedidosMap = List<Map<String, dynamic>>.from(
      respuestaPedidos,
    );

    if (pedidosMap.isEmpty) return [];

    final clienteIds = pedidosMap
        .map((pedido) => pedido['cliente_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final pedidoIds = pedidosMap
        .map((pedido) => pedido['id'].toString())
        .toList();

    // 2. Consultar clientes.
    Map<String, Map<String, dynamic>> clientesMap = {};

    if (clienteIds.isNotEmpty) {
      final respuestaClientes = await _supabase
          .from('clientes')
          .select('id, nombre, celular')
          .inFilter('id', clienteIds);

      for (final cliente in respuestaClientes) {
        final map = Map<String, dynamic>.from(cliente);
        clientesMap[map['id'].toString()] = map;
      }
    }

    // 3. Consultar detalles de los pedidos.
    final respuestaDetalles = await _supabase
        .from('detalle_pedidos')
        .select()
        .inFilter('pedido_id', pedidoIds);

    final detallesPorPedido = <String, List<DetallePedido>>{};

    for (final detalle in respuestaDetalles) {
      final map = Map<String, dynamic>.from(detalle);
      final pedidoId = map['pedido_id'].toString();

      detallesPorPedido.putIfAbsent(pedidoId, () => []);
      detallesPorPedido[pedidoId]!.add(
        DetallePedido.fromMap(map),
      );
    }

    // 4. Relacionar pedidos, clientes y detalles.
    return pedidosMap.map((map) {
      final clienteId = map['cliente_id']?.toString() ?? '';
      final pedidoId = map['id'].toString();

      return Pedido.fromMap(
        map,
        cliente: clientesMap[clienteId],
        detalles: detallesPorPedido[pedidoId] ?? [],
      );
    }).toList();
  }

  Future<void> actualizarEstado(
    String pedidoId,
    String nuevoEstado,
  ) async {
    if (!PedidoEstados.pedido.contains(nuevoEstado)) {
      throw Exception('Estado de pedido no válido.');
    }

    await _supabase
        .from('pedidos')
        .update({
          'estado': nuevoEstado,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', pedidoId);
  }

  Future<void> actualizarEstadoPago(
    String pedidoId,
    String nuevoEstado,
  ) async {
    if (!PedidoEstados.pago.contains(nuevoEstado)) {
      throw Exception('Estado de pago no válido.');
    }

    // Consultar el estado actual para validar el flujo antes de escribir.
    // PostgreSQL seguirá aplicando la validación definitiva mediante RLS
    // y el trigger de protección del pedido.
    final pedidoActual = await _supabase
        .from('pedidos')
        .select('metodo_pago, estado_pago')
        .eq('id', pedidoId)
        .single();

    final metodoPago = pedidoActual['metodo_pago']?.toString();
    final estadoActual = pedidoActual['estado_pago']?.toString();

    if (metodoPago == 'qr') {
      final transicionPermitida = estadoActual == 'por_verificar' &&
          (nuevoEstado == 'pagado' || nuevoEstado == 'rechazado');

      if (!transicionPermitida) {
        throw Exception(
          'Un pago QR solo puede confirmarse o rechazarse '
          'cuando el cliente lo notificó y está por verificar.',
        );
      }
    } else if (metodoPago == 'efectivo') {
      final transicionPermitida =
          estadoActual == 'pendiente' && nuevoEstado == 'pagado';

      if (!transicionPermitida) {
        throw Exception(
          'El pago en efectivo solo puede marcarse como pagado '
          'desde el estado pendiente.',
        );
      }
    } else {
      throw Exception('Método de pago no reconocido.');
    }

    await _supabase
        .from('pedidos')
        .update({
          'estado_pago': nuevoEstado,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', pedidoId);
  }
}
