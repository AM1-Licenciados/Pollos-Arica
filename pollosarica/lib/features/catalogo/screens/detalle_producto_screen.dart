
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../carrito/data/carrito_service.dart';
import '../models/producto.dart';
import '../models/variante_producto.dart';

class DetalleProductoScreen extends StatefulWidget {
  final Producto producto;

  const DetalleProductoScreen({
    super.key,
    required this.producto,
  });

  @override
  State<DetalleProductoScreen> createState() =>
      _DetalleProductoScreenState();
}

class _DetalleProductoScreenState extends State<DetalleProductoScreen> {
  VarianteProducto? _varianteSeleccionada;
  int _cantidad = 2;
  bool _esFavorito = false;

  List<VarianteProducto> get _variantes {
    final resultado = widget.producto.variantes
        .where((variante) => variante.activa)
        .toList();

    resultado.sort((a, b) => a.orden.compareTo(b.orden));
    return resultado;
  }

  @override
  void initState() {
    super.initState();

    if (_variantes.isNotEmpty) {
      _varianteSeleccionada = _variantes.firstWhere(
        (variante) => variante.esPredeterminada,
        orElse: () => _variantes.first,
      );
    }
  }

  double get _precioUnitario =>
      _varianteSeleccionada?.precio ?? 0;

  double get _total => _precioUnitario * _cantidad;

  bool get _disponible {
    return widget.producto.disponible &&
        _varianteSeleccionada != null &&
        _varianteSeleccionada!.disponible &&
        _varianteSeleccionada!.activa;
  }

  String get _ingredientesTexto {
    final producto = widget.producto.ingredientes?.trim();
    final variante = _varianteSeleccionada?.ingredientes?.trim();

    if (variante != null && variante.isNotEmpty) {
      return variante;
    }

    if (producto != null && producto.isNotEmpty) {
      return producto;
    }

    return '';
  }

  List<String> get _ingredientes {
    if (_ingredientesTexto.isEmpty) return [];

    return _ingredientesTexto
        .split(RegExp(r'[,;\n]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _emojiIngrediente(String ingrediente) {
    final texto = ingrediente.toLowerCase();

    if (texto.contains('carne') ||
        texto.contains('milanesa')) {
      return '🥩';
    }
    if (texto.contains('pollo crispy')) return '🍗';
    if (texto.contains('pollo')) return '🍗';
    if (texto.contains('queso') ||
        texto.contains('mozzarella')) {
      return '🧀';
    }
    if (texto.contains('tomate')) return '🍅';
    if (texto.contains('lechuga')) return '🥬';
    if (texto.contains('pepino') ||
        texto.contains('pepinillo')) {
      return '🥒';
    }
    if (texto.contains('cebolla')) return '🧅';
    if (texto.contains('pan')) return '🍞';
    if (texto.contains('tocino')) return '🥓';
    if (texto.contains('huevo')) return '🍳';
    if (texto.contains('arroz')) return '🍚';
    if (texto.contains('papa')) return '🍟';
    if (texto.contains('piña')) return '🍍';
    if (texto.contains('champi')) return '🍄';
    if (texto.contains('choclo') ||
        texto.contains('maíz')) {
      return '🌽';
    }
    if (texto.contains('jamón')) return '🥓';
    if (texto.contains('salsa')) return '🥫';
    if (texto.contains('mantequilla')) return '🧈';

    return '🍽️';
  }

  String _nombreCategoria() {
    final seccion = widget.producto.seccion?.trim();

    if (seccion != null && seccion.isNotEmpty) {
      return seccion;
    }

    return 'Nuestro menú';
  }

  void _cambiarCantidad(int cambio) {
    final nuevaCantidad = _cantidad + cambio;

    if (nuevaCantidad < 1 || nuevaCantidad > 20) return;

    setState(() {
      _cantidad = nuevaCantidad;
    });
  }

  void _agregarAlCarrito() {
    if (!_disponible) return;

    final variante = _varianteSeleccionada;

    if (variante == null) return;

    CarritoService.instance.agregarProducto(
      producto: widget.producto,
      variante: variante,
      cantidad: _cantidad,
    );

    Navigator.of(context).pop(true);
  }

  Widget _construirImagenPlaceholder() {
    return Container(
      color: const Color(0xFFFFF3E8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        size: 85,
        color: AppTheme.naranja,
      ),
    );
  }

  // Fotografía completa en un fondo beige uniforme, sin duplicarla ni desenfocarla.
  Widget _construirImagen() {
    final url = widget.producto.imagenUrl;

    if (url == null || url.trim().isEmpty) {
      return _construirImagenPlaceholder();
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8E5D0),
      alignment: Alignment.center,
      child: Image.network(
        url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _construirImagenPlaceholder();
        },
      ),
    );
  }

