import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/datos.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhotoService {
  static Future<Map<String, dynamic>> uploadAndRegisterPhoto(File imageFile, String userId) async {
    final photoId = FirebaseFirestore.instance.collection('insect_photos').doc().id;
    final ref = FirebaseStorage.instance.ref().child('insect_photos/$userId/original/$photoId.jpg');
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    final docRef = FirebaseFirestore.instance.collection('insect_photos').doc(photoId);
    await docRef.set({
      'userId': userId,
      'imageUrl': imageUrl,
      'localPath': imageFile.path,
      'uploadedAt': FieldValue.serverTimestamp(),
      'class': '',
      'taxonOrder': '',
      'name': '',
      'coords': {},
      'habitat': '',
      'verificationDate': null,
      'details': '',
      'notes': '',
      'driveFolderId': '',
    });
    return {'photoId': photoId, 'imageUrl': imageUrl, 'docRef': docRef};
  }

  static Future<Map<String, dynamic>> analyzePhotoWithIA(String imageUrl) async {
    await Future.delayed(const Duration(seconds: 2));
    bool recognized = true; // TODO: Integrar IA real

    if (recognized) {
      return {
        'success': true,
        'taxonOrder': 'Lepidoptera',
      };
    } else {
      return {
        'success': false,
        'message': 'No se pudo identificar el orden taxonómico',
      };
    }
  }

  static Future<void> saveUnidentifiedPhoto({
    required String userId,
    required String imageUrl,
    required String photoId,
  }) async {
    await FirebaseFirestore.instance.collection('unidentified_photos').doc(photoId).set({
      'userId': userId,
      'imageUrl': imageUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para continuar.')),
      );
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final result = await PhotoService.uploadAndRegisterPhoto(_image!, user.uid);
      final photoId = result['photoId'];
      final imageUrl = result['imageUrl'];
      final docRef = result['docRef'];

      final iaResult = await PhotoService.analyzePhotoWithIA(imageUrl);

      if (iaResult['success'] == true && iaResult['taxonOrder'] != null && iaResult['taxonOrder'].toString().isNotEmpty) {   
        await docRef.update({
          'taxonOrder': iaResult['taxonOrder'],
          'verificationDate': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orden taxonómico reconocido: ${iaResult['taxonOrder']}'),
              backgroundColor: AppColors.buttonGreen2,
            ),
          );
          await Future.delayed(const Duration(milliseconds: 800));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegDatos(
                photoId: photoId,
                imageUrl: imageUrl,
                ordenTaxonomico: iaResult['taxonOrder'],
              ),
            ),
          );
        }
      } else {
        await PhotoService.saveUnidentifiedPhoto(
          userId: user.uid,
          imageUrl: imageUrl,
          photoId: photoId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo identificar el orden taxonómico. Tu foto será revisada por un administrador.'),      
              backgroundColor: AppColors.warning,
            ),
          );
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
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
                  // Botón para ir a la vista de datos (como ventana flotante)
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
                    onPressed: _isProcessing ? null : () async {
                      await _analizarFoto();
                    },
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