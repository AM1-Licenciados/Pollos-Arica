
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../catalogo/screens/catalogo_screen.dart';
import '../../cliente/services/cliente_local_service.dart';
import '../../cliente/services/autenticacion_service.dart';
import '../data/carrito_service.dart';
import '../data/pedido_service.dart';

class ConfirmarPedidoScreen extends StatefulWidget {
  const ConfirmarPedidoScreen({super.key});

  @override
  State<ConfirmarPedidoScreen> createState() =>
      _ConfirmarPedidoScreenState();
}

class _ConfirmarPedidoScreenState extends State<ConfirmarPedidoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _celularController = TextEditingController();
  final _observacionesController = TextEditingController();

  String _metodoPago = 'efectivo';
  String _tipoEntrega = 'retiro';
  String _momentoPreparacion = 'inmediato';

  bool _enviando = false;
  bool _cargandoQr = false;
  bool _cargandoCliente = true;

  String? _qrUrl;
  PedidoCreado? _pedidoCreado;
  String? _errorQr;

  @override
  void initState() {
    super.initState();
    _cargarCliente();
    _cargarQr();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _celularController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _cargarCliente() async {
    try {
      final perfil =
          await AutenticacionService.instance.obtenerPerfilCliente();

      if (!mounted) return;

      if (perfil != null) {
        final nombre = (perfil['nombre'] as String? ?? '').trim();
        final apellido = (perfil['apellido'] as String? ?? '').trim();

        _nombreController.text = [nombre, apellido]
            .where((parte) => parte.isNotEmpty)
            .join(' ');
        _celularController.text = perfil['telefono'] as String? ?? '';
      } else {
        // Compatibilidad con datos locales de instalaciones anteriores.
        final cliente =
            await ClienteLocalService.instance.obtenerCliente();

        if (!mounted) return;

        if (cliente != null) {
          _nombreController.text = cliente['nombre'] ?? '';
          _celularController.text = cliente['telefono'] ?? '';
        }
      }
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron recuperar tus datos. Puedes ingresarlos manualmente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _cargandoCliente = false);
      }
    }
  }

  Future<void> _cargarQr() async {
    setState(() {
      _cargandoQr = true;
      _errorQr = null;
    });

    try {
      final url = await PedidoService.instance.obtenerQrActual();

      if (!mounted) return;

      setState(() => _qrUrl = url);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorQr = 'No se pudo cargar el QR. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _cargandoQr = false);
      }
    }
  }

  String _precio(double valor) =>
      valor == valor.roundToDouble()
          ? 'Bs ${valor.toStringAsFixed(0)}'
          : 'Bs ${valor.toStringAsFixed(2)}';

  Future<void> _confirmar() async {
    if (_cargandoCliente || _enviando) return;

    if (!_formKey.currentState!.validate()) return;

    if (CarritoService.instance.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu carrito está vacío.'),
        ),
      );

      Navigator.pop(context);
      return;
    }

    setState(() => _enviando = true);

    try {
      final nombre = _nombreController.text.trim();
      final celular = _celularController.text.trim();

      final pedido = await PedidoService.instance.crearPedido(
        nombre: nombre,
        celular: celular,
        metodoPago: _metodoPago,
        tipoEntrega: _tipoEntrega,
        momentoPreparacion: _momentoPreparacion,
        observaciones: _observacionesController.text,
      );

      // Actualizamos los datos locales después de registrar
      // correctamente el pedido.
      await ClienteLocalService.instance.guardarCliente(
        nombre: nombre,
        telefono: celular,
      );

      if (!mounted) return;

      setState(() => _pedidoCreado = pedido);
    } catch (error) {
      if (!mounted) return;

      final mensaje = error.toString().replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrito = CarritoService.instance;
    final pedido = _pedidoCreado;

    return Scaffold(
      backgroundColor: AppTheme.crema,
      appBar: AppBar(
        backgroundColor: AppTheme.crema,
        foregroundColor: AppTheme.marron,
        elevation: 0,
        centerTitle: true,
        title: Text(
          pedido == null ? 'Confirmar pedido' : 'Pedido registrado',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        automaticallyImplyLeading: pedido == null,
      ),
      body: pedido != null
          ? _construirExito(pedido)
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _tituloSeccion('Tus datos'),

                  if (_cargandoCliente)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.naranja,
                        ),
                      ),
                    )
                  else ...[
                    _campo(
                      _nombreController,
                      'Nombre completo',
                      Icons.person_outline,
                      validator: (v) =>
                          (v == null || v.trim().length < 2)
                              ? 'Ingresa tu nombre.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      _celularController,
                      'Número de celular',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v == null ||
                                  !RegExp(r'^[0-9+() -]{7,30}$')
                                      .hasMatch(v.trim()))
                              ? 'Ingresa un celular válido.'
                              : null,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Puedes modificar tus datos si es necesario.',
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  _tituloSeccion('¿Cómo deseas disfrutar tu pedido?'),

                  _opcionSeleccion(
                    valor: 'retiro',
                    seleccionado: _tipoEntrega,
                    titulo: 'Retirar en el local',
                    descripcion: 'Recoge tu pedido en Pollos Arica.',
                    icono: Icons.shopping_bag_outlined,
                    onTap: () => setState(() {
                      _tipoEntrega = 'retiro';
                      _momentoPreparacion = 'inmediato';
                    }),
                  ),

                  const SizedBox(height: 10),

                  _opcionSeleccion(
                    valor: 'consumo_local',
                    seleccionado: _tipoEntrega,
                    titulo: 'Consumir en el local',
                    descripcion:
                        'Disfruta tu pedido en nuestro establecimiento.',
                    icono: Icons.restaurant_outlined,
                    onTap: () =>
                        setState(() => _tipoEntrega = 'consumo_local'),
                  ),

                  if (_tipoEntrega == 'consumo_local') ...[
                    const SizedBox(height: 24),

                    _tituloSeccion(
                      '¿Cuándo deseas que preparemos tu pedido?',
                    ),

                    _opcionSeleccion(
                      valor: 'inmediato',
                      seleccionado: _momentoPreparacion,
                      titulo: 'De inmediato',
                      descripcion:
                          'La preparación comenzará cuando el personal acepte tu pedido.',
                      icono: Icons.flash_on_outlined,
                      onTap: () =>
                          setState(() => _momentoPreparacion = 'inmediato'),
                    ),

                    const SizedBox(height: 10),

                    _opcionSeleccion(
                      valor: 'al_llegar',
                      seleccionado: _momentoPreparacion,
                      titulo: 'Cuando llegue al establecimiento',
                      descripcion:
                          'El personal esperará tu llegada para comenzar a prepararlo.',
                      icono: Icons.location_on_outlined,
                      onTap: () =>
                          setState(() => _momentoPreparacion = 'al_llegar'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  _tituloSeccion('Método de pago'),

                  _opcionPago(
                    'efectivo',
                    _tipoEntrega == 'retiro'
                        ? 'Efectivo al recoger'
                        : 'Efectivo en el local',
                    _tipoEntrega == 'retiro'
                        ? 'Paga cuando retires tu pedido.'
                        : 'Paga en el establecimiento al recibir tu pedido.',
                    Icons.payments_outlined,
                  ),

                  const SizedBox(height: 10),

                  _opcionPago(
                    'qr',
                    'Pago mediante QR',
                    'Escanea el QR y transfiere el importe exacto.',
                    Icons.qr_code_2_rounded,
                  ),

                  if (_metodoPago == 'qr') ...[
                    const SizedBox(height: 12),
                    _construirQr(),
                  ],

                  const SizedBox(height: 24),

                  _tituloSeccion('Observaciones (opcional)'),

                  TextFormField(
                    controller: _observacionesController,
                    maxLines: 3,
                    maxLength: 250,
                    decoration: InputDecoration(
                      hintText: '¿Alguna indicación para tu pedido?',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _tituloSeccion('Resumen del pedido'),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _decoracion(),
                    child: Column(
                      children: [
                        ...carrito.items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.cantidad} × ${item.producto.nombre}'
                                    '${item.producto.seccion == null ? '' : ' (${item.producto.seccion})'}',
                                    style: const TextStyle(
                                      color: AppTheme.marron,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  _precio(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.marron,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Divider(),

                        _filaResumen(
                          'Modalidad',
                          _tipoEntrega == 'retiro'
                              ? 'Retirar en el local'
                              : 'Consumir en el local',
                        ),

                        if (_tipoEntrega == 'consumo_local') ...[
                          const SizedBox(height: 6),
                          _filaResumen(
                            'Preparación',
                            _momentoPreparacion == 'inmediato'
                                ? 'De inmediato'
                                : 'Cuando llegue',
                          ),
                        ] else ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.crema,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  color: AppTheme.naranja,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Te avisaremos cuando tu pedido esté listo para recoger.',
                                    style: TextStyle(
                                      color: AppTheme.textoSecundario,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Divider(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: AppTheme.marron,
                              ),
                            ),
                            Text(
                              _precio(carrito.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 21,
                                color: AppTheme.naranja,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _enviando || _cargandoCliente
                          ? null
                          : _confirmar,
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Confirmar pedido',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Tu pedido quedará pendiente hasta que el personal lo revise.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _construirExito(PedidoCreado pedido) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: AppTheme.naranja.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.naranja,
                  size: 58,
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                '¡Pedido registrado!',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.marron,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Tu pedido fue enviado a Pollos Arica y está pendiente de revisión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textoSecundario),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _decoracion(),
                child: Column(
                  children: [
                    const Text(
                      'Código de pedido',
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      pedido.codigo,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.naranja,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total: ${_precio(pedido.total)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.marron,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CatalogoScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _construirQr() {
    if (_cargandoQr) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(18),
          child: CircularProgressIndicator(
            color: AppTheme.naranja,
          ),
        ),
      );
    }

    if (_errorQr != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _decoracion(),
        child: Column(
          children: [
            Text(
              _errorQr!,
              style: const TextStyle(
                color: AppTheme.textoSecundario,
              ),
            ),
            TextButton(
              onPressed: _cargarQr,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_qrUrl == null || _qrUrl!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _decoracion(),
        child: const Text(
          'El QR todavía no está configurado. Puedes registrar el pedido y el personal te indicará cómo realizar el pago.',
          style: TextStyle(
            color: AppTheme.textoSecundario,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _decoracion(),
      child: Column(
        children: [
          const Text(
            'Escanea este código QR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.marron,
            ),
          ),
          const SizedBox(height: 10),
          Image.network(
            _qrUrl!,
            height: 220,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.qr_code_2,
              size: 100,
              color: AppTheme.naranja,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Transfiere el importe exacto de tu pedido. El pago será verificado por nuestro personal.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcionSeleccion({
    required String valor,
    required String seleccionado,
    required String titulo,
    required String descripcion,
    required IconData icono,
    required VoidCallback onTap,
  }) {
    final activa = seleccionado == valor;

    return InkWell(
      onTap: _enviando ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: activa ? AppTheme.naranja : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icono, color: AppTheme.naranja, size: 25),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.marron,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              activa
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: AppTheme.naranja,
            ),
          ],
        ),
      ),
    );
  }

  Widget _filaResumen(String etiqueta, String valor) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppTheme.marron,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _opcionPago(
    String valor,
    String titulo,
    String descripcion,
    IconData icono,
  ) =>
      InkWell(
        onTap: _enviando
            ? null
            : () => setState(() => _metodoPago = valor),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _metodoPago == valor
                  ? AppTheme.naranja
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(icono, color: AppTheme.naranja, size: 25),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.marron,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                _metodoPago == valor
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: AppTheme.naranja,
              ),
            ],
          ),
        ),
      );

  Widget _tituloSeccion(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Text(
          texto,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppTheme.marron,
          ),
        ),
      );

  Widget _campo(
    TextEditingController controller,
    String hint,
    IconData icono, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        enabled: !_enviando,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icono,
            color: AppTheme.naranja,
          ),
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          errorMaxLines: 2,
        ),
      );

  BoxDecoration _decoracion() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      );
}
