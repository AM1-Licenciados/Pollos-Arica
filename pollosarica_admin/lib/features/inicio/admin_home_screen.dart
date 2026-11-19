
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../pedidos/screens/pedidos_screen.dart';
import '../configuracion/screens/configuracion_negocio_screen.dart';
import '../../core/theme/app_theme.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic> perfil;

  const AdminHomeScreen({
    super.key,
    required this.perfil,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _indiceSeleccionado = 0;

  final List<_OpcionMenu> _opciones = const [
    _OpcionMenu('Dashboard', Icons.dashboard_outlined),
    _OpcionMenu('Pedidos', Icons.shopping_bag_outlined),
    _OpcionMenu('Productos', Icons.restaurant_menu),
    _OpcionMenu('Categorías', Icons.category_outlined),
    _OpcionMenu('Clientes', Icons.people_outline),
    _OpcionMenu('Promociones', Icons.local_offer_outlined),
    _OpcionMenu('Configuración', Icons.settings_outlined),
    _OpcionMenu('Administradores', Icons.admin_panel_settings_outlined),
  ];

  String get _nombreAdmin =>
      widget.perfil['nombre']?.toString() ?? 'Administrador';

  String get _correoAdmin =>
      Supabase.instance.client.auth.currentUser?.email ?? '';

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
  }

  void _seleccionarOpcion(int indice) {
    setState(() {
      _indiceSeleccionado = indice;
    });

    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final esEscritorio = constraints.maxWidth >= 900;

        if (esEscritorio) {
          return Scaffold(
            body: Row(
              children: [
                _construirMenuLateral(),
                Expanded(
                  child: Column(
                    children: [
                      _construirBarraSuperior(),
                      Expanded(
                        child: _construirContenido(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          drawer: Drawer(
            backgroundColor: AppTheme.marron,
            child: SafeArea(
              child: _construirMenuContenido(),
            ),
          ),
          appBar: AppBar(
            title: const Text(
              'Pollos Arica Admin',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: _cerrarSesion,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: _construirContenido(),
        );
      },
    );
  }

  Widget _construirMenuLateral() {
    return Container(
      width: 255,
      color: AppTheme.marron,
      child: SafeArea(
        child: _construirMenuContenido(),
      ),
    );
  }

  Widget _construirMenuContenido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant,
                size: 35,
                color: AppTheme.naranjaClaro,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pollos Arica',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'PANEL ADMINISTRATIVO',
                      style: TextStyle(
                        color: AppTheme.naranjaClaro,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Divider(color: Color(0xFF765D4B)),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 16, 12),
          child: Text(
            'MENÚ PRINCIPAL',
            style: TextStyle(
              color: AppTheme.naranjaClaro,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _opciones.length,
            itemBuilder: (context, index) {
              final opcion = _opciones[index];
              final seleccionado = _indiceSeleccionado == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Material(
                  color: seleccionado
                      ? AppTheme.naranja
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _seleccionarOpcion(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            opcion.icono,
                            color: seleccionado
                                ? Colors.white
                                : const Color(0xFFD8C5B5),
                            size: 21,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              opcion.nombre,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: seleccionado
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (seleccionado)
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                              size: 19,
                            ),
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
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF54392D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppTheme.naranja,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nombreAdmin,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _correoAdmin,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFD8C5B5),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar sesión',
                  onPressed: _cerrarSesion,
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white70,
                    size: 19,
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEDE5DC)),
        ),
      ),
      child: Row(
        children: [
          Text(
            _opciones[_indiceSeleccionado].nombre,
            style: const TextStyle(
              color: AppTheme.marron,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.account_circle_outlined,
            color: AppTheme.naranja,
            size: 25,
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _nombreAdmin,
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Administrador',
                style: TextStyle(
                  color: AppTheme.textoSecundario,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 22),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
            icon: const Icon(
              Icons.logout,
              color: AppTheme.marron,
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirContenido() {
    if (_indiceSeleccionado == 0) {
      return _construirDashboard();
    }

    if (_indiceSeleccionado == 1) {
      return const PedidosScreen();
    }

    if (_indiceSeleccionado == 6) {
      return const ConfiguracionNegocioScreen();
    }

    return _construirModuloPendiente(
      _opciones[_indiceSeleccionado].nombre,
      _opciones[_indiceSeleccionado].icono,
    );
  }

  Widget _construirDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen del negocio',
            style: TextStyle(
              color: AppTheme.marron,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Bienvenido, $_nombreAdmin. Aquí tienes el resumen de Pollos Arica.',
            style: const TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final ancho = constraints.maxWidth;
              final columnas = ancho >= 1100
                  ? 4
                  : ancho >= 650
                      ? 2
                      : 1;

              return GridView.count(
                crossAxisCount: columnas,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: columnas == 1 ? 3.0 : 1.65,
                children: const [
                  _TarjetaIndicador(
                    titulo: 'Ventas de hoy',
                    valor: '—',
                    descripcion: 'Conectaremos las ventas',
                    icono: Icons.payments_outlined,
                  ),
                  _TarjetaIndicador(
                    titulo: 'Pedidos pendientes',
                    valor: '—',
                    descripcion: 'Pedidos por atender',
                    icono: Icons.shopping_bag_outlined,
                  ),
                  _TarjetaIndicador(
                    titulo: 'Productos activos',
                    valor: '—',
                    descripcion: 'Productos del menú',
                    icono: Icons.restaurant_menu,
                  ),
                  _TarjetaIndicador(
                    titulo: 'Clientes',
                    valor: '—',
                    descripcion: 'Clientes registrados',
                    icono: Icons.people_outline,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE5DC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Actividad reciente',
                  style: TextStyle(
                    color: AppTheme.marron,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppTheme.naranja.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Todavía no hay actividad para mostrar',
                        style: TextStyle(
                          color: AppTheme.marron,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Aquí aparecerán los últimos pedidos registrados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.textoSecundario,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBD9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: AppTheme.naranja,
                  size: 26,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'El panel está preparado. Próximamente conectaremos '
                    'los indicadores y módulos con los datos reales de Supabase.',
                    style: TextStyle(
                      color: AppTheme.marron,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirModuloPendiente(String titulo, IconData icono) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 64,
              color: AppTheme.naranja,
            ),
            const SizedBox(height: 20),
            Text(
              titulo,
              style: const TextStyle(
                color: AppTheme.marron,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Este módulo será implementado próximamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionMenu {
  final String nombre;
  final IconData icono;

  const _OpcionMenu(this.nombre, this.icono);
}

class _TarjetaIndicador extends StatelessWidget {
  final String titulo;
  final String valor;
  final String descripcion;
  final IconData icono;

  const _TarjetaIndicador({
    required this.titulo,
    required this.valor,
    required this.descripcion,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEDE5DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                icono,
                color: AppTheme.naranja,
                size: 23,
              ),
            ],
          ),
          Text(
            valor,
            style: const TextStyle(
              color: AppTheme.marron,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            descripcion,
            style: const TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
