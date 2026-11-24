import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../services/qr_pago_admin_service.dart';

class QrPagoAdminScreen extends StatefulWidget {
  const QrPagoAdminScreen({super.key});

  @override
  State<QrPagoAdminScreen> createState() => _QrPagoAdminScreenState();
}

class _QrPagoAdminScreenState extends State<QrPagoAdminScreen> {
  String? _qrUrl;
  Uint8List? _imagenRecortada;
  bool _cargando = true;
  bool _seleccionando = false;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final url = await QrPagoAdminService.instance.obtenerUrlActual();
      if (mounted) setState(() => _qrUrl = url);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _seleccionarYRecortar() async {
    if (_seleccionando || _guardando) return;
    setState(() => _seleccionando = true);

    try {
      final archivo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );
      if (archivo == null || !mounted) return;

      final bytesOriginales = await archivo.readAsBytes();
      if (!mounted) return;
      if (bytesOriginales.isEmpty ||
          bytesOriginales.length > 10 * 1024 * 1024) {
        throw Exception('Selecciona una imagen de hasta 10 MB para recortarla.');
      }

      final recortado = await ImageCropper().cropImage(
        sourcePath: archivo.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        maxWidth: 1200,
        maxHeight: 1200,
        compressFormat: ImageCompressFormat.png,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Recortar código QR',
            toolbarColor: AppTheme.naranja,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          IOSUiSettings(
            title: 'Recortar código QR',
            aspectRatioPresets: const [CropAspectRatioPreset.square],
          ),
          WebUiSettings(context: context),
        ],
      );

      if (recortado == null || !mounted) return;

      final bytes = await recortado.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw Exception(
          'La imagen recortada debe pesar como máximo 5 MB. '
          'Intenta recortar una zona más pequeña.',
        );
      }

      setState(() => _imagenRecortada = bytes);
      _mensaje('Recorte listo. Revisa la vista previa y guarda el QR.');
    } catch (error) {
      if (!mounted) return;
      _mensaje(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _seleccionando = false);
    }
  }

  Future<void> _guardar() async {
    final bytes = _imagenRecortada;
    if (bytes == null || _guardando) return;

    setState(() => _guardando = true);
    try {
      final url = await QrPagoAdminService.instance.actualizarQr(bytes);
      if (!mounted) return;

      setState(() {
        _qrUrl = url;
        _imagenRecortada = null;
      });
      _mensaje('QR de pago actualizado. Los nuevos pedidos usarán esta imagen.');
    } catch (error) {
      if (!mounted) return;
      _mensaje(
        error.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _mensaje(String texto, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.naranja),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _cargar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QR de pago',
                style: TextStyle(
                  color: AppTheme.marron,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Reemplaza el código cuando el QR bancario cambie o venza.',
                style: TextStyle(color: AppTheme.textoSecundario),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.borde),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Vista previa',
                            style: TextStyle(
                              color: AppTheme.marron,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (_imagenRecortada != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F3EC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Nuevo QR',
                              style: TextStyle(
                                color: Color(0xFF39845A),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: MediaQuery.sizeOf(context).width < 400 ? 180 : 300,
                      constraints: const BoxConstraints(maxWidth: 300),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.crema,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: _construirImagenQr(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Recorta en formato cuadrado y centra el código QR. '
                      'Evita incluir el nombre del banco, instrucciones o bordes innecesarios.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textoSecundario,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _seleccionando || _guardando
                              ? null
                              : _seleccionarYRecortar,
                          icon: _seleccionando
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.crop),
                          label: Text(
                            _seleccionando
                                ? 'Abriendo recorte...'
                                : _imagenRecortada == null
                                    ? 'Seleccionar y recortar QR'
                                    : 'Cambiar recorte',
                          ),
                        ),
                        if (_imagenRecortada != null)
                          ElevatedButton.icon(
                            onPressed: _guardando ? null : _guardar,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _guardando ? 'Guardando...' : 'Guardar nuevo QR',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4E9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.naranja),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'El QR nuevo se usará en los pedidos que se registren después del cambio. '
                        'Los pedidos que ya tienen la pantalla de pago abierta pueden conservar el QR anterior.',
                        style: TextStyle(
                          color: AppTheme.marron,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirImagenQr() {
    final bytes = _imagenRecortada;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.contain);
    }

    final url = _qrUrl;
    if (url == null || url.trim().isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2_rounded, color: AppTheme.naranja, size: 76),
            SizedBox(height: 8),
            Text(
              'QR no configurado',
              style: TextStyle(color: AppTheme.textoSecundario, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => const Center(
        child: Text(
          'No se pudo cargar la imagen actual.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textoSecundario, fontSize: 12),
        ),
      ),
    );
  }
}
