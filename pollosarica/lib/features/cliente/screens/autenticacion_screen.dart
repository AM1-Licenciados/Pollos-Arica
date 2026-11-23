import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../services/autenticacion_service.dart';

class AutenticacionScreen extends StatefulWidget {
  final bool iniciarEnRegistro;

  const AutenticacionScreen({
    super.key,
    this.iniciarEnRegistro = false,
  });

  @override
  State<AutenticacionScreen> createState() => _AutenticacionScreenState();
}

class _AutenticacionScreenState extends State<AutenticacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _apellido = TextEditingController();
  final _correo = TextEditingController();
  final _telefono = TextEditingController();
  final _password = TextEditingController();
  final _confirmarPassword = TextEditingController();

  late bool _registro;
  bool _cargando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmacion = true;

  @override
  void initState() {
    super.initState();
    _registro = widget.iniciarEnRegistro;
  }

  @override
  void dispose() {
    _nombre.dispose();
    _apellido.dispose();
    _correo.dispose();
    _telefono.dispose();
    _password.dispose();
    _confirmarPassword.dispose();
    super.dispose();
  }

  String? _validarObligatorio(String? valor, String campo) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Ingresa $campo.';
    }
    return null;
  }

  String? _validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';
    if (correo.isEmpty) return 'Ingresa tu correo electrónico.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }

  String? _validarTelefono(String? valor) {
    final telefono = (valor ?? '').replaceAll(RegExp(r'\s+'), '');
    if (telefono.isEmpty) return 'Ingresa tu número de teléfono.';
    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(telefono)) {
      return 'Ingresa un número válido, con código de país si corresponde.';
    }
    return null;
  }

  String? _validarPassword(String? valor) {
    if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña.';
    if (valor.length < 8) return 'Usa al menos 8 caracteres.';
    return null;
  }

  Future<void> _enviar() async {
    if (_cargando || !_formKey.currentState!.validate()) return;

    if (_registro && _password.text != _confirmarPassword.text) {
      _mensaje('Las contraseñas no coinciden.');
      return;
    }

    setState(() => _cargando = true);

    try {
      if (_registro) {
        final sesionCreada = await AutenticacionService.instance.registrar(
          nombre: _nombre.text,
          apellido: _apellido.text,
          correo: _correo.text,
          telefono: _telefono.text,
          password: _password.text,
        );

        if (!mounted) return;

        if (sesionCreada) {
          Navigator.of(context).pop(true);
        } else {
          await showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Confirma tu correo'),
              content: const Text(
                'Te enviamos un enlace de confirmación. '
                'Abre tu correo y confirma la cuenta antes de iniciar sesión.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          );
          if (mounted) setState(() => _registro = false);
        }
      } else {
        await AutenticacionService.instance.iniciarSesion(
          correo: _correo.text,
          password: _password.text,
        );
        if (mounted) Navigator.of(context).pop(true);
      }
    } on AuthException catch (error) {
      if (mounted) _mensaje(_traducirError(error));
    } catch (_) {
      if (mounted) {
        _mensaje('No pudimos completar la operación. Intenta nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _traducirError(AuthException error) {
    final mensaje = error.message.toLowerCase();

    if (mensaje.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (mensaje.contains('already registered') ||
        mensaje.contains('user already registered')) {
      return 'Este correo ya tiene una cuenta. Inicia sesión.';
    }
    if (mensaje.contains('email not confirmed')) {
      return 'Primero debes confirmar tu correo electrónico.';
    }
    if (mensaje.contains('password')) {
      return 'La contraseña no cumple los requisitos de seguridad.';
    }
    return error.message;
  }

  Future<void> _recuperarPassword() async {
    final correo = _correo.text.trim();

    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo)) {
      _mensaje('Escribe un correo válido en el campo de correo.');
      return;
    }

    setState(() => _cargando = true);
    try {
      await AutenticacionService.instance.enviarRecuperacion(correo);
      if (mounted) {
        _mensaje('Si el correo está registrado, recibirás instrucciones para recuperar tu contraseña.');
      }
    } on AuthException catch (error) {
      if (mounted) _mensaje(error.message);
    } catch (_) {
      if (mounted) _mensaje('No se pudo enviar el correo. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  InputDecoration _decoracion(String etiqueta, IconData icono) {
    return InputDecoration(
      labelText: etiqueta,
      prefixIcon: Icon(icono, color: AppTheme.naranja),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String etiqueta,
    required IconData icono,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      obscureText: obscure,
      enabled: !_cargando,
      decoration: _decoracion(etiqueta, icono).copyWith(suffixIcon: suffix),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/images/logo_pollos_arica.png',
                      width: 300,
                      height: 170,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _registro ? 'Crear cuenta' : 'Inicia sesión',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.marron,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),
                    if (_registro) ...[
                      _campo(
                        controller: _nombre,
                        etiqueta: 'Nombre',
                        icono: Icons.person_outline,
                        capitalization: TextCapitalization.words,
                        validator: (v) => _validarObligatorio(v, 'tu nombre'),
                      ),
                      const SizedBox(height: 14),
                      _campo(
                        controller: _apellido,
                        etiqueta: 'Apellido',
                        icono: Icons.person_outline,
                        capitalization: TextCapitalization.words,
                        validator: (v) => _validarObligatorio(v, 'tu apellido'),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _campo(
                      controller: _correo,
                      etiqueta: 'Correo electrónico',
                      icono: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validarCorreo,
                    ),
                    if (_registro) ...[
                      const SizedBox(height: 14),
                      _campo(
                        controller: _telefono,
                        etiqueta: 'Teléfono',
                        icono: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: _validarTelefono,
                      ),
                    ],
                    const SizedBox(height: 14),
                    _campo(
                      controller: _password,
                      etiqueta: 'Contraseña',
                      icono: Icons.lock_outline,
                      obscure: _ocultarPassword,
                      validator: _validarPassword,
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _ocultarPassword = !_ocultarPassword,
                        ),
                        icon: Icon(
                          _ocultarPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    if (_registro) ...[
                      const SizedBox(height: 14),
                      _campo(
                        controller: _confirmarPassword,
                        etiqueta: 'Confirmar contraseña',
                        icono: Icons.lock_reset_outlined,
                        obscure: _ocultarConfirmacion,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirma tu contraseña.';
                          }
                          return null;
                        },
                        suffix: IconButton(
                          onPressed: () => setState(
                            () => _ocultarConfirmacion = !_ocultarConfirmacion,
                          ),
                          icon: Icon(
                            _ocultarConfirmacion
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ],
                    if (!_registro)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _cargando ? null : _recuperarPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.naranja,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('¿Olvidaste tu contraseña?'),
                        ),
                      ),
                    if (!_registro) const SizedBox(height: 4),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _enviar,
                        child: _cargando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _registro ? 'Crear cuenta' : 'Ingresar',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.naranja.withValues(alpha: 0.42),
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            _registro
                                ? '¿Ya tienes una cuenta?'
                                : '¿No puedes iniciar sesión?',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.naranja,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.naranja.withValues(alpha: 0.42),
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _cargando
                            ? null
                            : () => setState(() => _registro = !_registro),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.naranja,
                          side: const BorderSide(
                            color: AppTheme.naranja,
                            width: 1.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _registro ? 'Iniciar sesión' : 'Crear cuenta',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: Center(
                        child: TextButton(
                          onPressed: _cargando
                              ? null
                              : () => Navigator.of(context).maybePop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textoSecundario,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Volver',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
