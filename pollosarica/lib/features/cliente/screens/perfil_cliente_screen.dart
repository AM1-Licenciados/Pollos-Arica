import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../negocio/screens/ficha_negocio_screen.dart';
import '../../negocio/services/configuracion_negocio_service.dart';
import '../services/autenticacion_service.dart';

class PerfilClienteScreen extends StatefulWidget {
  final VoidCallback onCerrarSesion;

  const PerfilClienteScreen({
    super.key,
    required this.onCerrarSesion,
  });

  @override
  State<PerfilClienteScreen> createState() => _PerfilClienteScreenState();
}

class _PerfilClienteScreenState extends State<PerfilClienteScreen> {
  late Future<Map<String, dynamic>?> _perfilFuture;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _perfilFuture = AutenticacionService.instance.obtenerPerfilCliente();
  }

  Future<void> _recargar() async {
    setState(() {
      _perfilFuture = AutenticacionService.instance.obtenerPerfilCliente();
    });
    await _perfilFuture;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _editarDatos(Map<String, dynamic> perfil) async {
    final nombreController =
        TextEditingController(text: perfil['nombre']?.toString() ?? '');
    final apellidoController =
        TextEditingController(text: perfil['apellido']?.toString() ?? '');
    final telefonoController =
        TextEditingController(text: perfil['telefono']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final guardar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.crema,
        title: const Text('Mis datos personales'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nombreController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Ingresa tu nombre.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: apellidoController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Apellido'),
                  validator: (valor) => valor == null || valor.trim().isEmpty
                      ? 'Ingresa tu apellido.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telefonoController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Teléfono'),
                  validator: (valor) {
                    final digitos = (valor ?? '').replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    if (digitos.length < 7 || digitos.length > 15) {
                      return 'Ingresa un teléfono válido.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'El correo electrónico de la cuenta no se modifica desde aquí.',
                  style: TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (guardar == true && mounted) {
      setState(() => _procesando = true);
      try {
        await AutenticacionService.instance.actualizarPerfilCliente(
          nombre: nombreController.text,
          apellido: apellidoController.text,
          telefono: telefonoController.text,
        );
        await _recargar();
        _mostrarMensaje('Tus datos se actualizaron correctamente.');
      } catch (error) {
        _mostrarMensaje(
          error.toString().replaceFirst('Exception: ', ''),
        );
      } finally {
        if (mounted) setState(() => _procesando = false);
      }
    }

    nombreController.dispose();
    apellidoController.dispose();
    telefonoController.dispose();
  }

  Future<void> _seleccionarFoto() async {
    if (_procesando) return;

    try {
      final imagen = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (imagen == null || !mounted) return;

      final extension = imagen.name.split('.').last.toLowerCase();
      const tipos = {
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png',
        'webp': 'image/webp',
      };
      final contentType = tipos[extension];

      if (contentType == null) {
        _mostrarMensaje('Selecciona una imagen JPG, PNG o WEBP.');
        return;
      }

      setState(() => _procesando = true);
      await AutenticacionService.instance.actualizarFotoPerfil(
        bytes: await imagen.readAsBytes(),
        extension: extension,
        contentType: contentType,
      );
      await _recargar();
      _mostrarMensaje('Tu fotografía se actualizó correctamente.');
    } catch (error) {
      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _cambiarPassword() async {
    if (_procesando) return;

    final actualController = TextEditingController();
    final nuevoController = TextEditingController();
    final confirmarController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final cambiar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.crema,
        title: const Text('Cambiar contraseña'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: actualController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña actual',
                  ),
                  validator: (valor) => valor == null || valor.isEmpty
                      ? 'Ingresa tu contraseña actual.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nuevoController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nueva contraseña',
                  ),
                  validator: (valor) => valor == null || valor.length < 8
                      ? 'Usa al menos 8 caracteres.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmarController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                  ),
                  validator: (valor) => valor != nuevoController.text
                      ? 'Las contraseñas no coinciden.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Actualizar'),
          ),
        ],
      ),
    );

    if (cambiar == true && mounted) {
      setState(() => _procesando = true);
      try {
        await AutenticacionService.instance.cambiarPassword(
          passwordActual: actualController.text,
          passwordNuevo: nuevoController.text,
        );
        _mostrarMensaje('Tu contraseña se actualizó correctamente.');
      } catch (error) {
        _mostrarMensaje(
          'No se pudo cambiar la contraseña. Verifica tu contraseña actual e inténtalo nuevamente.',
        );
      } finally {
        if (mounted) setState(() => _procesando = false);
      }
    }

    actualController.dispose();
    nuevoController.dispose();
    confirmarController.dispose();
  }

  Future<void> _cerrarSesion() async {
    if (_procesando) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.crema,
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que deseas salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);
    try {
      await AutenticacionService.instance.cerrarSesion();
      if (!mounted) return;
      widget.onCerrarSesion();
      _mostrarMensaje('Sesión cerrada correctamente.');
    } catch (_) {
      _mostrarMensaje('No se pudo cerrar la sesión. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _abrirWhatsApp() async {
    if (_procesando) return;

    try {
      final config = await ConfiguracionNegocioService.instance
          .obtenerConfiguracion();
      final telefono = config.telefonoWhatsApp.replaceAll(
        RegExp(r'[^0-9]'),
        '',
      );

      if (telefono.isEmpty) {
        _mostrarMensaje('El número de WhatsApp todavía no está configurado.');
        return;
      }

      final uri = Uri.https('wa.me', '/$telefono', {
        'text': '¡Hola! Quisiera consultar sobre los productos de Pollos Arica.',
      });
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abierto) {
        _mostrarMensaje('No se pudo abrir WhatsApp.');
      }
    } catch (error) {
      _mostrarMensaje(
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _perfilFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.naranja),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_off_outlined,
                    size: 54,
                    color: AppTheme.naranja,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No pudimos cargar tu perfil.',
                    style: TextStyle(
                      color: AppTheme.marron,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _recargar,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        final perfil = snapshot.data!;
        final nombre = [
          perfil['nombre'],
          perfil['apellido'],
        ].where((valor) => valor != null && valor.toString().trim().isNotEmpty)
            .join(' ');
        final correo = perfil['correo']?.toString() ??
            AutenticacionService.instance.usuarioActual?.email ??
            '';
        final fotoUrl = perfil['foto_url']?.toString();

        return RefreshIndicator(
          color: AppTheme.naranja,
          onRefresh: _recargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _seleccionarFoto,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFFFFE7D0),
                            backgroundImage: fotoUrl != null &&
                                    fotoUrl.trim().isNotEmpty
                                ? NetworkImage(fotoUrl)
                                : null,
                            child: fotoUrl == null || fotoUrl.trim().isEmpty
                                ? const Icon(
                                    Icons.person_rounded,
                                    size: 52,
                                    color: AppTheme.naranja,
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                color: AppTheme.naranja,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 13),
                    Text(
                      nombre.isEmpty ? 'Cliente de Pollos Arica' : nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.marron,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      correo,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const _TituloSeccion(texto: 'Mi cuenta'),
              const SizedBox(height: 10),
              _TarjetaOpciones(
                children: [
                  _OpcionPerfil(
                    icono: Icons.person_outline_rounded,
                    titulo: 'Mis datos personales',
                    subtitulo: 'Edita tu nombre y teléfono',
                    onTap: () => _editarDatos(perfil),
                  ),
                  const _SeparadorPerfil(),
                  _OpcionPerfil(
                    icono: Icons.photo_camera_outlined,
                    titulo: 'Cambiar fotografía',
                    subtitulo: 'Personaliza tu perfil',
                    onTap: _seleccionarFoto,
                  ),
                  const _SeparadorPerfil(),
                  _OpcionPerfil(
                    icono: Icons.lock_outline_rounded,
                    titulo: 'Cambiar contraseña',
                    subtitulo: 'Recibe un enlace en tu correo',
                    onTap: _cambiarPassword,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const _TituloSeccion(texto: 'Contacto'),
              const SizedBox(height: 10),
              _TarjetaOpciones(
                children: [
                  _OpcionPerfil(
                    icono: Icons.location_on_outlined,
                    titulo: 'Ubicación',
                    subtitulo: 'Conoce dónde estamos',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FichaNegocioScreen(),
                        ),
                      );
                    },
                  ),
                  const _SeparadorPerfil(),
                  _OpcionPerfil(
                    icono: Icons.chat_bubble_outline_rounded,
                    titulo: 'WhatsApp',
                    subtitulo: 'Escríbenos directamente',
                    colorIcono: const Color(0xFF25A85A),
                    onTap: _abrirWhatsApp,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _procesando ? null : _cerrarSesion,
                icon: _procesando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.logout_rounded),
                label: const Text('Cerrar sesión'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB3261E),
                  backgroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFE8D8C8)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final String texto;

  const _TituloSeccion({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: AppTheme.marron,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _TarjetaOpciones extends StatelessWidget {
  final List<Widget> children;

  const _TarjetaOpciones({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(children: children),
    );
  }
}

class _OpcionPerfil extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final Color colorIcono;

  const _OpcionPerfil({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.colorIcono = AppTheme.naranja,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: colorIcono.withValues(alpha: 0.11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, color: colorIcono),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          color: AppTheme.marron,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(
          color: AppTheme.textoSecundario,
          fontSize: 12,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppTheme.textoSecundario,
      ),
    );
  }
}

class _SeparadorPerfil extends StatelessWidget {
  const _SeparadorPerfil();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 16,
      color: Color(0xFFF0E4D9),
    );
  }
}

class _DatoPerfil extends StatelessWidget {
  final String etiqueta;
  final String valor;

  const _DatoPerfil({
    required this.etiqueta,
    required this.valor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              color: AppTheme.textoSecundario,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(
            valor.isEmpty ? 'No disponible' : valor,
            style: const TextStyle(
              color: AppTheme.marron,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
