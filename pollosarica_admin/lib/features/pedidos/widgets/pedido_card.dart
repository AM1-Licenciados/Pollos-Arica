
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
        return const Color(0xFFFFA726);
      case 'aceptado':
        return const Color(0xFF42A5F5);
      case 'en_preparacion':
        return const Color(0xFF8E65C5);
      case 'listo':
        return const Color(0xFF26A69A);
      case 'entregado':
        return const Color(0xFF66A56B);
      case 'rechazado':
      case 'cancelado':
        return const Color(0xFFE57373);
      default:
        return AppTheme.textoSecundario;
    }
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Fecha no disponible';

    final local = fecha.toLocal();

    String dosDigitos(int valor) => valor.toString().padLeft(2, '0');

    return '${dosDigitos(local.day)}/${dosDigitos(local.month)}/${local.year} '
        '${dosDigitos(local.hour)}:${dosDigitos(local.minute)}';
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

  IconData _iconoPago(String metodo) {
    return metodo.toLowerCase() == 'qr'
        ? Icons.qr_code_2
        : Icons.payments_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorEstado(pedido.estado);

    final cantidadProductos = pedido.detalles.fold<int>(
      0,
      (total, item) => total + item.cantidad,
    );

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEDE5DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Código y estado.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      pedido.codigo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.marron,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      PedidoEstados.etiqueta(pedido.estado),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 13),

              // Cliente.
              Text(
                pedido.nombreCliente,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),

              if (pedido.celularCliente.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  pedido.celularCliente,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 11,
                  ),
                ),
              ],

              const SizedBox(height: 13),

              // Cantidad de productos y total.
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: AppTheme.naranja,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$cantidadProductos productos',
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    'Bs ${pedido.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.marron,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              const Divider(
                height: 20,
                color: Color(0xFFEDE5DC),
              ),

              // Modalidad y método de pago.
              Row(
                children: [
                  Icon(
                    pedido.tipoEntrega == 'retiro'
                        ? Icons.store_outlined
                        : Icons.restaurant_outlined,
                    color: AppTheme.textoSecundario,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      pedido.tipoEntrega == 'retiro'
                          ? 'Retiro en local'
                          : 'Consumo en local',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _iconoPago(pedido.metodoPago),
                    color: AppTheme.naranja,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _etiquetaPago(pedido.metodoPago),
                    style: const TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: AppTheme.naranja,
                    size: 19,
                  ),
                ],
              ),

              const SizedBox(height: 7),

              // Fecha y hora.
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: AppTheme.textoSecundario,
                    size: 13,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatearFecha(pedido.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
