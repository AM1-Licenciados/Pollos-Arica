import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../models/clima.dart';
import '../models/configuracion_negocio.dart';
import '../services/clima_service.dart';
import '../services/configuracion_negocio_service.dart';

class FichaNegocioScreen extends StatefulWidget {
  const FichaNegocioScreen({super.key});

  @override
  State<FichaNegocioScreen> createState() => _FichaNegocioScreenState();
}

class _FichaNegocioScreenState extends State<FichaNegocioScreen> {
  static const String _claveConfiguracionLocal =
      'pollos_arica_configuracion_negocio';

  late Future<ConfiguracionNegocio> _configuracionFuture;
  late Future<Clima> _climaFuture;

  @override
  void initState() {
    super.initState();
    _configuracionFuture = _obtenerConfiguracionConRespaldo();
    _climaFuture = ClimaService.instance.obtenerClima();
  }

  /// Obtiene primero la configuración actual de Supabase.
  ///
  /// Si Supabase no está disponible, intenta recuperar la última
  /// configuración guardada localmente. Si todavía no existe una copia,
  /// utiliza los datos básicos de Pollos Arica.
  Future<ConfiguracionNegocio> _obtenerConfiguracionConRespaldo() async {
    try {
      final configuracion = await ConfiguracionNegocioService.instance
          .obtenerConfiguracion();

      await _guardarConfiguracionLocal(configuracion);
      return configuracion;
    } catch (_) {
      final configuracionLocal = await _obtenerConfiguracionLocal();
      return configuracionLocal ?? _configuracionPredeterminada;
    }
  }

  ConfiguracionNegocio get _configuracionPredeterminada {
    return const ConfiguracionNegocio(
      nombreNegocio: 'Pollos Arica',
      telefonoWhatsApp: '+59161370096',
      telefonoLlamadas: '+59161370096',
      direccion: 'Av. Paurito / Calle las Américas #6',
      latitud: -17.8311294,
      longitud: -63.1341483,
    );
  }

