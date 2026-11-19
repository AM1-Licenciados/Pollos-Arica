
class Pedido {
  final String id;
  final String codigo;
  final String clienteId;
  final String nombreCliente;
  final String celularCliente;
  final String estado;
  final String metodoPago;
  final String estadoPago;
  final String tipoEntrega;
  final String momentoPreparacion;
  final bool clienteLlego;
  final double subtotal;
  final double total;
  final String? observaciones;
  final DateTime? createdAt;
  final List<DetallePedido> detalles;

  const Pedido({
    required this.id,
    required this.codigo,
    required this.clienteId,
    required this.nombreCliente,
    required this.celularCliente,
    required this.estado,
    required this.metodoPago,
    required this.estadoPago,
    required this.tipoEntrega,
    required this.momentoPreparacion,
    required this.clienteLlego,
    required this.subtotal,
    required this.total,
    required this.observaciones,
    required this.createdAt,
    required this.detalles,
  });

  factory Pedido.fromMap(
    Map<String, dynamic> map, {
    Map<String, dynamic>? cliente,
    List<DetallePedido> detalles = const [],
  }) {
    return Pedido(
      id: map['id'].toString(),
      codigo: map['codigo']?.toString() ?? '',
      clienteId: map['cliente_id']?.toString() ?? '',
      nombreCliente: cliente?['nombre']?.toString() ?? 'Cliente',
      celularCliente: cliente?['celular']?.toString() ?? '',
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
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      detalles: detalles,
    );
  }
}

class DetallePedido {
  final String id;
  final String nombreProducto;
  final String nombreVariante;
  final String seccion;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DetallePedido({
    required this.id,
    required this.nombreProducto,
    required this.nombreVariante,
    required this.seccion,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetallePedido.fromMap(Map<String, dynamic> map) {
    return DetallePedido(
      id: map['id'].toString(),
      nombreProducto: map['nombre_producto']?.toString() ?? 'Producto',
      nombreVariante: map['nombre_variante']?.toString() ?? '',
      seccion: map['seccion']?.toString() ?? '',
      cantidad: (map['cantidad'] as num?)?.toInt() ?? 0,
      precioUnitario:
          (map['precio_unitario'] as num?)?.toDouble() ?? 0,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PedidoEstados {
  static const List<String> pedido = [
    'pendiente',
    'aceptado',
    'en_preparacion',
    'listo',
    'entregado',
    'rechazado',
    'cancelado',
  ];

  static const List<String> pago = [
    'pendiente',
    'por_verificar',
    'pagado',
    'rechazado',
  ];

  static String etiqueta(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aceptado':
        return 'Aceptado';
      case 'en_preparacion':
        return 'En preparación';
      case 'listo':
        return 'Listo';
      case 'entregado':
        return 'Entregado';
      case 'rechazado':
        return 'Rechazado';
      case 'cancelado':
        return 'Cancelado';
      case 'por_verificar':
        return 'Por verificar';
      case 'pagado':
        return 'Pagado';
      default:
        return estado;
    }
  }
}
