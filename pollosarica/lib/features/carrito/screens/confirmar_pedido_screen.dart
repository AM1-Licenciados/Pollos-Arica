
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
  bool _notificandoPago = false;
  bool _pagoNotificado = false;
  bool _subiendoComprobante = false;
  bool _descargandoQr = false;
  Uint8List? _comprobanteBytes;
  bool _comprobanteSubido = false;

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


  Future<void> _seleccionarComprobante() async {
    if (_pedidoCreado == null || _pagoNotificado || _subiendoComprobante) return;
    try {
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 2000,
      );
      if (archivo == null || !mounted) return;

      final bytes = await archivo.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw Exception('La imagen debe pesar como máximo 5 MB.');
      }

      setState(() {
        _subiendoComprobante = true;
        _comprobanteBytes = bytes;
        _comprobanteSubido = false;
      });

      await PedidoService.instance.subirComprobanteQr(
        pedidoId: _pedidoCreado!.id,
        archivo: archivo,
      );

      if (!mounted) return;
      setState(() => _comprobanteSubido = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprobante adjuntado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _comprobanteSubido = false;
        _comprobanteBytes = null;
      });
      final mensaje = error.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo adjuntar: $mensaje')),
      );
    } finally {
      if (mounted) setState(() => _subiendoComprobante = false);
    }
  }

  Future<void> _descargarQr() async {
    final url = _qrUrl;
    if (url == null || url.isEmpty || _descargandoQr) return;
    setState(() => _descargandoQr = true);
    try {
      final guardado = kIsWeb
          ? await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)
          : await GallerySaver.saveImage(url, albumName: 'Pollos Arica');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(guardado == true
              ? 'Código QR guardado en tu galería.'
              : kIsWeb
                  ? 'Se abrió el QR en el navegador para guardarlo.'
                  : 'No se pudo guardar el QR en la galería.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al descargar el QR: $error')),
      );
    } finally {
      if (mounted) setState(() => _descargandoQr = false);
    }
  }

  Future<void> _notificarPago() async {
    final pedido = _pedidoCreado;
    if (pedido == null ||
        pedido.metodoPago != 'qr' ||
        _notificandoPago ||
        _pagoNotificado ||
        !_comprobanteSubido) {
      return;
    }

    setState(() => _notificandoPago = true);

    try {
      await PedidoService.instance.notificarPagoQr(pedido.id);

      if (!mounted) return;

      setState(() => _pagoNotificado = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Avisamos al personal. Tu pago está pendiente de verificación.',
          ),
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
        setState(() => _notificandoPago = false);
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

  Widget _construirExito(PedidoCreado pedido) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.naranja.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.naranja, size: 54),
              ),
              const SizedBox(height: 18),
              const Text('¡Pedido registrado!',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold,
                      color: AppTheme.marron)),
              const SizedBox(height: 8),
              const Text(
                'Tu pedido fue enviado a Pollos Arica y está pendiente de revisión.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: _decoracion(),
                child: Column(
                  children: [
                    const Text('Código de pedido',
                        style: TextStyle(color: AppTheme.textoSecundario)),
                    const SizedBox(height: 5),
                    Text(pedido.codigo,
                        style: const TextStyle(fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.naranja)),
                    const SizedBox(height: 8),
                    Text('Total: ${_precio(pedido.total)}',
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            color: AppTheme.marron)),
                  ],
                ),
              ),
              if (pedido.metodoPago == 'qr') ...[
                const SizedBox(height: 16),
                if (_qrUrl != null && _qrUrl!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: _decoracion(),
                    child: Column(
                      children: [
                        const Text('Realiza tu transferencia',
                            style: TextStyle(fontWeight: FontWeight.bold,
                                color: AppTheme.marron)),
                        const SizedBox(height: 10),
                        InteractiveViewer(
                          minScale: 1,
                          maxScale: 4,
                          child: Image.network(_qrUrl!,
                              height: 250, width: 250, fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                  Icons.qr_code_2, size: 120,
                                  color: AppTheme.naranja)),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _descargandoQr ? null : _descargarQr,
                          icon: _descargandoQr
                              ? const SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download_outlined),
                          label: Text(_descargandoQr ? 'Guardando...' : 'Descargar QR'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.naranja,
                            side: const BorderSide(color: AppTheme.naranja),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Transfiere ${_precio(pedido.total)}. El personal verificará el movimiento en la banca.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textoSecundario,
                              fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: _decoracion(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pagoNotificado || _subiendoComprobante
                              ? null : _seleccionarComprobante,
                          icon: _subiendoComprobante
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : Icon(_comprobanteSubido
                                  ? Icons.check_circle_outline
                                  : Icons.image_outlined),
                          label: Text(_subiendoComprobante
                              ? 'Subiendo comprobante...'
                              : _comprobanteSubido
                                  ? 'Cambiar comprobante'
                                  : 'Adjuntar comprobante'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.naranja,
                            side: const BorderSide(color: AppTheme.naranja),
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
                        if (_comprobanteBytes != null) ...[
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(_comprobanteBytes!,
                                height: 150, fit: BoxFit.contain),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _comprobanteSubido
                                ? 'Comprobante cargado correctamente.'
                                : 'Comprobante seleccionado.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 11,
                                color: AppTheme.textoSecundario),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _notificandoPago || _pagoNotificado ||
                                    !_comprobanteSubido
                                ? null : _notificarPago,
                            icon: _notificandoPago
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Icon(_pagoNotificado
                                    ? Icons.check_circle_outline
                                    : Icons.account_balance_wallet_outlined),
                            label: Text(_pagoNotificado
                                ? 'Pago notificado'
                                : 'Ya realicé el pago'),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _pagoNotificado
                              ? 'Tu aviso fue enviado. Espera la verificación del personal.'
                              : _comprobanteSubido
                                  ? 'Comprobante adjuntado. Ahora puedes notificar tu pago.'
                                  : 'Adjunta primero una imagen del comprobante para habilitar este botón.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppTheme.textoSecundario, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ] else
                  const Text(
                    'No pudimos mostrar el QR. Comunícate con el personal para recibir instrucciones de pago.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textoSecundario),
                  ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const CatalogoScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
