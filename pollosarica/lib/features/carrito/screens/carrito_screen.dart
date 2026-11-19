import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/carrito_service.dart';
import 'confirmar_pedido_screen.dart';

class CarritoScreen extends StatelessWidget {
  const CarritoScreen({super.key});

  String _formatearPrecio(double precio) {
    final entero = precio == precio.roundToDouble();
    return entero
        ? 'Bs ${precio.toStringAsFixed(0)}'
        : 'Bs ${precio.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final carrito = CarritoService.instance;

    return AnimatedBuilder(
      animation: carrito,
      builder: (context, _) {
        final items = carrito.items;

        return Scaffold(
          backgroundColor: AppTheme.crema,
          appBar: AppBar(
            backgroundColor: AppTheme.crema,
            foregroundColor: AppTheme.marron,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Mi carrito',
              style: TextStyle(
                color: AppTheme.marron,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: items.isEmpty
              ? _construirCarritoVacio(context)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _TarjetaCarrito(
                            nombre: item.producto.nombre,
                            seccion: item.producto.seccion,
                            variante: item.variante.nombre,
                            imagenUrl: item.variante.imagenUrl ??
                                item.producto.imagenUrl,
                            precio: item.variante.precio,
                            cantidad: item.cantidad,
                            subtotal: item.subtotal,
                            onDisminuir: () => carrito.cambiarCantidad(
                              index,
                              item.cantidad - 1,
                            ),
                            onAumentar: () => carrito.cambiarCantidad(
                              index,
                              item.cantidad + 1,
                            ),
                            onEliminar: () =>
                                _confirmarEliminar(context, carrito, index),
                          );
                        },
                      ),
                    ),
                    _ResumenCarrito(
                      cantidad: carrito.cantidadTotal,
                      total: carrito.total,
                      formatearPrecio: _formatearPrecio,
                      onContinuar: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ConfirmarPedidoScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _construirCarritoVacio(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppTheme.naranja.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppTheme.naranja,
                size: 52,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Tu carrito está vacío',
              style: TextStyle(
                color: AppTheme.marron,
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Agrega tus favoritos del menú y aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: const Text('Explorar menú'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    CarritoService carrito,
    int index,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Eliminar producto'),
        content: const Text(
          '¿Quieres quitar este producto de tu carrito?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.naranja),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true && index < carrito.items.length) {
      carrito.eliminarProducto(index);
    }
  }
}

class _TarjetaCarrito extends StatelessWidget {
  final String nombre;
  final String? seccion;
  final String variante;
  final String? imagenUrl;
  final double precio;
  final int cantidad;
  final double subtotal;
  final VoidCallback onDisminuir;
  final VoidCallback onAumentar;
  final VoidCallback onEliminar;

  const _TarjetaCarrito({
    required this.nombre,
    required this.seccion,
    required this.variante,
    required this.imagenUrl,
    required this.precio,
    required this.cantidad,
    required this.subtotal,
    required this.onDisminuir,
    required this.onAumentar,
    required this.onEliminar,
  });

  String _precio(double valor) {
    return valor == valor.roundToDouble()
        ? 'Bs ${valor.toStringAsFixed(0)}'
        : 'Bs ${valor.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final detalle = [
      if (seccion != null && seccion!.trim().isNotEmpty) seccion!,
      if (variante.trim().isNotEmpty && variante.toLowerCase() != 'única')
        variante,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Container(
              width: 94,
              height: 94,
              color: AppTheme.crema,
              child: imagenUrl == null || imagenUrl!.isEmpty
                  ? const Icon(
                      Icons.restaurant_rounded,
                      color: AppTheme.naranja,
                      size: 34,
                    )
                  : Image.network(
                      imagenUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.restaurant_rounded,
                        color: AppTheme.naranja,
                        size: 34,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.marron,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onEliminar,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.textoSecundario,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                if (detalle.isNotEmpty) ...[
                  Text(
                    detalle,
                    style: const TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  '${_precio(precio)} c/u',
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ControlCantidad(
                      icono: Icons.remove,
                      onTap: onDisminuir,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '$cantidad',
                        style: const TextStyle(
                          color: AppTheme.marron,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    _ControlCantidad(
                      icono: Icons.add,
                      onTap: onAumentar,
                    ),
                    const Spacer(),
                    Text(
                      _precio(subtotal),
                      style: const TextStyle(
                        color: AppTheme.naranja,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _ControlCantidad({
    required this.icono,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppTheme.crema,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icono,
          color: AppTheme.naranja,
          size: 17,
        ),
      ),
    );
  }
}

class _ResumenCarrito extends StatelessWidget {
  final int cantidad;
  final double total;
  final String Function(double) formatearPrecio;
  final VoidCallback onContinuar;

  const _ResumenCarrito({
    required this.cantidad,
    required this.total,
    required this.formatearPrecio,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Productos ($cantidad)',
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 14,
                  ),
                ),
                Text(
                  formatearPrecio(total),
                  style: const TextStyle(
                    color: AppTheme.marron,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: AppTheme.marron,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formatearPrecio(total),
                  style: const TextStyle(
                    color: AppTheme.naranja,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onContinuar,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Continuar con el pedido',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
