
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _estado = widget.pedido.estado;
    _estadoPago = widget.pedido.estadoPago;
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

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final pedido = widget.pedido;

    return Dialog(
      backgroundColor: const Color(0xFFFFF5E9),
      insetPadding: const EdgeInsets.all(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650, maxHeight: 750),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle del pedido',
                          style: TextStyle(
                            color: AppTheme.marron,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pedido.codigo,
                          style: const TextStyle(
                            color: AppTheme.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                    const SizedBox(height: 22),

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
                    const SizedBox(height: 22),

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
                    const SizedBox(height: 22),

                    _seccionTitulo('Pago'),
                    _dato(
                      'Método',
                      pedido.metodoPago.toUpperCase(),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: PedidoEstados.pago.contains(_estadoPago)
                          ? _estadoPago
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Estado del pago',
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
                    const SizedBox(height: 22),

                    _seccionTitulo('Estado del pedido'),
                    DropdownButtonFormField<String>(
                      initialValue: PedidoEstados.pedido.contains(_estado)
                          ? _estado
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Actualizar estado',
                      ),
                      items: PedidoEstados.pedido.map((estado) {
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
                    const SizedBox(height: 22),

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

  Widget _seccionTitulo(String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        titulo,
        style: const TextStyle(
          color: AppTheme.marron,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
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
