import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/productos_admin_service.dart';

class ProductosAdminScreen extends StatefulWidget {
  const ProductosAdminScreen({super.key});

  @override
  State<ProductosAdminScreen> createState() => _ProductosAdminScreenState();
}

class _ProductosAdminScreenState extends State<ProductosAdminScreen> {
  final _busquedaController = TextEditingController();
  final Map<String, TextEditingController> _precios = {};
  final Set<String> _guardando = {};

  List<ProductoPrecioAdmin> _productos = [];
  bool _cargando = true;
  String? _error;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    for (final controller in _precios.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final productos =
          await ProductosAdminService.instance.obtenerProductos();
      if (!mounted) return;

      for (final controller in _precios.values) {
        controller.dispose();
      }
      _precios.clear();

      for (final producto in productos) {
        for (final variante in producto.variantes) {
          _precios[variante.id] = TextEditingController(
            text: variante.precio.toStringAsFixed(2),
          );
        }
      }

      setState(() => _productos = productos);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardarPrecio(VariantePrecioAdmin variante) async {
    if (_guardando.contains(variante.id)) return;

    final controller = _precios[variante.id];
    final texto = controller?.text.trim().replaceAll(',', '.') ?? '';
    final precio = double.tryParse(texto);

    if (precio == null || !precio.isFinite || precio <= 0 || precio > 100000) {
      _mensaje('Escribe un precio válido mayor que 0.', error: true);
      return;
    }

    setState(() => _guardando.add(variante.id));

    try {
      await ProductosAdminService.instance.actualizarPrecio(
        varianteId: variante.id,
        precio: precio,
      );

      if (!mounted) return;
      controller?.text = precio.toStringAsFixed(2);
      _mensaje('Precio actualizado: Bs \${precio.toStringAsFixed(2)}');
    } catch (error) {
      if (!mounted) return;
      _mensaje(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _guardando.remove(variante.id));
    }
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  List<ProductoPrecioAdmin> get _productosFiltrados {
    final consulta = _busqueda.trim().toLowerCase();
    if (consulta.isEmpty) return _productos;
    return _productos
        .where((producto) => producto.nombre.toLowerCase().contains(consulta))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.naranja),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final productos = _productosFiltrados;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Productos y precios',
                          style: TextStyle(
                            color: AppTheme.marron,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Edita los precios que aparecen en el catálogo de clientes.',
                          style: TextStyle(color: AppTheme.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar lista',
                    onPressed: _cargar,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _busquedaController,
                onChanged: (value) => setState(() => _busqueda = value),
                decoration: InputDecoration(
                  hintText: 'Buscar plato o producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _busqueda.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar',
                          onPressed: () {
                            _busquedaController.clear();
                            setState(() => _busqueda = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              if (productos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borde),
                  ),
                  child: const Text(
                    'No se encontraron productos con esa búsqueda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textoSecundario),
                  ),
                )
              else
                ...productos.map(_tarjetaProducto),
              const SizedBox(height: 18),
              const Text(
                'Los cambios se guardan en Supabase y se reflejan en el catálogo. '
                'Los pedidos ya registrados conservan el precio con el que fueron creados.',
                style: TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaProducto(ProductoPrecioAdmin producto) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.naranja.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppTheme.naranja,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  producto.nombre,
                  style: const TextStyle(
                    color: AppTheme.marron,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '\${producto.variantes.length} precio(s)',
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (producto.variantes.isEmpty)
            const Text(
              'Este producto no tiene variantes registradas.',
              style: TextStyle(color: AppTheme.textoSecundario),
            )
          else
            ...producto.variantes.map(_filaVariante),
        ],
      ),
    );
  }

  Widget _filaVariante(VariantePrecioAdmin variante) {
    final controller = _precios[variante.id];
    final guardando = _guardando.contains(variante.id);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 500;
          final nombre = Text(
            variante.nombre,
            style: TextStyle(
              color: variante.activa
                  ? AppTheme.marron
                  : AppTheme.textoSecundario,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          );
          final campo = SizedBox(
            width: compacto ? double.infinity : 150,
            child: TextField(
              controller: controller,
              enabled: !guardando,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: compacto ? TextAlign.start : TextAlign.end,
              decoration: const InputDecoration(
                prefixText: 'Bs ',
                isDense: true,
              ),
              onSubmitted: (_) => _guardarPrecio(variante),
            ),
          );
          final boton = SizedBox(
            height: 45,
            child: FilledButton.icon(
              onPressed: guardando ? null : () => _guardarPrecio(variante),
              icon: guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 17),
              label: Text(guardando ? 'Guardando' : 'Guardar'),
            ),
          );

          if (compacto) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(alignment: Alignment.centerLeft, child: nombre),
                const SizedBox(height: 8),
                campo,
                const SizedBox(height: 8),
                boton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: nombre),
              const SizedBox(width: 12),
              campo,
              const SizedBox(width: 10),
              boton,
            ],
          );
        },
      ),
    );
  }
}
