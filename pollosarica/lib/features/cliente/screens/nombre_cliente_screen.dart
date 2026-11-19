
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'telefono_cliente_screen.dart';

class NombreClienteScreen extends StatefulWidget {
  const NombreClienteScreen({super.key});

  @override
  State<NombreClienteScreen> createState() => _NombreClienteScreenState();
}

class _NombreClienteScreenState extends State<NombreClienteScreen> {
  final _nombreController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  void _continuar() {
    final nombre = _nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, escribe tu nombre.'),
        ),
      );
      return;
    }

    if (nombre.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre debe tener al menos 2 caracteres.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TelefonoClienteScreen(
          nombre: nombre,
        ),
      ),
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
          onPressed: () => Navigator.of(context).pop(),
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
              constraints: const BoxConstraints(
                maxWidth: 420,
              ),
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
                        Icons.person_outline,
                        color: AppTheme.naranja,
                        size: 39,
                      ),
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Text(
                    '¿Cómo quieres que te llamemos?',
                    style: TextStyle(
                      color: AppTheme.marron,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Queremos conocerte para brindarte una '
                    'experiencia más personal en Pollos Arica.',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Tu nombre',
                    style: TextStyle(
                      color: AppTheme.marron,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _continuar(),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Jhona',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _continuar,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continuar',
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
                      'Un paso más para disfrutar de nuestro menú.',
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
