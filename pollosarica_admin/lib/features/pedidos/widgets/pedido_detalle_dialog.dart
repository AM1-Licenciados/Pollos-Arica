
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../models/pedido.dart';

class PedidoDetalleDialog extends StatefulWidget {
  final Pedido pedido;
  final Future<void> Function(String) onActualizarEstado;
  final Future<void> Function(String) onActualizarPago;

  const PedidoDetalleDialog({
    super.key,
    required this.pedido,
    required this.onActualizarEstado,
    required this.onActualizarPago,
  });

  @override
  State<PedidoDetalleDialog> createState() =>
      _PedidoDetalleDialogState();
}

class _PedidoDetalleDialogState extends State<PedidoDetalleDialog> {
  late String _estado;
  late String _estadoPago;

  bool _guardandoEstado = false;
  bool _guardandoPago = false;
  late Future<String?> _urlComprobante;

  @override
  void initState() {
    super.initState();
    _estado = widget.pedido.estado;
    _estadoPago = widget.pedido.estadoPago;
    _urlComprobante = _obtenerUrlComprobante();
  }


  Future<String?> _obtenerUrlComprobante() async {
    final pedido = widget.pedido;
    if (pedido.metodoPago != 'qr' || pedido.authUserId.isEmpty) return null;
    final ruta = '${pedido.authUserId}/${pedido.id}/comprobante';
    try {
      return await Supabase.instance.client.storage
          .from('comprobantes-pago')
          .createSignedUrl(ruta, 300);
    } catch (_) {
      return null;
    }
  }

