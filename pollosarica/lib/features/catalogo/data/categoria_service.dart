
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/categoria.dart';

class CategoriaService {
  final SupabaseClient _supabase;

  CategoriaService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  Future<List<Categoria>> obtenerCategorias() async {
    final respuesta = await _supabase
        .from('categorias')
        .select('id, nombre, descripcion, orden')
        .eq('activo', true)
        .order('orden');

    return respuesta
        .map((registro) => Categoria.fromMap(registro))
        .toList();
  }
}
