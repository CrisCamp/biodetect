import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/datos.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CapturaFoto extends StatefulWidget {
  const CapturaFoto({super.key});

  @override
  State<CapturaFoto> createState() => _CapturaFotoState();
}

class _CapturaFotoState extends State<CapturaFoto> {
  File? _image;
  bool _isProcessing = false;

  Future<void> _tomarFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _seleccionarGaleria() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _analizarFoto() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una foto.')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Simular análisis de IA
      await Future.delayed(const Duration(seconds: 2));
      
      // Resultado simulado - aquí integrarás tu IA real
      const String ordenTaxonomico = 'Lepidoptera';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden taxonómico reconocido: Lepidoptera'),
            backgroundColor: AppColors.buttonGreen2,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegDatos(
              imageFile: _image!,
              ordenTaxonomico: ordenTaxonomico,
            ),
          ),
        );
        
        // Si se guardó correctamente, limpiar la imagen
        if (result == 'saved') {
          setState(() {
            _image = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la foto: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: AppColors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Nueva Fotografía',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Vista previa de la imagen o espacio vacío
                  Container(
                    height: 440,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.buttonGreen2,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _image == null
                        ? const Text(
                            'Aquí se mostrará la foto',
                            style: TextStyle(
                              color: AppColors.textPaleGreen,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_image!, fit: BoxFit.cover, width: double.infinity, height: 440),
                          ),
                  ),
                  const SizedBox(height: 20),
                  // Botones de captura y galería
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonGreen2,
                            foregroundColor: AppColors.textBlack,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _tomarFoto,
                          child: const Text(
                            'Capturar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBrown3,
                            foregroundColor: AppColors.textBlack,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          onPressed: _seleccionarGaleria,
                          child: const Text(
                            'Galería',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Requisitos de calidad
                  Card(
                    color: AppColors.backgroundCard,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asegúrate de:',
                            style: TextStyle(
                              color: AppColors.buttonGreen2,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '• Enfocar bien el insecto/arácnido',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '• Buena iluminación',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '• Sin objetos distractores',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Botón para ir a la vista de datos
                  ElevatedButton.icon(
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.textWhite,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(Icons.arrow_forward, color: AppColors.textWhite),
                    label: Text(
                      _isProcessing ? 'Procesando...' : 'Continuar con datos',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) {
                          if (states.contains(MaterialState.pressed) || states.contains(MaterialState.hovered)) {
                            return AppColors.buttonGreen2.withOpacity(0.18);
                          }
                          return AppColors.buttonBlue2;
                        },
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all(const Size(0, 48)),
                      elevation: MaterialStateProperty.all(_isProcessing ? 0 : 4),
                      shadowColor: MaterialStateProperty.all(AppColors.buttonBlue2),
                    ),
                    onPressed: _isProcessing ? null : _analizarFoto,
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