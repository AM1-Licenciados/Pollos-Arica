import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/pedido_cliente.dart';
import '../services/mis_pedidos_service.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  late Future<List<PedidoCliente>> _pedidosFuture;

  @override
  void initState() {
    super.initState();
    _pedidosFuture = _cargarPedidos();
  }

  Future<List<PedidoCliente>> _cargarPedidos() {
    return MisPedidosService.instance.obtenerMisPedidos();
  }

  Future<void> _actualizarPedidos() async {
    final nuevoFuture = _cargarPedidos();

    setState(() {
      _pedidosFuture = nuevoFuture;
    });

    await nuevoFuture;
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case PedidoEstadosCliente.pendiente:
        return const Color(0xFFFFA726);
      case PedidoEstadosCliente.aceptado:
        return const Color(0xFF42A5F5);
      case PedidoEstadosCliente.enPreparacion:
        return const Color(0xFFAB7BD5);
      case PedidoEstadosCliente.listo:
        return const Color(0xFF26A69A);
      case PedidoEstadosCliente.entregado:
        return const Color(0xFF66BB6A);
      case PedidoEstadosCliente.rechazado:
      case PedidoEstadosCliente.cancelado:
        return const Color(0xFFE57373);
      default:
        return AppTheme.textoSecundario;
    }
  }

  String _formatearFecha(DateTime fecha) {
    final local = fecha.toLocal();

    final dia = local.day.toString().padLeft(2, '0');
    final mes = local.month.toString().padLeft(2, '0');
    final anio = local.year;

    final hora = local.hour.toString().padLeft(2, '0');
    final minuto = local.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio • $hora:$minuto';
  }

  String _metodoPago(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return 'Efectivo';
      case 'qr':
        return 'Pago por QR';
      default:
        return metodo;
    }
  }

  String _tipoEntrega(String tipo) {
    switch (tipo) {
      case 'retiro':
        return 'Retiro en local';
      case 'consumo_local':
        return 'Consumo en local';
      default:
        return tipo;
    }
  }

  Color _colorPago(String estado) {
    switch (estado) {
      case 'pagado':
        return const Color(0xFF2E9D63);
      case 'por_verificar':
        return const Color(0xFF4285C5);
      case 'rechazado':
        return const Color(0xFFD9534F);
      default:
        return const Color(0xFFB7791F);
    }
  }

  String _etiquetaPago(String estado) {
    switch (estado) {
      case 'pagado':
        return 'Pagado';
      case 'por_verificar':
        return 'Por verificar';
      case 'rechazado':
        return 'Pago rechazado';
      default:
        return 'Pago pendiente';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.crema,
        elevation: 0,
        title: const Text(
          'Mis pedidos',
          style: TextStyle(
            color: AppTheme.marron,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar pedidos',
            onPressed: _actualizarPedidos,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.marron,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<PedidoCliente>>(
        future: _pedidosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.naranja,
              ),
            );
          }

          if (snapshot.hasError) {
            return _construirError();
          }

          final pedidos = snapshot.data ?? [];

          if (pedidos.isEmpty) {
            return _construirVacio();
          }

          return RefreshIndicator(
            color: AppTheme.naranja,
            onRefresh: _actualizarPedidos,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: pedidos.length,
              itemBuilder: (context, index) {
                return _construirTarjeta(pedidos[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _construirError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.naranja,
              size: 55,
            ),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar tus pedidos',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.marron,
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _actualizarPedidos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirVacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE7D0),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppTheme.naranja,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Todavía no tienes pedidos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.marron,
              ),
            ),
            const SizedBox(height: 9),
            const Text(
              'Cuando realices tu primer pedido, podrás consultar aquí su estado y todos sus detalles.',
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.5,
                color: AppTheme.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirTarjeta(PedidoCliente pedido) {
    final colorEstado = _colorEstado(pedido.estado);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppTheme.naranja,
        collapsedIconColor: AppTheme.textoSecundario,
        title: Row(
          children: [
            Expanded(
              child: Text(
                pedido.codigo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.marron,
                ),
              ),
            ),
            _construirEtiquetaEstado(
              PedidoEstadosCliente.etiqueta(pedido.estado),
              colorEstado,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatearFecha(pedido.createdAt),
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${pedido.cantidadProductos} productos',
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(2)}',
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
        children: [
          const Divider(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Detalle del pedido',
              style: const TextStyle(
                color: AppTheme.marron,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...pedido.detalles.map(_construirDetalle),
          const Divider(height: 24),
          _construirDato(
            'Tipo de entrega',
            _tipoEntrega(pedido.tipoEntrega),
          ),
          _construirDato(
            'Método de pago',
            _metodoPago(pedido.metodoPago),
          ),
          _construirDato(
            'Estado del pago',
            _etiquetaPago(pedido.estadoPago),
            color: _colorPago(pedido.estadoPago),
          ),
          _construirDato(
            'Subtotal',
            'Bs ${pedido.subtotal.toStringAsFixed(2)}',
          ),
          _construirDato(
            'Total',
            'Bs ${pedido.total.toStringAsFixed(2)}',
            destacado: true,
          ),
          if (pedido.observaciones != null &&
              pedido.observaciones!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Observaciones',
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                pedido.observaciones!,
                style: const TextStyle(
                  color: AppTheme.textoSecundario,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _construirDetalle(PedidoDetalleCliente detalle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7D0),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              '${detalle.cantidad}',
              style: const TextStyle(
                color: AppTheme.naranja,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detalle.nombreProducto,
                  style: const TextStyle(
                    color: AppTheme.marron,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detalle.nombreVariante.isNotEmpty)
                  Text(
                    detalle.nombreVariante,
                    style: const TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Bs ${detalle.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.marron,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirDato(
    String etiqueta,
    String valor, {
    Color? color,
    bool destacado = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: color ??
                  (destacado ? AppTheme.naranja : AppTheme.marron),
              fontSize: destacado ? 15 : 13,
              fontWeight:
                  destacado ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEtiquetaEstado(String texto, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}