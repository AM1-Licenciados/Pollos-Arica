
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';

class ConexionScreen extends StatefulWidget {
  const ConexionScreen({super.key});

  @override
  State<ConexionScreen> createState() => _ConexionScreenState();
}

class _ConexionScreenState extends State<ConexionScreen> {
  bool _cargando = false;
  String? _resultado;
  bool? _conexionExitosa;

  Future<void> _probarConexion() async {
    setState(() {
      _cargando = true;
      _resultado = null;
      _conexionExitosa = null;
    });

    try {
      await Supabase.instance.client
          .from('categorias')
          .select('id')
          .limit(1);

      if (!mounted) return;

      setState(() {
        _conexionExitosa = true;
        _resultado = 'Conexión establecida correctamente.\n'
            'Supabase respondió a nuestra consulta.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _conexionExitosa = false;
        _resultado = 'No se pudo completar la consulta.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restaurant,
                  size: 64,
                  color: AppTheme.naranja,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pollos Arica Admin',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.marron,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Panel administrativo',
                  style: TextStyle(
                    color: AppTheme.textoSecundario,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cargando ? null : _probarConexion,
                    icon: _cargando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.cloud_done),
                    label: Text(
                      _cargando
                          ? 'Conectando...'
                          : 'Probar conexión con Supabase',
                    ),
                  ),
                ),
                if (_resultado != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _conexionExitosa == true
                          ? Colors.green.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _resultado!,
                      style: TextStyle(
                        color: _conexionExitosa == true
                            ? Colors.green.shade800
                            : Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
