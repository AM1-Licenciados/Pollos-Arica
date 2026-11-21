import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../catalogo/screens/catalogo_screen.dart';
import '../negocio/screens/ficha_negocio_screen.dart';
import '../negocio/services/configuracion_negocio_service.dart';

class BienvenidaScreen extends StatefulWidget {
  const BienvenidaScreen({super.key});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  bool _comprobandoCliente = false;
  bool _abriendoWhatsapp = false;

  Future<void> _abrirMenu() async {
    if (_comprobandoCliente) return;
    setState(() => _comprobandoCliente = true);

    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CatalogoScreen()),
      );
    } finally {
      if (mounted) setState(() => _comprobandoCliente = false);
    }
  }

  Future<void> _abrirWhatsapp() async {
    if (_abriendoWhatsapp) return;
    setState(() => _abriendoWhatsapp = true);

    try {
      final config =
          await ConfiguracionNegocioService.instance.obtenerConfiguracion();
      final telefono = config.telefonoWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
      if (telefono.isEmpty) {
        throw Exception('El número de WhatsApp todavía no está configurado.');
      }

      final uri = Uri.parse('https://wa.me/$telefono').replace(
        queryParameters: {
          'text': '¡Hola! Quisiera consultar sobre los productos de Pollos Arica.',
        },
      );

      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abierto) throw Exception('No se pudo abrir WhatsApp.');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_mensajeError(error))),
      );
    } finally {
      if (mounted) setState(() => _abriendoWhatsapp = false);
    }
  }

  String _mensajeError(Object error) {
    final mensaje = error.toString().replaceFirst('Exception: ', '');
    return mensaje;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_pollos_arica.png',
                    width: 320,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.restaurant,
                      size: 100,
                      color: AppTheme.naranja,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    '¡Bienvenido!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.marron,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Descubre nuestros productos y disfruta '
                    'de todo lo que tenemos para ofrecerte.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _comprobandoCliente ? null : _abrirMenu,
                      child: _comprobandoCliente
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ver menú',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _AccesoBienvenida(
                          icono: Icons.location_on_outlined,
                          texto: 'Ubicación',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FichaNegocioScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AccesoBienvenida(
                          icono: Icons.chat_bubble_outline,
                          texto: _abriendoWhatsapp ? 'Abriendo...' : 'WhatsApp',
                          colorIcono: const Color(0xFF25A85A),
                          onTap: _abriendoWhatsapp ? null : _abrirWhatsapp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccesoBienvenida extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color colorIcono;
  final VoidCallback? onTap;

  const _AccesoBienvenida({
    required this.icono,
    required this.texto,
    required this.onTap,
    this.colorIcono = AppTheme.naranja,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icono, color: colorIcono, size: 20),
      label: Text(
        texto,
        style: const TextStyle(
          color: AppTheme.marron,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: const BorderSide(color: Color(0xFFE8D8C8)),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }
}
