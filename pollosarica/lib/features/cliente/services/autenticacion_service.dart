import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class CorreoYaRegistradoException implements Exception {
  const CorreoYaRegistradoException();
}

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

    // Supabase oculta intencionalmente si un correo ya existe.\n    // En ese caso devuelve un usuario ofuscado con identities vacío.\n    if (respuesta.user != null &&\n        (respuesta.user!.identities?.isEmpty ?? false)) {\n      throw const CorreoYaRegistradoException();\n    }\n\n    return respuesta.session != null;
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

  Future<void> actualizarPerfilCliente({
    required String nombre,
    required String apellido,
    required String telefono,
  }) async {
    final usuario = usuarioActual;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión para actualizar tu perfil.');
    }

    await _supabase
        .from('perfiles_clientes')
        .update({
          'nombre': nombre.trim(),
          'apellido': apellido.trim(),
          'telefono': telefono.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('auth_user_id', usuario.id);
  }

  Future<String> actualizarFotoPerfil({
    required Uint8List bytes,
    required String extension,
    required String contentType,
  }) async {
    final usuario = usuarioActual;
    if (usuario == null) {
      throw Exception('Debes iniciar sesión para cambiar tu fotografía.');
    }

    if (bytes.isEmpty || bytes.length > 2 * 1024 * 1024) {
      throw Exception('La imagen debe pesar como máximo 2 MB.');
    }

    const extensionesPermitidas = {'jpg', 'jpeg', 'png', 'webp'};
    if (!extensionesPermitidas.contains(extension.toLowerCase()) ||
        !const {
          'image/jpeg',
          'image/png',
          'image/webp',
        }.contains(contentType)) {
      throw Exception('Usa una imagen JPG, PNG o WEBP.');
    }

    final ruta = '${usuario.id}/avatar.${extension.toLowerCase()}';
    final storage = _supabase.storage.from('perfiles-clientes');

    await storage.uploadBinary(
      ruta,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: true,
      ),
    );

    final url = '${storage.getPublicUrl(ruta)}?v=${DateTime.now().millisecondsSinceEpoch}';

    await _supabase
        .from('perfiles_clientes')
        .update({
          'foto_url': url,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('auth_user_id', usuario.id);

    return url;
  }

  Future<void> cambiarPassword({
    required String passwordActual,
    required String passwordNuevo,
  }) async {
    if (usuarioActual == null) {
      throw Exception('Debes iniciar sesión para cambiar tu contraseña.');
    }

    await _supabase.auth.updateUser(
      UserAttributes(
        password: passwordNuevo,
        currentPassword: passwordActual,
      ),
    );
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }
}
