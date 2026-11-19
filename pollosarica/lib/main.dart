
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/bienvenida/bienvenida_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!SupabaseConfig.isConfigured) {
    throw Exception(
      'Faltan las credenciales de conexión de Supabase.',
    );
  }

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );

  runApp(const PollosAricaApp());
}

class PollosAricaApp extends StatelessWidget {
  const PollosAricaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pollos Arica',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const BienvenidaScreen(),
    );
  }
}
