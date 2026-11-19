class PedidoDetalleCliente {
  final String? productoId;
  final String? varianteId;
  final String nombreProducto;
  final String nombreVariante;
  final String? seccion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const PedidoDetalleCliente({
    this.productoId,
    this.varianteId,
    required this.nombreProducto,
    required this.nombreVariante,
    this.seccion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory PedidoDetalleCliente.fromMap(Map<String, dynamic> map) {
    return PedidoDetalleCliente(
      productoId: map['producto_id']?.toString(),
      varianteId: map['variante_id']?.toString(),
      nombreProducto: map['nombre_producto']?.toString() ?? 'Producto',
      nombreVariante: map['nombre_variante']?.toString() ?? '',
      seccion: map['seccion']?.toString(),
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario: (map['precio_unitario'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PedidoCliente {
  final String id;
  final String codigo;
  final String estado;
  final String metodoPago;
  final String estadoPago;
  final String tipoEntrega;
  final String momentoPreparacion;
  final bool clienteLlego;
  final double subtotal;
  final double total;
  final String? observaciones;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<PedidoDetalleCliente> detalles;

  const PedidoCliente({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.metodoPago,
    required this.estadoPago,
    required this.tipoEntrega,
    required this.momentoPreparacion,
    required this.clienteLlego,
    required this.subtotal,
    required this.total,
    this.observaciones,
    required this.createdAt,
    this.updatedAt,
    required this.detalles,
  });

  factory PedidoCliente.fromMap(Map<String, dynamic> map) {
    final detallesJson = map['detalles'] as List? ?? [];

    return PedidoCliente(
      id: map['id'].toString(),
      codigo: map['codigo']?.toString() ?? '',
      estado: map['estado']?.toString() ?? 'pendiente',
      metodoPago: map['metodo_pago']?.toString() ?? '',
      estadoPago: map['estado_pago']?.toString() ?? 'pendiente',
      tipoEntrega: map['tipo_entrega']?.toString() ?? 'retiro',
      momentoPreparacion:
          map['momento_preparacion']?.toString() ?? 'inmediato',
      clienteLlego: map['cliente_llego'] == true,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 0,
      observaciones: map['observaciones']?.toString(),
      createdAt: DateTime.parse(map['created_at'].toString()),
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.tryParse(map['updated_at'].toString()),
      detalles: detallesJson
          .whereType<Map>()
          .map(
            (detalle) => PedidoDetalleCliente.fromMap(
              Map<String, dynamic>.from(detalle),
            ),
          )
          .toList(),
    );
  }

  int get cantidadProductos =>
      detalles.fold(0, (total, detalle) => total + detalle.cantidad);
}

class PedidoEstadosCliente {
  static const pendiente = 'pendiente';
  static const aceptado = 'aceptado';
  static const enPreparacion = 'en_preparacion';
  static const listo = 'listo';
  static const entregado = 'entregado';
  static const rechazado = 'rechazado';
  static const cancelado = 'cancelado';

  static String etiqueta(String estado) {
    switch (estado) {
      case pendiente:
        return 'Pendiente';
      case aceptado:
        return 'Aceptado';
      case enPreparacion:
        return 'En preparación';
      case listo:
        return 'Listo para recoger';
      case entregado:
        return 'Entregado';
      case rechazado:
        return 'Rechazado';
      case cancelado:
        return 'Cancelado';
      default:
        return estado;
    }
  }
}