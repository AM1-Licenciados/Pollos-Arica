class VarianteProducto {
  final String id;
  final String productoId;
  final String nombre;
  final double precio;
  final bool esPredeterminada;
  final bool activa;
  final int orden;
  final String? descripcion;
  final String? ingredientes;
  final String? imagenUrl;
  final bool disponible;

  const VarianteProducto({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.esPredeterminada,
    required this.activa,
    required this.orden,
    this.descripcion,
    this.ingredientes,
    this.imagenUrl,
    this.disponible = true,
  });

  factory VarianteProducto.fromMap(Map<String, dynamic> map) {
    return VarianteProducto(
      id: map['id'] as String,
      productoId: map['producto_id'] as String,
      nombre: map['nombre'] as String,
      precio: (map['precio'] as num).toDouble(),
      esPredeterminada: map['es_predeterminada'] as bool? ?? false,
      activa: map['activa'] as bool? ?? true,
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      descripcion: map['descripcion'] as String?,
      ingredientes: map['ingredientes'] as String?,
      imagenUrl: map['imagen_url'] as String?,
      disponible: map['disponible'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'nombre': nombre,
      'precio': precio,
      'es_predeterminada': esPredeterminada,
      'activa': activa,
      'orden': orden,
      'descripcion': descripcion,
      'ingredientes': ingredientes,
      'imagen_url': imagenUrl,
      'disponible': disponible,
    };
  }
}
