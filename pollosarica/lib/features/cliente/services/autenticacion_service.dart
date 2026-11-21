import 'package:supabase_flutter/supabase_flutter.dart';

class AutenticacionService {
  AutenticacionService._();

  static final AutenticacionService instance = AutenticacionService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  User? get usuarioActual => _supabase.auth.currentUser;

  bool get estaAutenticado => usuarioActual != null;

  Future<bool> registrar({
    required String nombre,
    required String apellido,
    required String correo,
    required String telefono,
    required String password,
  }) async {
    final respuesta = await _supabase.auth.signUp(
      email: correo.trim().toLowerCase(),
      password: password,
      data: {
        'nombre': nombre.trim(),
        'apellido': apellido.trim(),
        'telefono': telefono.trim(),
      },
    );

    return respuesta.session != null;
  }

  Future<void> iniciarSesion({
    required String correo,
    required String password,
  }) async {
    await _supabase.auth.signInWithPassword(
      email: correo.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> enviarRecuperacion(String correo) async {
    await _supabase.auth.resetPasswordForEmail(
      correo.trim().toLowerCase(),
    );
  }

  Future<Map<String, dynamic>?> obtenerPerfilCliente() async {
    final usuario = usuarioActual;
    if (usuario == null) return null;

    final perfil = await _supabase
        .from('perfiles_clientes')
        .select('nombre, apellido, correo, telefono, foto_url')
        .eq('auth_user_id', usuario.id)
        .maybeSingle();

    return perfil;
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }
}