  Widget _botonSuperior({
    required IconData icono,
    required VoidCallback onPressed,
    Color color = AppTheme.marron,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            icono,
            color: color,
            size: 21,
          ),
        ),
      ),
    );
  }

  Widget _construirEncabezadoImagen() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: AspectRatio(
            aspectRatio: 3 / 2,
            child: _construirImagen(),
          ),
        ),
        Positioned(
          top: 15,
          left: 15,
          child: _botonSuperior(
            icono: Icons.arrow_back_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        Positioned(
          top: 15,
          right: 15,
          child: _botonSuperior(
            icono: _esFavorito
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: AppTheme.naranja,
            onPressed: () {
              setState(() {
                _esFavorito = !_esFavorito;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _construirBarraSuperior() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          const SizedBox(width: 42),
          const Expanded(
            child: Center(
              child: Text(
                'Detalle del menú',
                style: TextStyle(
                  color: AppTheme.marron,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _construirSelectorCantidad() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _botonCantidad(
          icono: Icons.remove,
          habilitado: _cantidad > 1,
          onPressed: () => _cambiarCantidad(-1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Text(
            '$_cantidad',
            style: const TextStyle(
              color: AppTheme.marron,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _botonCantidad(
          icono: Icons.add,
          habilitado: _cantidad < 20,
          onPressed: () => _cambiarCantidad(1),
        ),
      ],
    );
  }

  Widget _botonCantidad({
    required IconData icono,
    required bool habilitado,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: habilitado ? onPressed : null,
        child: SizedBox(
          width: 25,
          height: 30,
          child: Icon(
            icono,
            size: 17,
            color: habilitado
                ? AppTheme.marron
                : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _construirInformacionProducto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE7D0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _nombreCategoria(),
            style: const TextStyle(
              color: AppTheme.naranja,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                widget.producto.nombre,
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _construirSelectorCantidad(),
          ],
        ),
      ],
    );
  }

  Widget _construirTituloSeccion(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        color: AppTheme.marron,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _construirIngredientes() {
    final ingredientes = _ingredientes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirTituloSeccion('Ingredientes'),
        const SizedBox(height: 13),
        if (ingredientes.isEmpty)
          const Text(
            'Los ingredientes todavía no están configurados.',
            style: TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 13,
            ),
          )
        else
          SizedBox(
            height: 91,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ingredientes.length,
              separatorBuilder: (context, index) {
                return const SizedBox(width: 17);
              },
              itemBuilder: (context, index) {
                final ingrediente = ingredientes[index];

                return SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E8),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _emojiIngrediente(ingrediente),
                          style: const TextStyle(fontSize: 25),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        ingrediente,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.marron,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _construirDescripcion() {
    final descripcion = widget.producto.descripcion?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _construirTituloSeccion('Descripción'),
        const SizedBox(height: 9),
        Text(
          descripcion != null && descripcion.isNotEmpty
              ? descripcion
              : 'La descripción de este producto todavía no ha sido agregada.',
          style: TextStyle(
            color: descripcion != null && descripcion.isNotEmpty
                ? AppTheme.textoSecundario
                : Colors.grey.shade500,
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _construirPrecio() {
    if (_variantes.isEmpty) {
      return const Text(
        'Precio por confirmar',
        style: TextStyle(
          color: AppTheme.textoSecundario,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Total',
          style: TextStyle(
            color: AppTheme.textoSecundario,
            fontSize: 11,
          ),
        ),
        Text(
          'Bs ${_total.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppTheme.marron,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _construirBotonCarrito() {
    final puedeAgregar = _disponible;

    String textoBoton;

    if (!widget.producto.disponible) {
      textoBoton = 'Producto no disponible';
    } else if (_variantes.isEmpty) {
      textoBoton = 'Precio por confirmar';
    } else if (_varianteSeleccionada == null) {
      textoBoton = 'Sin presentación disponible';
    } else if (!_varianteSeleccionada!.disponible) {
      textoBoton = 'Agotado';
    } else {
      textoBoton = 'Agregar al carrito';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 13, 20, 15),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 15,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 53,
                child: ElevatedButton(
                  onPressed: puedeAgregar
                      ? _agregarAlCarrito
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.naranja,
                    disabledBackgroundColor:
                        Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          textoBoton,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 17),
            _construirPrecio(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF8),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      12,
                      18,
                      25,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _construirBarraSuperior(),
                          _construirEncabezadoImagen(),
                          const SizedBox(height: 19),
                          _construirInformacionProducto(),
                          const SizedBox(height: 25),
                          _construirIngredientes(),
                          const SizedBox(height: 22),
                          _construirDescripcion(),
                          if (!_disponible) ...[
                            const SizedBox(height: 15),
                            const Text(
                              'Este producto no está disponible actualmente.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _construirBotonCarrito(),
          ],
        ),
      ),
    );
  }
}
