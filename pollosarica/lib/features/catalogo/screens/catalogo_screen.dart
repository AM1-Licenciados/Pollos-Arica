
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt_result;
import 'package:speech_to_text/speech_to_text.dart' as stt;

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
  final stt.SpeechToText _reconocimientoVoz = stt.SpeechToText();

  bool _vozDisponible = false;
  bool _escuchando = false;
  String? _localeVoz;
  String? _mensajeVoz;

  late Future<_DatosCatalogo> _datosFuture;

  String? _categoriaSeleccionada;
  String _busqueda = '';
  int _paginaSeleccionada = 0;

  @override
  void initState() {
    super.initState();
    _datosFuture = _cargarCatalogo();
    _inicializarReconocimientoVoz();
  }

  @override
  void dispose() {
    _reconocimientoVoz.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _inicializarReconocimientoVoz() async {
    try {
      final disponible = await _reconocimientoVoz.initialize(
        onStatus: (estado) {
          if (!mounted) return;

          setState(() {
            _escuchando = estado == 'listening';
          });
        },
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _escuchando = false;
            _mensajeVoz =
                'No se pudo reconocer la voz. Revisa el micrófono e intenta nuevamente.';
          });
        },
      );

      if (!mounted) return;

      String? localeEspanol;

      if (disponible) {
        final locales = await _reconocimientoVoz.locales();
        final localesEspanol = locales.where((locale) {
          final codigo = locale.localeId.toLowerCase().replaceAll('-', '_');
          return codigo.startsWith('es_') || codigo == 'es';
        }).toList();

        for (final locale in localesEspanol) {
          final codigo = locale.localeId.toLowerCase().replaceAll('-', '_');
          if (codigo == 'es_bo') {
            localeEspanol = locale.localeId;
            break;
          }
        }

        localeEspanol ??= localesEspanol.isNotEmpty
            ? localesEspanol.first.localeId
            : null;
      }

      setState(() {
        _vozDisponible = disponible;
        _localeVoz = localeEspanol;
        _mensajeVoz = disponible
            ? null
            : 'La búsqueda por voz no está disponible en este navegador o dispositivo.';
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _vozDisponible = false;
        _escuchando = false;
        _mensajeVoz = 'No se pudo iniciar el reconocimiento de voz.';
      });
    }
  }

  String _normalizarTexto(String texto) {
    return texto
        .toLowerCase()
        .trim()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n');
  }

  Future<void> _alternarReconocimientoVoz() async {
    if (!_vozDisponible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La búsqueda por voz no está disponible en este dispositivo.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_reconocimientoVoz.isListening) {
      await _reconocimientoVoz.stop();
      if (!mounted) return;
      setState(() => _escuchando = false);
      return;
    }

    setState(() {
      _mensajeVoz = null;
      _busquedaController.clear();
      _busqueda = '';
      _escuchando = true;
    });

    try {
      await _reconocimientoVoz.listen(
        onResult: _alRecibirResultadoVoz,
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeVoz,
          pauseFor: const Duration(seconds: 2),
          listenFor: const Duration(seconds: 15),
          partialResults: true,
          cancelOnError: true,
        ),
      );

      if (!mounted) return;
      setState(() {
        _escuchando = _reconocimientoVoz.isListening;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _escuchando = false;
        _mensajeVoz = 'No se pudo activar el micrófono. Comprueba los permisos.';
      });
    }
  }

  void _alRecibirResultadoVoz(stt_result.SpeechRecognitionResult resultado) {
    if (!mounted) return;

    final textoReconocido = resultado.recognizedWords;

    setState(() {
      _busquedaController.value = TextEditingValue(
        text: textoReconocido,
        selection: TextSelection.collapsed(offset: textoReconocido.length),
      );
      _busqueda = textoReconocido;
      _mensajeVoz = null;

      if (resultado.finalResult) {
        _escuchando = false;
      }
    });

    // Un resultado final significa que la frase terminó.
    // La pausa configurada también detiene sesiones sin resultado final inmediato.
    if (resultado.finalResult) {
      unawaited(_reconocimientoVoz.stop());
    }
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
    final consulta = _normalizarTexto(_busqueda);

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
          _normalizarTexto(producto.nombre).contains(consulta) ||
          _normalizarTexto(nombreCategoria).contains(consulta) ||
          _normalizarTexto(producto.seccion ?? '').contains(consulta);

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
          extendBody: true,
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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: _construirEncabezado(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _construirBuscador(),
            ),
          ),
          SliverToBoxAdapter(
            child: _construirCategorias(datos.categorias),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
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
            child: SizedBox(height: 112),
          ),
        ],
      ),
    );
  }

  Widget _construirGrupo(_GrupoProductos grupo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 9),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ancho = constraints.maxWidth;
                final columnas = ancho >= 850
                    ? 4
                    : ancho >= 550
                        ? 3
                        : 2;

                const espacio = 12.0;
                final anchoTarjeta =
                    (ancho - espacio * (columnas - 1)) / columnas;

                return Wrap(
                  spacing: espacio,
                  runSpacing: 12,
                  children: grupo.productos.map((producto) {
                    return SizedBox(
                      width: anchoTarjeta,
                      child: _construirTarjetaProducto(
                        producto,
                        _precioDesde(producto),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
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
              Image.asset(
                'assets/images/logo_pollos_arica.png',
                width: 172,
                height: 48,
                alignment: Alignment.centerLeft,
                fit: BoxFit.contain,
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


  Widget _construirBuscador() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
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
              suffixIcon: SizedBox(
                width: 96,
                height: 52,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (_busqueda.isNotEmpty)
                      IconButton(
                        tooltip: 'Limpiar búsqueda',
                        constraints: const BoxConstraints.tightFor(
                          width: 40,
                          height: 48,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          _busquedaController.clear();
                          setState(() {
                            _busqueda = '';
                          });
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppTheme.textoSecundario,
                          size: 20,
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                    IconButton(
                      tooltip: _escuchando
                          ? 'Detener búsqueda por voz'
                          : 'Buscar por voz',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _vozDisponible
                          ? _alternarReconocimientoVoz
                          : null,
                      icon: Icon(
                        _escuchando
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        color: _escuchando
                            ? Colors.red
                            : _vozDisponible
                                ? AppTheme.naranja
                                : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              suffixIconConstraints: const BoxConstraints.tightFor(
                width: 96,
                height: 52,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        if (_escuchando || _mensajeVoz != null) ...[
          const SizedBox(height: 7),
          Text(
            _escuchando
                ? 'Escuchando... di el nombre de un producto'
                : _mensajeVoz!,
            style: TextStyle(
              color: _escuchando ? AppTheme.naranja : AppTheme.textoSecundario,
              fontSize: 11,
              fontWeight: _escuchando ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ],
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
            AspectRatio(
              aspectRatio: 1.25,
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
      width: double.infinity,
      height: double.infinity,
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
    final destinos = [
      (
        icono: Icons.home_outlined,
        iconoSeleccionado: Icons.home_rounded,
        etiqueta: 'Inicio',
      ),
      (
        icono: Icons.receipt_long_outlined,
        iconoSeleccionado: Icons.receipt_long_rounded,
        etiqueta: 'Mis pedidos',
      ),
      (
        icono: Icons.person_outline_rounded,
        iconoSeleccionado: Icons.person_rounded,
        etiqueta: 'Perfil',
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 8),
        child: SizedBox(
          height: 62,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.marron.withValues(alpha: 0.14),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                children: List.generate(destinos.length, (index) {
                  final destino = destinos[index];
                  final seleccionado = _paginaSeleccionada == index;

                  return Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(26),
                        onTap: () {
                          setState(() {
                            _paginaSeleccionada = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          decoration: BoxDecoration(
                            color: seleccionado
                                ? AppTheme.naranja.withValues(alpha: 0.10)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                seleccionado
                                    ? destino.iconoSeleccionado
                                    : destino.icono,
                                size: 22,
                                color: seleccionado
                                    ? AppTheme.naranja
                                    : AppTheme.textoSecundario,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                destino.etiqueta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  height: 1.1,
                                  fontWeight: seleccionado
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: seleccionado
                                      ? AppTheme.naranja
                                      : AppTheme.textoSecundario,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
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
