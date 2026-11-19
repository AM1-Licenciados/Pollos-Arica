
class Categoria {
  final String id;
  final String nombre;
  final String? descripcion;
  final int orden;

  const Categoria({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.orden,
  });

  factory Categoria.fromMap(Map<String, dynamic> map) {
    return Categoria(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      descripcion: map['descripcion'] as String?,
      orden: (map['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'orden': orden,
    };
  }
}