  Future<void> _guardarConfiguracionLocal(
    ConfiguracionNegocio configuracion,
  ) async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      await preferencias.setString(
        _claveConfiguracionLocal,
        jsonEncode({
          'nombre_negocio': configuracion.nombreNegocio,
          'telefono_whatsapp': configuracion.telefonoWhatsApp,
          'telefono_llamadas': configuracion.telefonoLlamadas,
          'direccion': configuracion.direccion,
          'latitud': configuracion.latitud,
          'longitud': configuracion.longitud,
        }),
      );
    } catch (_) {
      // La caché es opcional: un fallo al guardarla no debe interrumpir
      // la visualización de la ficha del restaurante.
    }
  }

  Future<ConfiguracionNegocio?> _obtenerConfiguracionLocal() async {
    try {
      final preferencias = await SharedPreferences.getInstance();
      final contenido = preferencias.getString(_claveConfiguracionLocal);

      if (contenido == null || contenido.isEmpty) return null;

      final decoded = jsonDecode(contenido);
      if (decoded is! Map<String, dynamic>) return null;

      return ConfiguracionNegocio.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _recargar() async {
    setState(() {
      _configuracionFuture = _obtenerConfiguracionConRespaldo();
      _climaFuture = ClimaService.instance.obtenerClima();
    });
  }

  Future<void> _abrirUrl(Uri uri, String accion) async {
    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!abierto) {
        throw Exception('No se pudo abrir $accion.');
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _abrirWhatsApp(ConfiguracionNegocio config) async {
    final numero = config.telefonoWhatsApp.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (numero.isEmpty) {
      _mostrarMensaje('El WhatsApp todavía no está configurado.');
      return;
    }

    final uri = Uri.https(
      'wa.me',
      '/$numero',
      {
        'text':
            '¡Hola! Quisiera consultar sobre los productos de Pollos Arica.',
      },
    );

    await _abrirUrl(uri, 'WhatsApp');
  }

  Future<void> _llamar(ConfiguracionNegocio config) async {
    final numero = config.telefonoLlamadas.isNotEmpty
        ? config.telefonoLlamadas
        : config.telefonoWhatsApp;

    final limpio = numero.replaceAll(RegExp(r'[^0-9+]'), '');

    if (limpio.isEmpty) {
      _mostrarMensaje('El teléfono todavía no está configurado.');
      return;
    }

    await _abrirUrl(
      Uri(scheme: 'tel', path: limpio),
      'el marcador telefónico',
    );
  }

  Future<void> _comoLlegar(ConfiguracionNegocio config) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': '${config.latitud},${config.longitud}',
      },
    );

    await _abrirUrl(uri, 'la aplicación de mapas');
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
        title: const Text('Ubicación y contacto'),
        backgroundColor: AppTheme.crema,
        foregroundColor: AppTheme.marron,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ConfiguracionNegocio>(
        future: _configuracionFuture,
        builder: (context, snapshot) {
          // La configuración siempre dispone de un respaldo local.
          // Este estado de carga solo aparece mientras se intenta obtener
          // Supabase y consultar la caché local.
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.naranja,
              ),
            );
          }

          final config = snapshot.data ?? _configuracionPredeterminada;
          final centro = LatLng(config.latitud, config.longitud);

          return RefreshIndicator(
            color: AppTheme.naranja,
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                Text(
                  config.nombreNegocio,
                  style: const TextStyle(
                    color: AppTheme.marron,
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Con el sazón de la casa',
                  style: TextStyle(
                    color: AppTheme.textoSecundario,
                  ),
                ),
                const SizedBox(height: 18),

                // Open-Meteo funciona de manera independiente de Supabase.
                _TarjetaClima(
                  future: _climaFuture,
                  onReintentar: () {
                    setState(() {
                      _climaFuture = ClimaService.instance.obtenerClima(
                        latitud: config.latitud,
                        longitud: config.longitud,
                      );
                    });
                  },
                ),

                const SizedBox(height: 20),
                const Text(
                  'Estamos aquí',
                  style: TextStyle(
                    color: AppTheme.marron,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    height: 260,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: centro,
                        initialZoom: 16,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.all,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.pollosarica',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: centro,
                              width: 56,
                              height: 64,
                              child: const Icon(
                                Icons.location_on,
                                color: AppTheme.naranja,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                        RichAttributionWidget(
                          attributions: [
                            TextSourceAttribution(
                              '© OpenStreetMap contributors',
                              onTap: () => _abrirUrl(
                                Uri.parse(
                                  'https://www.openstreetmap.org/copyright',
                                ),
                                'OpenStreetMap',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (config.direccion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        color: AppTheme.naranja,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          config.direccion,
                          style: const TextStyle(
                            color: AppTheme.textoSecundario,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 18),
                _BotonAccion(
                  icono: Icons.directions_outlined,
                  texto: 'Cómo llegar',
                  onPressed: () => _comoLlegar(config),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BotonAccion(
                        icono: Icons.chat_bubble_outline,
                        texto: 'WhatsApp',
                        color: const Color(0xFF218B50),
                        onPressed: () => _abrirWhatsApp(config),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BotonAccion(
                        icono: Icons.phone_outlined,
                        texto: 'Llamar',
                        onPressed: () => _llamar(config),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaClima extends StatelessWidget {
  final Future<Clima> future;
  final VoidCallback onReintentar;

  const _TarjetaClima({
    required this.future,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFEDE0D3),
        ),
      ),
      child: FutureBuilder<Clima>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.naranja,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Consultando el clima de Santa Cruz...',
                  style: TextStyle(
                    color: AppTheme.textoSecundario,
                  ),
                ),
              ],
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Row(
              children: [
                const Icon(
                  Icons.cloud_off_outlined,
                  color: AppTheme.naranja,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'No se pudo consultar el clima. '
                    'Comprueba tu conexión.',
                    style: TextStyle(
                      color: AppTheme.textoSecundario,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Reintentar clima',
                  onPressed: onReintentar,
                  icon: const Icon(
                    Icons.refresh,
                    color: AppTheme.naranja,
                  ),
                ),
              ],
            );
          }

          final clima = snapshot.data!;

          return Row(
            children: [
              Text(
                clima.icono,
                style: const TextStyle(fontSize: 38),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Clima actual · Santa Cruz',
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      clima.descripcion,
                      style: const TextStyle(
                        color: AppTheme.marron,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Sensación ${clima.sensacionTermica.toStringAsFixed(0)}° · '
                      'Humedad ${clima.humedad}%',
                      style: const TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${clima.temperatura.toStringAsFixed(0)}°',
                style: const TextStyle(
                  color: AppTheme.marron,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onPressed;
  final Color color;

  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.onPressed,
    this.color = AppTheme.naranja,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icono,
          color: color,
        ),
        label: Text(
          texto,
          style: const TextStyle(
            color: AppTheme.marron,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: Color(0xFFE8D8C8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
