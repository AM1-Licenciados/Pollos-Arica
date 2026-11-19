
import 'variante_producto.dart';

class Producto {
  final String id;
  final String categoriaId;
  final String nombre;
  final String? seccion;
  final String? descripcion;
  final String? ingredientes;
  final String? imagenUrl;
  final bool disponible;
  final bool activo;
  final int orden;
  final List<VarianteProducto> variantes;

  const Producto({
    required this.id,
    required this.categoriaId,
    required this.nombre,
    this.seccion,
    this.descripcion,
    this.ingredientes,
    this.imagenUrl,
    required this.disponible,
    required this.activo,
    required this.orden,
    this.variantes = const [],
  });

  factory Producto.fromMap(Map<String, dynamic> map) {
    final variantesMap =
        map['variantes_producto'] as List<dynamic>? ?? [];

    return Producto(
      id: map['id'] as String,
      categoriaId: map['categoria_id'] as String,
      nombre: map['nombre'] as String,
      seccion: map['seccion'] as String?,
      descripcion: map['descripcion'] as String?,
      ingredientes: map['ingredientes'] as String?,
      imagenUrl: map['imagen_url'] as String?,
      disponible: map['disponible'] as bool? ?? true,
      activo: map['activo'] as bool? ?? true,
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      variantes: variantesMap
          .map(
            (variante) => VarianteProducto.fromMap(
              variante as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}
