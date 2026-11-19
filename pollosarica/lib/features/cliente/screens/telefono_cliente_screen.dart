
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../catalogo/screens/catalogo_screen.dart';
import '../services/cliente_local_service.dart';

class TelefonoClienteScreen extends StatefulWidget {
  final String nombre;

  const TelefonoClienteScreen({
    super.key,
    required this.nombre,
  });

  @override
  State<TelefonoClienteScreen> createState() =>
      _TelefonoClienteScreenState();
}

class _TelefonoClienteScreenState extends State<TelefonoClienteScreen> {
  final _telefonoController = TextEditingController();

  bool _guardando = false;

  @override
  void dispose() {
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _continuar() async {
    if (_guardando) return;

    final telefono = _telefonoController.text.trim();

    if (telefono.isEmpty) {
      _mostrarMensaje('Por favor, escribe tu número de teléfono.');
      return;
    }

    if (!RegExp(r'^\+?[0-9]{7,15}$').hasMatch(telefono)) {
      _mostrarMensaje('Ingresa un número de teléfono válido.');
      return;
    }

    setState(() => _guardando = true);

    try {
      await ClienteLocalService.instance.guardarCliente(
        nombre: widget.nombre,
        telefono: telefono,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const CatalogoScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      _mostrarMensaje('No se pudieron guardar tus datos. Intenta nuevamente.');
    } finally {
      if (mounted) {
        setState(() => _guardando = false);
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.crema,
      appBar: AppBar(
        backgroundColor: AppTheme.crema,
        elevation: 0,
        leading: IconButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: AppTheme.marron,
          ),
        ),
      ),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppTheme.naranja.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.phone_android,
                        color: AppTheme.naranja,
                        size: 39,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    '¡Un gusto, ${widget.nombre}!',
                    style: const TextStyle(
                      color: AppTheme.marron,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ahora necesitamos tu número de teléfono '
                    'para identificar tus pedidos.',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Número de teléfono',
                    style: TextStyle(
                      color: AppTheme.marron,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continuar(),
                    decoration: const InputDecoration(
                      hintText: 'Ej. 75512345',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _continuar,
                      child: _guardando
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
                                  'Ingresar al menú',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'Tus datos nos ayudarán a identificar tus pedidos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
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
