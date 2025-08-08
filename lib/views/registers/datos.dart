import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/services/offline_storage_service.dart';
import 'package:biodetect/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class RegDatos extends StatefulWidget {
  final File? imageFile;
  final String? photoId;
  final String? imageUrl;
  final String ordenTaxonomico;
  final Map<String, dynamic>? datosIniciales;

  const RegDatos({
    super.key,
    this.imageFile,
    this.photoId,
    this.imageUrl,
    required this.ordenTaxonomico,
    this.datosIniciales,
  });

  @override
  State<RegDatos> createState() => _RegDatosState();
}

class _RegDatosState extends State<RegDatos> {
  final _formKey = GlobalKey<FormState>();
  String taxonOrder = '';
  String className = '';
  String habitat = '';
  String details = '';
  String notes = '';
  double lat = 0;
  double lon = 0;
  String? currentImageUrl;
  bool _isEditing = false;
  bool _isProcessing = false;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    taxonOrder = widget.ordenTaxonomico;
    _isEditing = widget.photoId != null;
    currentImageUrl = widget.imageUrl;
    
    _checkInternetConnection();
    
    if (widget.datosIniciales != null) {
      _loadDatosFromParam();
    } else if (_isEditing) {
      _loadPhotoData();
    }
  }

  Future<void> _checkInternetConnection() async {
    final hasInternet = await SyncService.hasInternetConnection();
    setState(() {
      _hasInternet = hasInternet;
    });
  }

  void _loadDatosFromParam() {
    final data = widget.datosIniciales!;
    setState(() {
      taxonOrder = data['taxonOrder'] ?? '';
      className = data['class'] ?? '';
      habitat = data['habitat'] ?? '';
      details = data['details'] ?? '';
      notes = data['notes'] ?? '';
      if (data['coords'] != null) {
        lat = data['coords']['x'] ?? 0;
        lon = data['coords']['y'] ?? 0;
      }
    });
  }

  Future<void> _loadPhotoData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('insect_photos').doc(widget.photoId).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          taxonOrder = data['taxonOrder'] ?? '';
          className = data['class'] ?? '';
          habitat = data['habitat'] ?? '';
          details = data['details'] ?? '';
          notes = data['notes'] ?? '';
          if (data['coords'] != null) {
            lat = data['coords']['x'] ?? 0;
            lon = data['coords']['y'] ?? 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  Future<void> _actualizarActividadUsuario(String userId, {bool isIncrement = true}) async {
    if (!_hasInternet) return; // Skip si no hay internet, se sincronizará después
    
    final activityRef = FirebaseFirestore.instance.collection('user_activity').doc(userId);
    final increment = isIncrement ? 1 : -1;
    
    await activityRef.set({
      'userId': userId,
      'photosUploaded': FieldValue.increment(increment),
      'speciesIdentified.total': FieldValue.increment(increment),
      'speciesIdentified.byTaxon.$taxonOrder': FieldValue.increment(increment),
      'lastActivity': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _guardarDatos() async {
    if (_isProcessing) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    try {
      if (_isEditing) {
        // Modo edición: solo online (las fotos offline no se pueden editar hasta sincronizar)
        if (!_hasInternet) {
          throw Exception('Se requiere conexión a internet para editar registros sincronizados');
        }
        
        final docRef = FirebaseFirestore.instance.collection('insect_photos').doc(widget.photoId);
        await docRef.update({
          'taxonOrder': taxonOrder,
          'class': className,
          'habitat': habitat,
          'details': details,
          'notes': notes,
          'coords': {'x': lat, 'y': lon},
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos actualizados correctamente')),
          );
          Navigator.of(context).pop(true);
        }
        
      } else {
        // Modo nuevo: puede ser online u offline
        if (_hasInternet) {
          // Guardar online (comportamiento original)
          await _guardarOnline(user.uid);
        } else {
          // Guardar offline
          await _guardarOffline(user.uid);
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _guardarOnline(String userId) async {
    final photoId = FirebaseFirestore.instance.collection('insect_photos').doc().id;
    
    // Subir imagen a Storage
    final ref = FirebaseStorage.instance.ref().child('insect_photos/$userId/original/$photoId.jpg');
    await ref.putFile(widget.imageFile!);
    final imageUrl = await ref.getDownloadURL();
    
    // Crear documento en Firestore
    await FirebaseFirestore.instance.collection('insect_photos').doc(photoId).set({
      'userId': userId,
      'imageUrl': imageUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'verificationDate': FieldValue.serverTimestamp(),
      'taxonOrder': taxonOrder,
      'class': className,
      'habitat': habitat,
      'details': details,
      'notes': notes,
      'coords': {'x': lat, 'y': lon},
    });
    
    // Actualizar actividad del usuario
    await _actualizarActividadUsuario(userId, isIncrement: true);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos guardados correctamente'),
          backgroundColor: AppColors.buttonGreen2,
        ),
      );
      Navigator.of(context).pop('saved');
    }
  }

  Future<void> _guardarOffline(String userId) async {
    // Guardar en almacenamiento local
    await OfflineStorageService.savePhotoOffline(
      userId: userId,
      imageFile: widget.imageFile!,
      taxonOrder: taxonOrder,
      className: className,
      habitat: habitat,
      details: details,
      notes: notes,
      lat: lat != 0 ? lat : null,
      lon: lon != 0 ? lon : null,
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos guardados offline. Se sincronizarán automáticamente cuando recuperes la conexión.'),
          backgroundColor: AppColors.buttonBrown3,
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop('saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
            child: Column(
              children: [
                Card(
                  color: AppColors.backgroundCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.white, width: 2),
                  ),
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Header con indicador de conexión
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new),
                                color: AppColors.white,
                                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                                iconSize: 28,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      _isEditing ? 'Editar Registro' : 'Datos del Registro',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    // Indicador de conexión
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
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Botón de refresh para verificar conexión
                              IconButton(
                                icon: const Icon(Icons.refresh),
                                color: AppColors.white,
                                onPressed: _isProcessing ? null : _checkInternetConnection,
                                iconSize: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Imagen
                          Card(
                            color: AppColors.backgroundCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.white, width: 1),
                            ),
                            elevation: 4,
                            margin: EdgeInsets.zero,
                            child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _isEditing && currentImageUrl != null
                                    ? Image.network(currentImageUrl!, fit: BoxFit.cover)
                                    : (widget.imageFile != null 
                                        ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                                        : Container(
                                            color: AppColors.paleGreen.withOpacity(0.2),
                                            child: const Icon(Icons.image_outlined, color: AppColors.textPaleGreen, size: 80),
                                          )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Formulario
                          Column(
                            children: [
                              // Orden taxonómico SOLO LECTURA
                              TextFormField(
                                initialValue: taxonOrder,
                                enabled: !_isProcessing,
                                decoration: InputDecoration(
                                  labelText: 'Orden taxonómico',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                                readOnly: true,
                              ),
                              const SizedBox(height: 16),
                              // Clase
                              TextFormField(
                                initialValue: className,
                                enabled: !_isProcessing,
                                onChanged: (v) => className = v,
                                decoration: InputDecoration(
                                  labelText: 'Clase',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Ubicación
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonBlue1,
                                        foregroundColor: AppColors.textWhite,
                                        elevation: _isProcessing ? 0 : 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      onPressed: _isProcessing ? null : () async {
                                        LocationPermission permission = await Geolocator.checkPermission();
                                        if (permission == LocationPermission.denied) {
                                          permission = await Geolocator.requestPermission();
                                          if (permission == LocationPermission.denied) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Permiso de ubicación denegado')),
                                            );
                                            return;
                                          }
                                        }
                                        if (permission == LocationPermission.deniedForever) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
                                          );
                                          return;
                                        }
                                        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                        setState(() {
                                          lat = position.latitude;
                                          lon = position.longitude;
                                        });
                                      },
                                      child: const Text('Obtener ubicación'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Lat: $lat\nLon: $lon',
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Hábitat
                              DropdownButtonFormField<String>(
                                value: habitat.isNotEmpty ? habitat : null,
                                decoration: InputDecoration(
                                  labelText: 'Hábitat',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                dropdownColor: AppColors.paleGreen,
                                items: const [
                                  DropdownMenuItem(value: 'Bosque', child: Text('Bosque')),
                                  DropdownMenuItem(value: 'Selva', child: Text('Selva')),
                                  DropdownMenuItem(value: 'Desierto', child: Text('Desierto')),
                                  DropdownMenuItem(value: 'Urbano', child: Text('Urbano')),
                                ],
                                onChanged: _isProcessing ? null : (value) => setState(() => habitat = value ?? ''),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Detalles
                              TextFormField(
                                initialValue: details,
                                enabled: !_isProcessing,
                                onChanged: (v) => details = v,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Detalles del hallazgo',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Notas
                              TextFormField(
                                initialValue: notes,
                                enabled: !_isProcessing,
                                onChanged: (v) => notes = v,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Notas u observaciones',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 24),
                              // Botón guardar/actualizar
                              Row(
                                children: [
                                  Expanded(
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
                                          : Icon(_hasInternet ? Icons.cloud_upload : Icons.save),
                                      label: Text(
                                        _isProcessing 
                                            ? (_isEditing ? 'Actualizando...' : (_hasInternet ? 'Guardando online...' : 'Guardando offline...'))
                                            : (_isEditing ? 'Actualizar' : (_hasInternet ? 'Guardar' : 'Guardar offline')),
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _hasInternet ? AppColors.buttonBlue2 : AppColors.buttonBrown3,
                                        foregroundColor: AppColors.textWhite,
                                        elevation: _isProcessing ? 0 : 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      onPressed: _isProcessing ? null : _guardarDatos,
                                    ),
                                  ),
                                ],
                              ),
                              if (!_hasInternet && !_isEditing) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.warning, width: 1),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Sin conexión. Los datos se guardarán localmente y se sincronizarán automáticamente cuando recuperes la conexión.',
                                          style: TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}