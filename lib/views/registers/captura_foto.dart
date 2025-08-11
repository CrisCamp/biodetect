import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/datos.dart';
import 'package:biodetect/services/pending_photos_service.dart';
import 'package:biodetect/services/ai_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode

class CapturaFoto extends StatefulWidget {
  const CapturaFoto({super.key});

  @override
  State<CapturaFoto> createState() => _CapturaFotoState();
}

class _CapturaFotoState extends State<CapturaFoto> {
  File? _image;
  bool _isProcessing = false;
  bool _hasInternet = true;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _checkInternetConnection();
    _getCurrentLocation();
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      setState(() {
        _hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
    } catch (_) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Cambiar print por debugPrint
      if (kDebugMode) {
        debugPrint('Error obteniendo ubicación: $e');
      }
    }
  }

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
    if (!mounted) return; // Verificar mounted antes de setState
    
    setState(() => _isProcessing = true);

    if (_image == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primero selecciona una foto.')),
        );
        setState(() => _isProcessing = false);
      }
      return;
    }

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    await _checkInternetConnection();

    if (!_hasInternet) {
      await _guardarPendiente(user.uid);
      return;
    }

    try {
      final Map<String, dynamic> response = await AIService.analyzeImage(_image!);

      final String ordenTaxonomico = response['predicted_class'];
      final List<String> taxonomia = ordenTaxonomico.split('-');
      final double confianza = response['confidence'];

      if (mounted) {
        if (confianza >= 0.75) {
          final String claseArtropodo = taxonomia[0];
          final String ordenTaxonomicoFinal = taxonomia[1];
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Clase: $claseArtropodo. Orden: $ordenTaxonomicoFinal.\nConfianza: (${(confianza * 100).toStringAsFixed(2)}%)'),
              backgroundColor: AppColors.buttonGreen2,
            ),
          );

          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted) {
            final dynamic result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegDatos(
                  imageFile: _image!,
                  claseArtropodo: claseArtropodo,
                  ordenTaxonomico: ordenTaxonomicoFinal,
                ),
              ),
            );

            if (result == 'saved' && mounted) {
              setState(() {
                _image = null;
              });
            }
          }
        } else {
          await _mostrarOpcionesBajaConfianza();
        }
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

  Future<void> _guardarPendiente(String userId) async {
    try {
      await PendingPhotosService.savePendingPhoto(
        userId: userId,
        imageFile: _image!,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto guardada como pendiente. Se clasificará cuando tengas conexión.'),
            backgroundColor: AppColors.buttonBrown3,
            duration: Duration(seconds: 3),
          ),
        );
        
        setState(() {
          _image = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  Future<void> _mostrarOpcionesBajaConfianza() async {
    if (!mounted) return;
    
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            'Confianza Insuficiente',
            style: TextStyle(color: AppColors.textWhite),
          ),
          content: const Text(
            'No se alcanzó el nivel de confianza adecuado para la identificación automática.',
            style: TextStyle(color: AppColors.textWhite),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Guardar como pendiente',
                style: TextStyle(color: AppColors.buttonBrown3),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final User? user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  _guardarPendiente(user.uid);
                }
              },
            ),
            TextButton(
              child: const Text(
                'Enviar para revisión',
                style: TextStyle(color: AppColors.buttonBlue2),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _enviarRevision();
              },
            ),
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textPaleGreen),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _enviarRevision() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      setState(() => _isProcessing = true);

      final photoId = FirebaseFirestore.instance.collection('unidentified').doc().id;

      final ref = FirebaseStorage.instance.ref().child('unidentified/${user.uid}/$photoId.jpg');
      await ref.putFile(_image!);
      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('unidentified').doc(photoId).set({
        'userId': user.uid,
        'imageUrl': imageUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'status': 'Pending'
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto enviada para revisión. Gracias por su apoyo.'),
            backgroundColor: AppColors.buttonGreen2,
          ),
        );
        
        setState(() {
          _image = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
                minHeight: MediaQuery.of(context).size.height - 
                          MediaQuery.of(context).padding.top - 
                          MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new),
                          color: AppColors.white,
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Text(
                                'Nueva Fotografía',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _hasInternet ? AppColors.buttonGreen2 : AppColors.warning,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _hasInternet ? 'En línea' : 'Sin conexión',
                                  style: const TextStyle(
                                    color: AppColors.textBlack,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          color: AppColors.white,
                          onPressed: _checkInternetConnection,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                              child: Image.file(
                                _image!, 
                                fit: BoxFit.cover, 
                                width: double.infinity, 
                                height: 440,
                              ),
                            ),
                    ),
                    const SizedBox(height: 20),
                    if (!_hasInternet && _image == null) ...[
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
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Sin conexión',
                                    style: TextStyle(
                                      color: AppColors.warning,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Las fotos se guardarán como pendientes y se clasificarán automáticamente cuando recuperes la conexión.',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else if (_image == null) ...[
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
                    ],
                    const SizedBox(height: 30),
                    if (_image != null) ...[
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
                            : Icon(
                                _hasInternet ? Icons.psychology : Icons.save,
                                color: AppColors.textWhite,
                              ),
                        label: Text(
                          _isProcessing 
                              ? (_hasInternet ? 'Analizando...' : 'Guardando...')
                              : (_hasInternet ? 'Analizar' : 'Guardar como pendiente'),
                          style: const TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all(
                            _hasInternet ? AppColors.buttonBlue2 : AppColors.buttonBrown3,
                          ),
                          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
                          elevation: WidgetStateProperty.all(_isProcessing ? 0 : 4),
                        ),
                        onPressed: _isProcessing ? null : _analizarFoto,
                      ),
                      const SizedBox(height: 20),
                    ],
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