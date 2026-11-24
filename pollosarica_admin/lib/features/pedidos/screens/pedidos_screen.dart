
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/pedido.dart';
import '../services/pedido_admin_service.dart';
import '../widgets/pedido_card.dart';
import '../widgets/pedido_detalle_dialog.dart';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  final _servicio = PedidoAdminService.instance;
  final _busquedaController = TextEditingController();

  List<Pedido> _pedidos = [];
  bool _cargando = true;
  String? _error;
  String _filtroEstado = 'todos';

  @override
  void initState() {
    super.initState();
    _cargarPedidos();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargarPedidos() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _servicio.obtenerPedidos();

      if (!mounted) return;

      setState(() {
        _pedidos = resultado;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  List<Pedido> get _pedidosFiltrados {
    final busqueda = _busquedaController.text.trim().toLowerCase();

    return _pedidos.where((pedido) {
      final coincideEstado =
          _filtroEstado == 'todos' || pedido.estado == _filtroEstado;

      final coincideBusqueda = busqueda.isEmpty ||
          pedido.codigo.toLowerCase().contains(busqueda) ||
          pedido.nombreCliente.toLowerCase().contains(busqueda) ||
          pedido.celularCliente.toLowerCase().contains(busqueda);

      return coincideEstado && coincideBusqueda;
    }).toList();
  }

  int _contarEstado(String estado) {
    return _pedidos.where((pedido) => pedido.estado == estado).length;
  }

  void _mostrarDetalle(Pedido pedido) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return PedidoDetalleDialog(
          pedido: pedido,
          onActualizarEstado: (estado) async {
            await _servicio.actualizarEstado(pedido.id, estado);
            await _cargarPedidos();
          },
          onActualizarPago: (estado) async {
            await _servicio.actualizarEstadoPago(pedido.id, estado);
            await _cargarPedidos();
          },
        );
      },
    );
  }

  // INDICADORES COMPACTOS CON FONDOS PASTEL

  Widget _construirIndicador(
    String titulo,
    int cantidad,
    Color color,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withValues(alpha: 0.13),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icono,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cantidad.toString(),
                  style: const TextStyle(
                    color: AppTheme.marron,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirIndicadores() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 850
            ? 4
            : constraints.maxWidth >= 500
                ? 2
                : 1;

        final proporcion = columnas == 4
            ? 3.5
            : columnas == 2
                ? 3.0
                : 4.0;

        return GridView.count(
          crossAxisCount: columnas,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: proporcion,
          children: [
            _construirIndicador(
              'Pendientes',
              _contarEstado('pendiente'),
              const Color(0xFFF59E0B),
              Icons.schedule,
            ),
            _construirIndicador(
              'En preparación',
              _contarEstado('en_preparacion'),
              const Color(0xFF8E65C5),
              Icons.soup_kitchen_outlined,
            ),
            _construirIndicador(
              'Listos',
              _contarEstado('listo'),
              const Color(0xFF26A69A),
              Icons.check_circle_outline,
            ),
            _construirIndicador(
              'Entregados',
              _contarEstado('entregado'),
              const Color(0xFF66A56B),
              Icons.task_alt,
            ),
          ],
        );
      },
    );
  }

  // BUSCADOR Y FILTROS

  Widget _construirBuscador() {
    return TextField(
      controller: _busquedaController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Buscar por código, cliente o celular...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _busquedaController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _busquedaController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
      ),
    );
  }

  Widget _construirFiltroEstado() {
    return DropdownButtonFormField<String>(
      initialValue: _filtroEstado,
      decoration: const InputDecoration(
        labelText: 'Filtrar por estado',
        prefixIcon: Icon(Icons.filter_list),
      ),
      items: [
        const DropdownMenuItem(
          value: 'todos',
          child: Text('Todos los pedidos'),
        ),
        ...PedidoEstados.pedido.map(
          (estado) => DropdownMenuItem(
            value: estado,
            child: Text(PedidoEstados.etiqueta(estado)),
          ),
        ),
      ],
      onChanged: (valor) {
        if (valor != null) {
          setState(() => _filtroEstado = valor);
        }
      },
    );
  }

  Widget _construirFiltros() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 650) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _construirBuscador(),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: _construirFiltroEstado(),
              ),
            ],
          );
        }

        return Column(
          children: [
            _construirBuscador(),
            const SizedBox(height: 12),
            _construirFiltroEstado(),
          ],
        );
      },
    );
  }

  // LISTADO DE PEDIDOS

  Widget _construirListado() {
    if (_cargando) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            color: AppTheme.naranja,
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 45,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudieron cargar los pedidos',
                style: TextStyle(
                  color: AppTheme.marron,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarPedidos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final pedidos = _pedidosFiltrados;

    if (pedidos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: AppTheme.naranja,
                size: 55,
              ),
              const SizedBox(height: 14),
              const Text(
                'No hay pedidos para mostrar',
                style: TextStyle(
                  color: AppTheme.marron,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Prueba cambiando los filtros o realiza una nueva búsqueda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = constraints.maxWidth >= 1050
            ? 3
            : constraints.maxWidth >= 650
                ? 2
                : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pedidos.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnas,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            mainAxisExtent: 260,
          ),
          itemBuilder: (context, index) {
            final pedido = pedidos[index];

            return PedidoCard(
              pedido: pedido,
              onTap: () => _mostrarDetalle(pedido),
            );
          },
        );
      },
    );
  }

  // PANTALLA PRINCIPAL

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.naranja,
      onRefresh: _cargarPedidos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de pedidos',
              style: TextStyle(
                color: AppTheme.marron,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Consulta y administra los pedidos de Pollos Arica.',
              style: TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),

            _construirIndicadores(),

            const SizedBox(height: 23),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pedidos registrados',
                    style: TextStyle(
                      color: AppTheme.marron,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar pedidos',
                  onPressed: _cargando ? null : _cargarPedidos,
                  icon: const Icon(
                    Icons.refresh,
                    color: AppTheme.naranja,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _construirFiltros(),

            const SizedBox(height: 18),

            _construirListado(),
          ],
        ),
      ),
    );
  }
}
