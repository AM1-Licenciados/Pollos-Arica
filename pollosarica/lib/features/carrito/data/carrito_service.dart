import 'package:flutter/foundation.dart';

import '../../catalogo/models/producto.dart';
import '../../catalogo/models/variante_producto.dart';

class CarritoItem {
  final Producto producto;
  final VarianteProducto variante;
  int cantidad;

  CarritoItem({
    required this.producto,
    required this.variante,
    this.cantidad = 1,
  });

  double get subtotal => variante.precio * cantidad;
}

class CarritoService extends ChangeNotifier {
  CarritoService._();

  static final CarritoService instance = CarritoService._();

  final List<CarritoItem> _items = [];

  List<CarritoItem> get items => List.unmodifiable(_items);

  int get cantidadTotal {
    return _items.fold(
      0,
      (total, item) => total + item.cantidad,
    );
  }

  double get total {
    return _items.fold(
      0,
      (suma, item) => suma + item.subtotal,
    );
  }

  void agregarProducto({
    required Producto producto,
    required VarianteProducto variante,
    required int cantidad,
  }) {
    if (cantidad <= 0 || !producto.disponible ||
        !variante.disponible || !variante.activa) {
      return;
    }

    final indice = _items.indexWhere(
      (item) =>
          item.producto.id == producto.id &&
          item.variante.id == variante.id,
    );

    if (indice != -1) {
      _items[indice].cantidad += cantidad;
    } else {
      _items.add(
        CarritoItem(
          producto: producto,
          variante: variante,
          cantidad: cantidad,
        ),
      );
    }

    notifyListeners();
  }

  void cambiarCantidad(int indice, int cantidad) {
    if (indice < 0 || indice >= _items.length) return;

    if (cantidad <= 0) {
      eliminarProducto(indice);
      return;
    }

    _items[indice].cantidad = cantidad;
    notifyListeners();
  }

  void eliminarProducto(int indice) {
    if (indice < 0 || indice >= _items.length) return;

    _items.removeAt(indice);
    notifyListeners();
  }

  void vaciar() {
    _items.clear();
    notifyListeners();
  }
}
