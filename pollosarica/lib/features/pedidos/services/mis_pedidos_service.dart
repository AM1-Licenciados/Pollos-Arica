import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cliente/services/cliente_local_service.dart';
import '../models/pedido_cliente.dart';

class MisPedidosService {
  MisPedidosService._();

  static final MisPedidosService instance = MisPedidosService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<PedidoCliente>> obtenerMisPedidos() async {
    final credenciales = await ClienteLocalService.instance
        .obtenerPedidosSeguimiento();

    if (credenciales.isEmpty) {
      return [];
    }

    final respuesta = await _supabase.rpc(
      'obtener_mis_pedidos',
      params: {
        'p_pedidos': credenciales,
      },
    );

    if (respuesta is! List) {
      throw Exception(
        'No se pudo interpretar la respuesta de los pedidos.',
      );
    }

    final pedidos = respuesta
        .whereType<Map>()
        .map(
          (pedido) => PedidoCliente.fromMap(
            Map<String, dynamic>.from(pedido),
          ),
        )
        .toList();

    pedidos.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return pedidos;
  }
}