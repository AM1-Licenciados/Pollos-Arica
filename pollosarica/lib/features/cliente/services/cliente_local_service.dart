
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ClienteLocalService {
  ClienteLocalService._();

  static final ClienteLocalService instance = ClienteLocalService._();

  static const String _claveNombre = 'cliente_nombre';
  static const String _claveTelefono = 'cliente_telefono';
  static const String _clavePedidos = 'cliente_pedidos_seguimiento';

  // =====================================================
  // DATOS DEL CLIENTE
  // =====================================================

  Future<void> guardarCliente({
    required String nombre,
    required String telefono,
  }) async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.setString(_claveNombre, nombre.trim());
    await preferencias.setString(_claveTelefono, telefono.trim());
  }

  Future<Map<String, String>?> obtenerCliente() async {
    final preferencias = await SharedPreferences.getInstance();

    final nombre = preferencias.getString(_claveNombre);
    final telefono = preferencias.getString(_claveTelefono);

    if (nombre == null ||
        nombre.trim().isEmpty ||
        telefono == null ||
        telefono.trim().isEmpty) {
      return null;
    }

    return {
      'nombre': nombre,
      'telefono': telefono,
    };
  }

  Future<void> eliminarCliente() async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.remove(_claveNombre);
    await preferencias.remove(_claveTelefono);
  }

  // =====================================================
  // HISTORIAL PRIVADO DE PEDIDOS
  // =====================================================

  Future<void> guardarPedidoSeguimiento({
    required String pedidoId,
    required String seguimientoToken,
  }) async {
    final id = pedidoId.trim();
    final token = seguimientoToken.trim();

    if (id.isEmpty || token.isEmpty) {
      throw Exception('Los datos de seguimiento del pedido son inválidos.');
    }

    final preferencias = await SharedPreferences.getInstance();

    final pedidos = await obtenerPedidosSeguimiento();

    // Evitar guardar dos veces el mismo pedido.
    pedidos.removeWhere((pedido) => pedido['pedido_id'] == id);

    pedidos.add({
      'pedido_id': id,
      'seguimiento_token': token,
    });

    final resultado = await preferencias.setString(
      _clavePedidos,
      jsonEncode(pedidos),
    );

    if (!resultado) {
      throw Exception('No se pudo guardar el seguimiento del pedido.');
    }
  }

  Future<List<Map<String, String>>> obtenerPedidosSeguimiento() async {
    final preferencias = await SharedPreferences.getInstance();

    final contenido = preferencias.getString(_clavePedidos);

    if (contenido == null || contenido.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(contenido);

      if (decoded is! List) {
        return [];
      }

      final pedidos = <Map<String, String>>[];

      for (final elemento in decoded) {
        if (elemento is! Map) continue;

        final id = elemento['pedido_id']?.toString();
        final token = elemento['seguimiento_token']?.toString();

        if (id == null ||
            id.isEmpty ||
            token == null ||
            token.isEmpty) {
          continue;
        }

        pedidos.add({
          'pedido_id': id,
          'seguimiento_token': token,
        });
      }

      return pedidos;
    } catch (_) {
      return [];
    }
  }

  Future<void> eliminarPedidoSeguimiento(String pedidoId) async {
    final preferencias = await SharedPreferences.getInstance();

    final pedidos = await obtenerPedidosSeguimiento();

    pedidos.removeWhere(
      (pedido) => pedido['pedido_id'] == pedidoId,
    );

    await preferencias.setString(
      _clavePedidos,
      jsonEncode(pedidos),
    );
  }

  Future<void> eliminarTodosLosSeguimientos() async {
    final preferencias = await SharedPreferences.getInstance();

    await preferencias.remove(_clavePedidos);
  }
}
