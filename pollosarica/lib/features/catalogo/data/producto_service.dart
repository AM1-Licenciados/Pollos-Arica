
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/producto.dart';

class ProductoService {
  final SupabaseClient _supabase;

  ProductoService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  static const String _seleccion = '''
    id,
    categoria_id,
    nombre,
    seccion,
    descripcion,
    ingredientes,
    imagen_url,
    disponible,
    activo,
    orden,
    variantes_producto (
      id,
      producto_id,
      nombre,
      precio,
      es_predeterminada,
      activa,
      orden,
      descripcion,
      ingredientes,
      imagen_url,
      disponible
    )
  ''';

  Future<List<Producto>> obtenerProductos() async {
    final respuesta = await _supabase
        .from('productos')
        .select(_seleccion)
        .eq('activo', true)
        .order('orden');

    return respuesta
        .map((registro) => Producto.fromMap(registro))
        .toList();
  }

  Future<List<Producto>> obtenerProductosPorCategoria(
    String categoriaId,
  ) async {
    final respuesta = await _supabase
        .from('productos')
        .select(_seleccion)
        .eq('categoria_id', categoriaId)
        .eq('activo', true)
        .order('orden');

    return respuesta
        .map((registro) => Producto.fromMap(registro))
        .toList();
  }
}
