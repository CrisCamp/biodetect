import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/datos.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
      // Convertir la imagen a bytes
      final bytes = await _image!.readAsBytes();

      // Crear la solicitud multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.3:5000/predict'), // Aquí cambia tu IP por la de tu máquina
      );

      // Agregar la imagen al request
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'image.jpg',
        contentType: MediaType('image', 'jpg'),
      ));

      // Enviar la solicitud
      final response = await request.send();

      // Verificar el estado de la respuesta
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseData);

        final String ordenTaxonomico = jsonResponse['predicted_class'];
        List<String> taxonomia = ordenTaxonomico.split('-');
        final double confianza = jsonResponse['confidence'];

        if (mounted) {
          String claseArtropodo = '';
          String ordenTaxonomico = '';
          String mensaje = '';
          if (confianza >= 0.75) {
            claseArtropodo = taxonomia[0];
            ordenTaxonomico = taxonomia[1];
            //mensaje = 'Clase: $claseArtropodo. Orden: $ordenTaxonomico.\nConfianza: (${(confianza * 100).toStringAsFixed(2)}%)';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Clase: $claseArtropodo. Orden: $ordenTaxonomico.\nConfianza: (${(confianza * 100).toStringAsFixed(2)}%)'),
                backgroundColor: AppColors.buttonGreen2,
              ),
            );

            await Future.delayed(const Duration(milliseconds: 1000));

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegDatos(
                  imageFile: _image!,
                  claseArtropodo: taxonomia[0],  // "Insecta"
                  ordenTaxonomico: taxonomia[1], // "Orthoptera"
                ),
              ),
            );

            // Si se guardó correctamente, limpiar la imagen
            if (result == 'saved') {
              setState(() {
                _image = null;
              });
            }
          } else {
            if (mounted) {
              showDialog<void>(
                context: context,
                barrierDismissible: false, // El usuario debe seleecionar un botón para cerrar
                builder: (BuildContext dialogContext) {
                  return AlertDialog(
                    title: const Text('Confianza Insuficiente'),
                    content: const SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text('No se alcanzó el nivel de confianza adecuado para la identificación automática.'),
                        ],
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Aceptar'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Cierra el diálogo
                        },
                      ),
                      TextButton(
                        child: const Text('Enviar para revisión'),
                        onPressed: () {
                          Navigator.of(dialogContext).pop(); // Cierra el diálogo
                          _enviarRevision();
                        },
                      ),
                    ],
                  );
                },
              );
            }
          }

        }
      } else {
        final errorData = await response.stream.bytesToString();
        final errorJson = jsonDecode(errorData);
        throw Exception(errorJson['error'] ?? 'Error desconocido del servidor');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar la foto: ${e.toString()}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _enviarRevision() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final photoId = FirebaseFirestore.instance.collection('unidentified').doc().id;

    // Subir imagen a Storage
    final ref = FirebaseStorage.instance.ref().child('unidentified/${user.uid}/$photoId.jpg');
    await ref.putFile(_image!);
    final imageUrl = await ref.getDownloadURL();

    // Crear documento en Firestore
    await FirebaseFirestore.instance.collection('unidentified').doc(photoId).set({
      'userId': user.uid,
      'imageUrl': imageUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'status': 'Pending'
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gracias por su apoyo.'),
          backgroundColor: AppColors.buttonGreen2,
        ),
      );
    }
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
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom, // Altura de la pantalla menos el padding del SafeArea
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    // Requisitos de calidad
                    Visibility(
                      visible: _image == null,
                      //maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Card(
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
                                '• Tener buena iluminación',
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
                    ),
                    const SizedBox(height: 30),
                    // Botón para ir a la vista de datos
                    Visibility(
                      visible: _image != null,
                      //maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: ElevatedButton.icon(
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
                          _isProcessing ? 'Procesando...' : 'Analizar',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}