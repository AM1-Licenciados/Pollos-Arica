
import 'package:flutter/material.dart';

import '../../cliente/screens/perfil_cliente_screen.dart';

import '../../../core/theme/app_theme.dart';
import '../data/categoria_service.dart';
import '../data/producto_service.dart';
import '../models/categoria.dart';
import '../models/producto.dart';
import '../../carrito/screens/carrito_screen.dart';
import '../../cliente/services/autenticacion_service.dart';
import '../../cliente/screens/autenticacion_screen.dart';
import '../../pedidos/screens/mis_pedidos_screen.dart';
import 'detalle_producto_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  State<CatalogoScreen> createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  final CategoriaService _categoriaService = CategoriaService();
  final ProductoService _productoService = ProductoService();
  final TextEditingController _busquedaController =
      TextEditingController();

  late Future<_DatosCatalogo> _datosFuture;

  String? _categoriaSeleccionada;
  String _busqueda = '';
  int _paginaSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _datosFuture = _cargarCatalogo();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<_DatosCatalogo> _cargarCatalogo() async {
    final resultados = await Future.wait([
      _categoriaService.obtenerCategorias(),
      _productoService.obtenerProductos(),
    ]);

    return _DatosCatalogo(
      categorias: resultados[0] as List<Categoria>,
      productos: resultados[1] as List<Producto>,
    );
  }

  Future<void> _recargarCatalogo() async {
    setState(() {
      _datosFuture = _cargarCatalogo();
    });

    await _datosFuture;
  }

  List<Producto> _filtrarProductos(
    List<Producto> productos,
    List<Categoria> categorias,
  ) {
    final consulta = _busqueda.toLowerCase().trim();

    return productos.where((producto) {
      final coincideCategoria =
          _categoriaSeleccionada == null ||
          producto.categoriaId == _categoriaSeleccionada;

      final categoria = categorias.where(
        (item) => item.id == producto.categoriaId,
      );

      final nombreCategoria =
          categoria.isNotEmpty ? categoria.first.nombre : '';

      final coincideBusqueda = consulta.isEmpty ||
          producto.nombre.toLowerCase().contains(consulta) ||
          nombreCategoria.toLowerCase().contains(consulta) ||
          (producto.seccion ?? '').toLowerCase().contains(consulta);

      return coincideCategoria && coincideBusqueda;
    }).toList();
  }

  double? _precioDesde(Producto producto) {
    final variantes = producto.variantes
        .where((variante) => variante.activa)
        .toList();

    if (variantes.isEmpty) return null;

    final precios = variantes
        .map((variante) => variante.precio)
        .toList();

    precios.sort();

    return precios.first;
  }

  Future<void> _abrirDetalle(Producto producto) async {
    final agregado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => DetalleProductoScreen(
          producto: producto,
        ),
      ),
    );

    if (!mounted) return;

    if (agregado == true) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Producto agregado al carrito.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  bool _tieneSecciones(String nombreCategoria) {
    final nombre = nombreCategoria.toLowerCase().trim();

    return nombre == 'hamburguesas' || nombre == 'milanesas';
  }

  List<_GrupoProductos> _crearGrupos(
    List<Producto> productos,
    List<Categoria> categorias,
  ) {
    final grupos = <_GrupoProductos>[];

    final categoriasOrdenadas = [...categorias]
      ..sort((a, b) => a.orden.compareTo(b.orden));

    for (final categoria in categoriasOrdenadas) {
      final productosCategoria = productos
          .where((producto) => producto.categoriaId == categoria.id)
          .toList()
        ..sort((a, b) => a.orden.compareTo(b.orden));

      if (productosCategoria.isEmpty) continue;

      if (_tieneSecciones(categoria.nombre)) {
        for (final seccion in ['Carne', 'Pollo']) {
          final productosSeccion = productosCategoria
              .where(
                (producto) =>
                    (producto.seccion ?? '').toLowerCase().trim() ==
                    seccion.toLowerCase(),
              )
              .toList();

          if (productosSeccion.isNotEmpty) {
            grupos.add(
              _GrupoProductos(
                titulo: seccion,
                subtitulo: categoria.nombre,
                productos: productosSeccion,
              ),
            );
          }
        }

        final sinSeccion = productosCategoria
            .where(
              (producto) =>
                  (producto.seccion ?? '').trim().isEmpty ||
                  !['carne', 'pollo'].contains(
                    producto.seccion!.toLowerCase().trim(),
                  ),
            )
            .toList();

        if (sinSeccion.isNotEmpty) {
          grupos.add(
            _GrupoProductos(
              titulo: categoria.nombre,
              productos: sinSeccion,
            ),
          );
        }
      } else {
        grupos.add(
          _GrupoProductos(
            titulo: categoria.nombre,
            productos: productosCategoria,
          ),
        );
      }
    }

    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DatosCatalogo>(
      future: _datosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.naranja,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 54,
                      color: AppTheme.naranja,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No pudimos cargar el menú',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.marron,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprueba tu conexión e intenta nuevamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _recargarCatalogo,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final datos = snapshot.data!;
        final productos = _filtrarProductos(
          datos.productos,
          datos.categorias,
        );

        return Scaffold(
          backgroundColor: AppTheme.crema,
          body: SafeArea(
            bottom: false,
            child: _paginaSeleccionada == 0
                ? _construirInicio(datos, productos)
                : _construirPaginaSecundaria(),
          ),
          bottomNavigationBar: _construirNavegacion(),
        );
      },
    );
  }

  Widget _construirInicio(
    _DatosCatalogo datos,
    List<Producto> productos,
  ) {
    final grupos = _crearGrupos(productos, datos.categorias);

    return RefreshIndicator(
      color: AppTheme.naranja,
      onRefresh: _recargarCatalogo,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: _construirEncabezado(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _construirPromocion(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
              child: _construirBuscador(),
            ),
          ),
          SliverToBoxAdapter(
            child: _construirCategorias(datos.categorias),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nuestro menú',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.marron,
                    ),
                  ),
                  Text(
                    '${productos.length} productos',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (productos.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text(
                    'No encontramos productos para tu búsqueda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _construirGrupo(grupos[index]);
                },
                childCount: grupos.length,
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 24),
          ),
        ],
      ),
    );
  }

  Widget _construirGrupo(_GrupoProductos grupo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppTheme.naranja,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  grupo.titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.marron,
                  ),
                ),
                if (grupo.subtitulo != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    grupo.subtitulo!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;
              final columnas = ancho >= 850
                  ? 4
                  : ancho >= 550
                      ? 3
                      : 2;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: grupo.productos.length,
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columnas,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 245,
                  ),
                  itemBuilder: (context, index) {
                    final producto = grupo.productos[index];

                    return _construirTarjetaProducto(
                      producto,
                      _precioDesde(producto),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _abrirCarrito() async {
    if (!AutenticacionService.instance.estaAutenticado) {
      final resultado = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => const AutenticacionScreen(),
        ),
      );

      if (resultado != true ||
          !AutenticacionService.instance.estaAutenticado ||
          !mounted) {
        return;
      }
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CarritoScreen(),
      ),
    );
  }

  Widget _construirEncabezado() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Hola! Bienvenido a',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textoSecundario,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Pollos Arica',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.marron,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Con el sazón de la casa',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: IconButton(
            onPressed: _abrirCarrito,
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: AppTheme.marron,
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirPromocion() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            AppTheme.naranja,
            AppTheme.naranjaClaro,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Bienvenido!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Algo delicioso\nte está esperando',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Descubre nuestro menú',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.restaurant_rounded,
            color: Colors.white,
            size: 66,
          ),
        ],
      ),
    );
  }

  Widget _construirBuscador() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: _busquedaController,
        onChanged: (valor) {
          setState(() {
            _busqueda = valor;
          });
        },
        decoration: InputDecoration(
          hintText: 'Buscar hamburguesas, milanesas...',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: AppTheme.naranja,
          ),
          suffixIcon: _busqueda.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _busquedaController.clear();
                    setState(() {
                      _busqueda = '';
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _construirCategorias(List<Categoria> categorias) {
    return SizedBox(
      height: 43,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _construirFiltroCategoria(
            nombre: 'Todos',
            seleccionado: _categoriaSeleccionada == null,
            onTap: () {
              setState(() {
                _categoriaSeleccionada = null;
              });
            },
          ),
          ...categorias.map(
            (categoria) => _construirFiltroCategoria(
              nombre: categoria.nombre,
              seleccionado: _categoriaSeleccionada == categoria.id,
              onTap: () {
                setState(() {
                  _categoriaSeleccionada = categoria.id;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirFiltroCategoria({
    required String nombre,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: Material(
        color: seleccionado ? AppTheme.naranja : Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 17,
              vertical: 10,
            ),
            child: Text(
              nombre,
              style: TextStyle(
                color: seleccionado
                    ? Colors.white
                    : AppTheme.textoSecundario,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirTarjetaProducto(
    Producto producto,
    double? precio,
  ) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalle(producto),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _construirImagen(producto.imagenUrl),
                  if (!producto.disponible)
                    Container(
                      color: Colors.black.withValues(alpha: 0.45),
                      alignment: Alignment.center,
                      child: const Text(
                        'No disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.marron,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          precio == null
                              ? 'Precio por confirmar'
                              : 'Bs ${precio.toStringAsFixed(0)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.naranja,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.add_circle,
                        color: AppTheme.naranja,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirImagen(String? url) {
    if (url == null || url.trim().isEmpty) {
      return _imagenPlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _imagenPlaceholder();
      },
    );
  }

  Widget _imagenPlaceholder() {
    return Container(
      color: const Color(0xFFFFE7D0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.fastfood_rounded,
        size: 54,
        color: AppTheme.naranja,
      ),
    );
  }

  Widget _construirPaginaSecundaria() {
    if (_paginaSeleccionada == 1) {
      return const MisPedidosScreen();
    }

    return PerfilClienteScreen(
      onCerrarSesion: () {
        if (!mounted) return;
        setState(() => _paginaSeleccionada = 0);
      },
    );
  }

  Widget _construirNavegacion() {
    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: AppTheme.naranja.withValues(alpha: 0.13),
      selectedIndex: _paginaSeleccionada,
      onDestinationSelected: (index) {
        setState(() {
          _paginaSeleccionada = index;
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(
            Icons.home_rounded,
            color: AppTheme.naranja,
          ),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(
            Icons.receipt_long_rounded,
            color: AppTheme.naranja,
          ),
          label: 'Mis pedidos',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(
            Icons.person_rounded,
            color: AppTheme.naranja,
          ),
          label: 'Perfil',
        ),
      ],
    );
  }
}

class _DatosCatalogo {
  final List<Categoria> categorias;
  final List<Producto> productos;

  const _DatosCatalogo({
    required this.categorias,
    required this.productos,
  });
}

class _GrupoProductos {
  final String titulo;
  final String? subtitulo;
  final List<Producto> productos;

  const _GrupoProductos({
    required this.titulo,
    this.subtitulo,
    required this.productos,
  });
}
