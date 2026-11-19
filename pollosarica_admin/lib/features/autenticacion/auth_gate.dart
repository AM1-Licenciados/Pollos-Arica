
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../inicio/admin_home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<Map<String, dynamic>?> _obtenerPerfil(String userId) async {
    final resultado = await Supabase.instance.client
        .from('perfiles_admin')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, authSnapshot) {
        final session =
            authSnapshot.data?.session ??
            Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _obtenerPerfil(session.user.id),
          builder: (context, perfilSnapshot) {
            if (perfilSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.naranja,
                  ),
                ),
              );
            }

            if (perfilSnapshot.hasError) {
              return _AccesoDenegado(
                mensaje: 'No se pudo verificar tu perfil administrativo.',
              );
            }

            final perfil = perfilSnapshot.data;

            if (perfil == null || perfil['activo'] != true) {
              return const _AccesoDenegado(
                mensaje: 'Esta cuenta no tiene autorización para acceder '
                    'al panel administrativo.',
              );
            }

            return AdminHomeScreen(perfil: perfil);
          },
        );
      },
    );
  }
}

class _AccesoDenegado extends StatelessWidget {
  final String mensaje;

  const _AccesoDenegado({
    required this.mensaje,
  });

  Future<void> _cerrarSesion() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.gpp_bad_outlined,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Acceso no autorizado',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _cerrarSesion,
                  child: const Text('Cerrar sesión'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
