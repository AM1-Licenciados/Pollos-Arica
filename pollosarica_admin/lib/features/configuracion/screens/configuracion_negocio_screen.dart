import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../services/configuracion_negocio_admin_service.dart';

class ConfiguracionNegocioScreen extends StatefulWidget {
  const ConfiguracionNegocioScreen({super.key});

  @override
  State<ConfiguracionNegocioScreen> createState() =>
      _ConfiguracionNegocioScreenState();
}

class _ConfiguracionNegocioScreenState
    extends State<ConfiguracionNegocioScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();

  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _whatsappController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _latitudController.dispose();
    _longitudController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final config =
          await ConfiguracionNegocioAdminService.instance.obtener();
      if (!mounted) return;

      _nombreController.text = config.nombreNegocio;
      _whatsappController.text = config.telefonoWhatsApp;
      _telefonoController.text = config.telefonoLlamadas;
      _direccionController.text = config.direccion;
      _latitudController.text = config.latitud.toString();
      _longitudController.text = config.longitud.toString();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _guardando) return;

    final latitud = double.tryParse(_latitudController.text.trim());
    final longitud = double.tryParse(_longitudController.text.trim());

    if (latitud == null || longitud == null ||
        latitud < -90 || latitud > 90 ||
        longitud < -180 || longitud > 180) {
      _mostrarMensaje('Introduce coordenadas válidas.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await ConfiguracionNegocioAdminService.instance.actualizar(
        nombreNegocio: _nombreController.text,
        telefonoWhatsApp: _whatsappController.text,
        telefonoLlamadas: _telefonoController.text,
        direccion: _direccionController.text,
        latitud: latitud,
        longitud: longitud,
      );

      if (!mounted) return;
      _mostrarMensaje('Configuración actualizada correctamente.');
    } catch (error) {
      if (!mounted) return;
      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.naranja),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Información del restaurante',
                  style: TextStyle(
                    color: AppTheme.marron,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Estos datos se muestran en la aplicación de los clientes.',
                  style: TextStyle(color: AppTheme.textoSecundario),
                ),
                const SizedBox(height: 24),
                _SeccionFormulario(
                  titulo: 'Datos generales',
                  icono: Icons.storefront_outlined,
                  children: [
                    _campo(
                      controller: _nombreController,
                      label: 'Nombre del negocio',
                      icono: Icons.restaurant,
                    ),
                    const SizedBox(height: 16),
                    _campo(
                      controller: _direccionController,
                      label: 'Dirección',
                      icono: Icons.location_on_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SeccionFormulario(
                  titulo: 'Contacto',
                  icono: Icons.contact_phone_outlined,
                  children: [
                    _campo(
                      controller: _whatsappController,
                      label: 'WhatsApp (con código de país)',
                      icono: Icons.chat_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    _campo(
                      controller: _telefonoController,
                      label: 'Teléfono para llamadas',
                      icono: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      helper: 'Si queda vacío, se utilizará el WhatsApp.',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SeccionFormulario(
                  titulo: 'Ubicación del mapa',
                  icono: Icons.map_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            controller: _latitudController,
                            label: 'Latitud',
                            icono: Icons.north,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _campo(
                            controller: _longitudController,
                            label: 'Longitud',
                            icono: Icons.east,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Coordenadas actuales: -17.8311294, -63.1341483',
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _guardando ? null : _guardar,
                    icon: _guardando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _guardando ? 'Guardando...' : 'Guardar cambios',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String label,
    required IconData icono,
    TextInputType? keyboardType,
    String? helper,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: Icon(icono, color: AppTheme.naranja),
      ),
      validator: (value) {
        if (label == 'Nombre del negocio' &&
            (value == null || value.trim().isEmpty)) {
          return 'Este campo es obligatorio.';
        }
        return null;
      },
    );
  }
}

class _SeccionFormulario extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final List<Widget> children;

  const _SeccionFormulario({
    required this.titulo,
    required this.icono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFEDE5DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: AppTheme.naranja),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
