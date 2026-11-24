import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/pedido.dart';

class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback onTap;

  const PedidoCard({
    super.key,
    required this.pedido,
    required this.onTap,
  });

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFE59A22);
      case 'aceptado':
        return const Color(0xFF438CCB);
      case 'en_preparacion':
        return const Color(0xFF8B65C5);
      case 'listo':
        return const Color(0xFF229F91);
      case 'entregado':
        return const Color(0xFF579A65);
      case 'rechazado':
      case 'cancelado':
        return const Color(0xFFD65F5F);
      default:
        return AppTheme.textoSecundario;
    }
  }

  Color _colorEstadoPago() {
    switch (pedido.estadoPago) {
      case 'por_verificar':
        return const Color(0xFFB7791F);
      case 'pagado':
        return const Color(0xFF32866C);
      case 'rechazado':
        return const Color(0xFFD65F5F);
      default:
        return const Color(0xFF8A817B);
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no disponible';
    final local = fecha.toLocal();
    String d(int v) => v.toString().padLeft(2, '0');
    return '${d(local.day)}/${d(local.month)}/${local.year} ${d(local.hour)}:${d(local.minute)}';
  }

  String _etiquetaPago(String metodo) {
    switch (metodo.toLowerCase()) {
      case 'efectivo':
        return 'Efectivo';
      case 'qr':
        return 'Pago QR';
      default:
        return metodo.isEmpty ? 'No especificado' : metodo;
    }
  }

  IconData _iconoPago(String metodo) =>
      metodo.toLowerCase() == 'qr' ? Icons.qr_code_2_rounded : Icons.payments_outlined;

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(pedido.estado);
    final cantidad = pedido.detalles.fold<int>(0, (total, item) => total + item.cantidad);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borde),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF39271D).withValues(alpha: 0.035),
                blurRadius: 16,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pedido.codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.marron,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ChipEstado(
                    texto: PedidoEstados.etiqueta(pedido.estado),
                    color: color,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                pedido.nombreCliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (pedido.celularCliente.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  pedido.celularCliente,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 17),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      color: AppTheme.naranja, size: 16),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text('$cantidad productos',
                        style: const TextStyle(
                            color: AppTheme.textoSecundario, fontSize: 11)),
                  ),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.marron,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Divider(height: 22, color: AppTheme.borde),
              Row(
                children: [
                  Icon(
                    pedido.tipoEntrega == 'retiro'
                        ? Icons.storefront_outlined
                        : Icons.restaurant_outlined,
                    color: AppTheme.textoSecundario,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      pedido.tipoEntrega == 'retiro'
                          ? 'Retiro en local'
                          : 'Consumo en local',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textoSecundario, fontSize: 10),
                    ),
                  ),
                  Icon(_iconoPago(pedido.metodoPago),
                      color: AppTheme.naranja, size: 15),
                  const SizedBox(width: 5),
                  Text(_etiquetaPago(pedido.metodoPago),
                      style: const TextStyle(
                          color: AppTheme.textoSecundario, fontSize: 10)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      color: AppTheme.naranja, size: 13),
                ],
              ),
              if (pedido.metodoPago == 'qr') ...[
                const SizedBox(height: 9),
                Row(
                  children: [
                    Icon(Icons.circle, size: 7, color: _colorEstadoPago()),
                    const SizedBox(width: 6),
                    Text(
                      'Pago: ${PedidoEstados.etiqueta(pedido.estadoPago)}',
                      style: TextStyle(
                        color: _colorEstadoPago(),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      color: AppTheme.textoSecundario, size: 13),
                  const SizedBox(width: 6),
                  Text(_formatearFecha(pedido.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textoSecundario, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipEstado extends StatelessWidget {
  final String texto;
  final Color color;

  const _ChipEstado({required this.texto, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Text(
        texto,
        style: TextStyle(
            color: color, fontSize: 10, fontWeight: FontWeight.w800),
      ),
    );
  }
}