  Widget _comprobanteQr() {
    return FutureBuilder<String?>(
      future: _urlComprobante,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final url = snapshot.data;
        if (url == null || url.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'El cliente todavía no adjuntó un comprobante.',
              style: TextStyle(color: AppTheme.textoSecundario, fontSize: 12),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('Comprobante de pago',
                style: TextStyle(color: AppTheme.marron,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(url, fit: BoxFit.contain),
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  height: 190,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No se pudo cargar la imagen del comprobante.'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Toca la imagen para ampliarla.',
              style: TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Future<void> _guardarEstado(String? valor) async {
    if (valor == null || valor == _estado) return;

    setState(() => _guardandoEstado = true);

    try {
      await widget.onActualizarEstado(valor);

      if (!mounted) return;

      setState(() => _estado = valor);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado del pedido actualizado.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardandoEstado = false);
      }
    }
  }

  Future<void> _guardarPago(String? valor) async {
    if (valor == null || valor == _estadoPago) return;

    setState(() => _guardandoPago = true);

    try {
      await widget.onActualizarPago(valor);

      if (!mounted) return;

      setState(() => _estadoPago = valor);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Estado del pago actualizado.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _guardandoPago = false);
      }
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no disponible';

    final local = fecha.toLocal();

    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${dosDigitos(local.day)}/${dosDigitos(local.month)}/${local.year} '
        '${dosDigitos(local.hour)}:${dosDigitos(local.minute)}';
  }

  List<String> get _estadosPagoDisponibles {
    final metodo = widget.pedido.metodoPago;
    
    if (metodo == 'qr') {
      if (_estadoPago == 'por_verificar') {
        return const ['por_verificar', 'pagado', 'rechazado'];
      }
      return [_estadoPago];
    }

    if (metodo == 'efectivo') {
      if (_estadoPago == 'pendiente') {
        return const ['pendiente', 'pagado'];
      }
      return [_estadoPago];
    }

    return [_estadoPago];
  }

  String? get _ayudaEstadoPago {
    if (widget.pedido.metodoPago == 'qr' && _estadoPago == 'pendiente') {
      return 'El cliente todavía no notificó el pago. '
          'Cuando lo haga, podrás verificarlo aquí.';
    }

    if (widget.pedido.metodoPago == 'qr' &&
        _estadoPago == 'por_verificar') {
      return 'Verifica el movimiento en la banca del negocio antes de confirmar.';
    }

    if (widget.pedido.metodoPago == 'qr' && _estadoPago == 'rechazado') {
      return 'El pago fue rechazado. No avances con la preparación del pedido.';
    }

    return null;
  }

  List<String> get _estadosPedidoDisponibles {
    if (widget.pedido.metodoPago != 'qr' || _estadoPago == 'pagado') {
      return PedidoEstados.pedido;
    }

    final permitidos = _estadoPago == 'rechazado'
        ? <String>['rechazado', 'cancelado']
        : <String>['pendiente', 'aceptado', 'rechazado', 'cancelado'];

    // Mantener visible el estado actual si es un pedido histórico
    // que ya estaba en una etapa operativa antes de aplicar la regla QR.
    if (!permitidos.contains(_estado)) {
      return [_estado, ...permitidos];
    }

    return permitidos;
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.borde),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(26, 22, 14, 19),
              decoration: const BoxDecoration(
                color: Color(0xFFFFFAF5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE9D6),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: AppTheme.naranja, size: 21),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detalle del pedido',
                            style: TextStyle(color: AppTheme.marron,
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(pedido.codigo,
                            style: const TextStyle(color: AppTheme.textoSecundario,
                                fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textoSecundario,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 19),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borde),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 22, 26, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _seccionTitulo('Información del cliente'),
                    _dato('Nombre', pedido.nombreCliente),
                    _dato(
                      'Celular',
                      pedido.celularCliente.isEmpty
                          ? 'No disponible'
                          : pedido.celularCliente,
                    ),
                    _dato('Fecha', _formatearFecha(pedido.createdAt)),
                    _separadorSeccion(),

                    _seccionTitulo('Productos'),
                    if (pedido.detalles.isEmpty)
                      const Text('No se encontraron detalles.')
                    else
                      ...pedido.detalles.map(
                        (detalle) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detalle.nombreProducto,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.marron,
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
                                    if (detalle.seccion.isNotEmpty)
                                      Text(
                                        detalle.seccion,
                                        style: const TextStyle(
                                          color: AppTheme.textoSecundario,
                                          fontSize: 11,
                                        ),
                                      ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${detalle.cantidad} × Bs ${detalle.precioUnitario.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppTheme.textoSecundario,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Bs ${detalle.subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: AppTheme.marron,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    _dato('Subtotal', 'Bs ${pedido.subtotal.toStringAsFixed(2)}'),
                    _dato('TOTAL', 'Bs ${pedido.total.toStringAsFixed(2)}'),
                    _separadorSeccion(),

                    _seccionTitulo('Entrega y preparación'),
                    _dato(
                      'Modalidad',
                      pedido.tipoEntrega == 'retiro'
                          ? 'Retiro en el local'
                          : 'Consumo en el local',
                    ),
                    if (pedido.tipoEntrega == 'consumo_local')
                      _dato(
                        'Preparación',
                        pedido.momentoPreparacion == 'al_llegar'
                            ? 'Al llegar el cliente'
                            : 'Inmediata',
                      ),
                    if (pedido.tipoEntrega == 'consumo_local')
                      _dato(
                        'Cliente llegó',
                        pedido.clienteLlego ? 'Sí' : 'No',
                      ),
                    _separadorSeccion(),

                    _seccionTitulo('Pago'),
                    _dato(
                      'Método',
                      pedido.metodoPago.toUpperCase(),
                    ),
                    if (pedido.metodoPago == 'qr') _comprobanteQr(),
                    DropdownButtonFormField<String>(
                      initialValue: PedidoEstados.pago.contains(_estadoPago)
                          ? _estadoPago
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Estado del pago',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      items: _estadosPagoDisponibles.map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Text(PedidoEstados.etiqueta(estado)),
                        );
                      }).toList(),
                      onChanged: _guardandoPago ? null : _guardarPago,
                    ),
                    if (_guardandoPago)
                      const LinearProgressIndicator(
                        color: AppTheme.naranja,
                      ),
                    if (_ayudaEstadoPago != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _ayudaEstadoPago!,
                        style: const TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    _separadorSeccion(),

                    _seccionTitulo('Estado del pedido'),
                    DropdownButtonFormField<String>(
                      initialValue: PedidoEstados.pedido.contains(_estado)
                          ? _estado
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Actualizar estado',
                        prefixIcon: Icon(Icons.sync_alt_rounded),
                      ),
                      items: _estadosPedidoDisponibles.map((estado) {
                        return DropdownMenuItem(
                          value: estado,
                          child: Text(PedidoEstados.etiqueta(estado)),
                        );
                      }).toList(),
                      onChanged: _guardandoEstado ? null : _guardarEstado,
                    ),
                    if (_guardandoEstado)
                      const LinearProgressIndicator(
                        color: AppTheme.naranja,
                      ),
                    _separadorSeccion(),

                    _seccionTitulo('Observaciones'),
                    Text(
                      pedido.observaciones?.isNotEmpty == true
                          ? pedido.observaciones!
                          : 'Sin observaciones.',
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _separadorSeccion() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppTheme.borde.withValues(alpha: 0.75),
      ),
    );
  }

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.naranja,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Text(titulo,
              style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 14,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _dato(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.textoSecundario,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                color: AppTheme.marron,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
