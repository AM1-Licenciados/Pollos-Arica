import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pedidos/screens/pedidos_screen.dart';
import '../configuracion/screens/configuracion_negocio_screen.dart';
import '../../core/theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;

  const AdminHomeScreen({super.key, required this.perfil});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _indiceSeleccionado = 0;

  static const List<_OpcionMenu> _opciones = [
    _OpcionMenu('Inicio', Icons.grid_view_rounded),
    _OpcionMenu('Pedidos', Icons.receipt_long_rounded),
    _OpcionMenu('Configuración', Icons.tune_rounded),
  ];

  String get _nombreAdmin =>
      widget.perfil['nombre']?.toString().trim().isNotEmpty == true
          ? widget.perfil['nombre'].toString()
          : 'Administrador';

  String get _correoAdmin =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
  }

  void _seleccionarOpcion(int indice) {
    setState(() => _indiceSeleccionado = indice);
    if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final escritorio = constraints.maxWidth >= 900;

        if (escritorio) {
          return Scaffold(
            body: Row(
              children: [
                _construirMenuLateral(),
                Expanded(
                  child: Column(
                    children: [
                      _construirBarraSuperior(),
                      Expanded(child: _construirContenido()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          drawer: Drawer(
            width: 285,
            backgroundColor: AppTheme.marron,
            child: SafeArea(child: _construirMenuContenido()),
          ),
          appBar: AppBar(
            title: Text(
              _opciones[_indiceSeleccionado].nombre,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout_rounded),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: _construirContenido(),
        );
      },
    );
  }

  Widget _construirMenuLateral() {
    return Container(
      width: 258,
      color: AppTheme.marron,
      child: SafeArea(child: _construirMenuContenido()),
    );
  }

  Widget _construirMenuContenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 20, 25),
          child: Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: AppTheme.naranja,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pollos Arica',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3)),
                    SizedBox(height: 4),
                    Text('PANEL DE CONTROL',
                        style: TextStyle(
                            color: AppTheme.naranjaClaro,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.3)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Divider(color: Colors.white.withValues(alpha: 0.12)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 23, 16, 12),
          child: Text('MENÚ PRINCIPAL',
              style: TextStyle(
                  color: Color(0xFFB9A69A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            itemCount: _opciones.length,
            itemBuilder: (context, index) {
              final opcion = _opciones[index];
              final seleccionado = _indiceSeleccionado == index;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Material(
                  color: seleccionado
                      ? AppTheme.naranja
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _seleccionarOpcion(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Icon(opcion.icono,
                              color: seleccionado
                                  ? Colors.white
                                  : const Color(0xFFCBBDB4),
                              size: 20),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(opcion.nombre,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: seleccionado
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                          ),
                          if (seleccionado)
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(15),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                      color: Color(0xFF624638), shape: BoxShape.circle),
                  child: const Icon(Icons.person_rounded,
                      color: AppTheme.naranjaClaro, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_nombreAdmin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(_correoAdmin,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Color(0xFFCBBDB4), fontSize: 10)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white70, size: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _construirBarraSuperior() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 34),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borde)),
      ),
      child: Row(
        children: [
          Text(_opciones[_indiceSeleccionado].nombre,
              style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: Color(0xFF43A477), size: 8),
                SizedBox(width: 7),
                Text('Panel activo',
                    style: TextStyle(
                        color: AppTheme.marron,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: Color(0xFFFFE9D6), shape: BoxShape.circle),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.naranja, size: 19),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_nombreAdmin,
                  style: const TextStyle(
                      color: AppTheme.marron,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
              const Text('Administrador',
                  style: TextStyle(
                      color: AppTheme.textoSecundario, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.textoSecundario, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _construirContenido() {
    switch (_indiceSeleccionado) {
      case 1:
        return const PedidosScreen();
      case 2:
        return const ConfiguracionNegocioScreen();
      default:
        return _construirDashboard();
    }
  }

  Widget _construirDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¡Hola, $_saludo!',
                  style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 5),
              Text(_nombreAdmin,
                  style: const TextStyle(
                      color: AppTheme.marron,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.7)),
              const SizedBox(height: 8),
              const Text(
                'Este es el centro de control de tu negocio.',
                style: TextStyle(color: AppTheme.textoSecundario, fontSize: 13),
              ),
              const SizedBox(height: 26),
              _construirBannerPrincipal(),
              const SizedBox(height: 26),
              const Text('Accesos rápidos',
                  style: TextStyle(
                      color: AppTheme.marron,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              const Text('Gestiona las tareas principales de Pollos Arica.',
                  style: TextStyle(
                      color: AppTheme.textoSecundario, fontSize: 12)),
              const SizedBox(height: 15),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 850
                      ? 3
                      : constraints.maxWidth >= 520
                          ? 2
                          : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: columns == 1 ? 3.3 : 2.1,
                    children: [
                      _TarjetaAcceso(
                        icono: Icons.receipt_long_rounded,
                        titulo: 'Gestionar pedidos',
                        descripcion: 'Revisa pedidos y actualiza su estado.',
                        color: AppTheme.naranja,
                        onTap: () => _seleccionarOpcion(1),
                      ),
                      _TarjetaAcceso(
                        icono: Icons.qr_code_2_rounded,
                        titulo: 'Verificación QR',
                        descripcion: 'Confirma manualmente los pagos recibidos.',
                        color: const Color(0xFF32866C),
                        onTap: () => _seleccionarOpcion(1),
                      ),
                      _TarjetaAcceso(
                        icono: Icons.storefront_rounded,
                        titulo: 'Datos del negocio',
                        descripcion: 'Actualiza la información y configuración.',
                        color: const Color(0xFF6D79A8),
                        onTap: () => _seleccionarOpcion(2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              _construirNotaPresentacion(),
            ],
          ),
        ),
      ),
    );
  }

  static const String _saludo = 'bienvenido';

  Widget _construirBannerPrincipal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE87522), Color(0xFFCA5818)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: AppTheme.naranja.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 10)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compacto = constraints.maxWidth < 560;
          final texto = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.17),
                    borderRadius: BorderRadius.circular(30)),
                child: const Text('PANEL ADMINISTRATIVO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1)),
              ),
              const SizedBox(height: 15),
              const Text('Todo tu negocio,\nen un solo lugar.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 9),
              const Text(
                'Administra pedidos, verifica pagos y mantén actualizada la información de tu restaurante.',
                style: TextStyle(
                    color: Color(0xFFFFEBDD), fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _seleccionarOpcion(1),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.naranja,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: const Text('Ir a pedidos',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
              ),
            ],
          );

          if (compacto) {
            return texto;
          }
          return Row(
            children: [
              Expanded(flex: 3, child: texto),
              const SizedBox(width: 25),
              Expanded(
                flex: 2,
                child: Container(
                  height: 185,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant_menu_rounded,
                        color: Colors.white, size: 88),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _construirNotaPresentacion() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borde),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_user_outlined,
              color: Color(0xFF32866C), size: 23),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pagos QR con verificación administrativa',
                    style: TextStyle(
                        color: AppTheme.marron,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 5),
                Text(
                  'El cliente notifica que realizó el pago y el administrador verifica la transferencia antes de marcar el pedido como pagado. La preparación se habilita después de la confirmación.',
                  style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 12,
                      height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OpcionMenu {
  final String nombre;
  final IconData icono;
  const _OpcionMenu(this.nombre, this.icono);
}

class _TarjetaAcceso extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _TarjetaAcceso({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: AppTheme.borde),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icono, color: color, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            color: AppTheme.marron,
                            fontSize: 13,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Text(descripcion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppTheme.textoSecundario,
                            fontSize: 11,
                            height: 1.35)),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFB7AAA2), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
