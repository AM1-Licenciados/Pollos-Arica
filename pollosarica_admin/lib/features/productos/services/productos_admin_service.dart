import 'package:supabase_flutter/supabase_flutter.dart';

class VariantePrecioAdmin {
  final String id;
  final String nombre;
  final double precio;
  final bool activa;
  final int orden;

  const VariantePrecioAdmin({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.activa,
    required this.orden,
  });

  factory VariantePrecioAdmin.fromMap(Map<String, dynamic> map) {
    return VariantePrecioAdmin(
      id: map['id'].toString(),
      nombre: map['nombre']?.toString() ?? 'Presentación',
      precio: (map['precio'] as num).toDouble(),
      activa: map['activa'] as bool? ?? true,
      orden: (map['orden'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductoPrecioAdmin {
  final String id;
  final String nombre;
  final int orden;
  final List<VariantePrecioAdmin> variantes;

  const ProductoPrecioAdmin({
    required this.id,
    required this.nombre,
    required this.orden,
    required this.variantes,
  });

  factory ProductoPrecioAdmin.fromMap(Map<String, dynamic> map) {
    final variantesRaw = map['variantes_producto'] as List<dynamic>? ?? [];
    final variantes = variantesRaw
        .map((item) => VariantePrecioAdmin.fromMap(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));

    return ProductoPrecioAdmin(
      id: map['id'].toString(),
      nombre: map['nombre']?.toString() ?? 'Producto',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      variantes: variantes,
    );
  }
}

class ProductosAdminService {
  ProductosAdminService._();

  static final ProductosAdminService instance = ProductosAdminService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<ProductoPrecioAdmin>> obtenerProductos() async {
    final respuesta = await _supabase
        .from('productos')
        .select(
          'id, nombre, orden, variantes_producto '
          '(id, nombre, precio, activa, orden)',
        )
        .eq('activo', true)
        .order('orden');

    return respuesta
        .map((registro) => ProductoPrecioAdmin.fromMap(registro))
        .toList();
  }

  Future<void> actualizarPrecio({
    required String varianteId,
    required double precio,
  }) async {
    if (!precio.isFinite || precio <= 0 || precio > 100000) {
      throw Exception('Introduce un precio mayor que 0 y menor que 100000.');
    }

    final respuesta = await _supabase
        .from('variantes_producto')
        .update({'precio': precio})
        .eq('id', varianteId)
        .select('id');

    if (respuesta.isEmpty) {
      throw Exception(
        'No se pudo guardar el precio. Comprueba que tu usuario sea '
        'administrador activo y que la variante siga disponible.',
      );
    }
  }
}
