import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../carrito/data/pedido_service.dart';
import '../models/pedido_cliente.dart';
import '../services/mis_pedidos_service.dart';

class MisPedidosScreen extends StatefulWidget {
  const MisPedidosScreen({super.key});

  @override
  State<MisPedidosScreen> createState() => _MisPedidosScreenState();
}

class _MisPedidosScreenState extends State<MisPedidosScreen> {
  late Future<List<PedidoCliente>> _pedidosFuture;
  String _filtroSeleccionado = 'Todos';
  final Set<String> _pedidosNotificandoPago = {};
  final Set<String> _pedidosSubiendoComprobante = {};
  final Map<String, Future<bool>> _comprobantesFuture = {};

  Future<bool> _comprobanteExiste(PedidoCliente pedido) {
    return _comprobantesFuture.putIfAbsent(
      pedido.id,
      () => PedidoService.instance.tieneComprobanteQr(pedido.id),
    );
  }

  Future<void> _subirComprobanteDesdeHistorial(PedidoCliente pedido) async {
    if (_pedidosSubiendoComprobante.contains(pedido.id)) return;

    try {
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (archivo == null || !mounted) return;

      setState(() => _pedidosSubiendoComprobante.add(pedido.id));

      await PedidoService.instance.subirComprobanteQr(
        pedidoId: pedido.id,
        archivo: archivo,
      );

      if (!mounted) return;

      setState(() {
        _comprobantesFuture[pedido.id] = Future<bool>.value(true);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comprobante adjuntado correctamente.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } finally {
      if (mounted) {
        setState(() => _pedidosSubiendoComprobante.remove(pedido.id));
      }
    }
  }

  void _reintentarComprobante(PedidoCliente pedido) {
    setState(() {
      _comprobantesFuture.remove(pedido.id);
    });
  }

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

  Future<void> _notificarPagoDesdeHistorial(PedidoCliente pedido) async {
    if (_pedidosNotificandoPago.contains(pedido.id)) return;

    setState(() => _pedidosNotificandoPago.add(pedido.id));

    try {
      await PedidoService.instance.notificarPagoQr(pedido.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Avisamos al personal. Tu pago está pendiente de verificación.',
          ),
        ),
      );

      // La notificación ya fue guardada. Si falla la recarga, no debemos
      // informar al cliente que el pago no se notificó.
      try {
        await _actualizarPedidos();
      } catch (_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El pago fue notificado, pero no pudimos actualizar la lista. '
              'Desliza hacia abajo para volver a cargarla.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } finally {
      if (mounted) {
        setState(() => _pedidosNotificandoPago.remove(pedido.id));
      }
    }
  }

  bool _estaEnCurso(PedidoCliente pedido) {
    return {
      PedidoEstadosCliente.pendiente,
      PedidoEstadosCliente.aceptado,
      PedidoEstadosCliente.enPreparacion,
      PedidoEstadosCliente.listo,
    }.contains(pedido.estado);
  }

  List<PedidoCliente> _filtrarPedidos(List<PedidoCliente> pedidos) {
    if (_filtroSeleccionado == 'En curso') {
      return pedidos.where(_estaEnCurso).toList();
    }
    return pedidos;
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
        toolbarHeight: 48,
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
          final pedidosFiltrados = _filtrarPedidos(pedidos);

          return RefreshIndicator(
            color: AppTheme.naranja,
            onRefresh: _actualizarPedidos,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _construirFiltros(pedidos.length),
                  ),
                ),
                if (pedidos.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _construirVacio(),
                  )
                else if (pedidosFiltrados.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _construirVacioEnCurso(),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 15, 16, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _construirTarjeta(pedidosFiltrados[index]),
                        childCount: pedidosFiltrados.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _construirFiltros(int cantidadTotal) {
    return Row(
      children: [
        _construirOpcionFiltro('Todos', cantidadTotal),
        const SizedBox(width: 9),
        _construirOpcionFiltro('En curso', null),
      ],
    );
  }

  Widget _construirOpcionFiltro(String etiqueta, int? cantidad) {
    final seleccionado = _filtroSeleccionado == etiqueta;

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () {
        setState(() {
          _filtroSeleccionado = etiqueta;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: seleccionado ? AppTheme.naranja : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: seleccionado
                ? AppTheme.naranja
                : const Color(0xFFE8D8C8),
          ),
          boxShadow: seleccionado
              ? [
                  BoxShadow(
                    color: AppTheme.naranja.withValues(alpha: 0.16),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etiqueta,
              style: TextStyle(
                color: seleccionado ? Colors.white : AppTheme.marron,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (cantidad != null) ...[
              const SizedBox(width: 7),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: seleccionado
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppTheme.crema,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    color: seleccionado ? Colors.white : AppTheme.naranja,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _construirVacioEnCurso() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7D0),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              size: 42,
              color: AppTheme.naranja,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No tienes pedidos en curso',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.marron,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cuando realices un pedido, podrás seguir su preparación desde aquí.',
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
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFF0E6DD)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.marron.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 17),
        iconColor: AppTheme.naranja,
        collapsedIconColor: AppTheme.textoSecundario,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9D6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_rounded,
                color: AppTheme.naranja,
                size: 20,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PEDIDO',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pedido.codigo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.marron,
                    ),
                  ),
                ],
              ),
            ),
            _construirEtiquetaEstado(
              PedidoEstadosCliente.etiqueta(pedido.estado),
              colorEstado,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 50, top: 7, right: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 12,
                          color: AppTheme.textoSecundario,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            _formatearFecha(pedido.createdAt),
                            style: const TextStyle(
                              color: AppTheme.textoSecundario,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${pedido.cantidadProductos} ${pedido.cantidadProductos == 1 ? 'producto' : 'productos'}',
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.naranja,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        children: [
          const Divider(height: 18, color: Color(0xFFF1E7DF)),
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
          if (pedido.metodoPago == 'qr' &&
              pedido.estadoPago == 'pendiente' &&
              !{
                PedidoEstadosCliente.rechazado,
                PedidoEstadosCliente.cancelado,
              }.contains(pedido.estado)) ...[
            const SizedBox(height: 14),
            FutureBuilder<bool>(
              future: _comprobanteExiste(pedido),
              builder: (context, comprobanteSnapshot) {
                if (comprobanteSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.naranja,
                        ),
                      ),
                    ),
                  );
                }

                if (comprobanteSnapshot.hasError) {
                  return Column(
                    children: [
                      const Text(
                        'No pudimos comprobar si adjuntaste el comprobante.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _reintentarComprobante(pedido),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  );
                }

                final comprobanteSubido =
                    comprobanteSnapshot.data == true;
                final subiendo =
                    _pedidosSubiendoComprobante.contains(pedido.id);
                final notificando =
                    _pedidosNotificandoPago.contains(pedido.id);

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.crema.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE8D8C8),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            comprobanteSubido
                                ? Icons.check_circle_rounded
                                : Icons.receipt_long_outlined,
                            color: comprobanteSubido
                                ? const Color(0xFF2E9D63)
                                : AppTheme.naranja,
                            size: 21,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              comprobanteSubido
                                  ? 'Comprobante adjuntado'
                                  : 'Completa tu pago',
                              style: const TextStyle(
                                color: AppTheme.marron,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        comprobanteSubido
                            ? 'Ahora puedes avisar al personal que realizaste la transferencia.'
                            : 'Primero adjunta una imagen de tu comprobante para continuar.',
                        style: const TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 11),
                      OutlinedButton.icon(
                        onPressed: subiendo || notificando
                            ? null
                            : () => _subirComprobanteDesdeHistorial(pedido),
                        icon: subiendo
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                comprobanteSubido
                                    ? Icons.edit_outlined
                                    : Icons.upload_file_rounded,
                              ),
                        label: Text(
                          subiendo
                              ? 'Subiendo comprobante...'
                              : comprobanteSubido
                                  ? 'Cambiar comprobante'
                                  : 'Subir comprobante',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.naranja,
                          side: const BorderSide(color: AppTheme.naranja),
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: !comprobanteSubido ||
                                  subiendo ||
                                  notificando
                              ? null
                              : () => _notificarPagoDesdeHistorial(pedido),
                          icon: notificando
                              ? const SizedBox(
                                  width: 17,
                                  height: 17,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                          label: const Text('Ya realicé el pago'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (pedido.metodoPago == 'qr' &&
              pedido.estadoPago == 'por_verificar') ...[
            const SizedBox(height: 10),
            const Text(
              'Tu pago fue notificado y está pendiente de verificación.',
              style: TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 12,
              ),
            ),
          ],
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