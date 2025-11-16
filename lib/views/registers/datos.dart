import 'dart:io';
import 'dart:async';
import 'package:biodetect/themes.dart';
import 'package:biodetect/services/profile_notifier.dart';
import 'package:biodetect/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:biodetect/views/badges/galeria_insignias.dart';
import 'package:biodetect/services/google_drive_service.dart';
import 'package:biodetect/views/location/location_picker_screen.dart';

class RegDatos extends StatefulWidget {
  final File? imageFile;
  final String? photoId;
  final String? imageUrl;
  final String? claseArtropodo;
  final String? ordenTaxonomico;
  final Map<String, dynamic>? datosIniciales;
  final Map<String, double>? coordenadas;

  const RegDatos({
    super.key,
    this.imageFile,
    this.photoId,
    this.imageUrl,
    this.claseArtropodo,
    this.ordenTaxonomico,
    this.datosIniciales,
    this.coordenadas,
  });

  @override
  State<RegDatos> createState() => _RegDatosState();
}

class _RegDatosState extends State<RegDatos> {
  // Variables auxiliares para sincronización inmediata
  String? _originalClass;
  String? _originalOrder;
  String? _originalPhotoId;
  final _formKey = GlobalKey<FormState>();
  final _latitudController = TextEditingController();
  final _longitudController = TextEditingController();
  final _detailsController = TextEditingController();
  final _notesController = TextEditingController();
  Timer? _internetCheckTimer;
  
  String taxonOrder = '';
  String className = '';
  String habitat = '';
  String details = '';
  String notes = '';
  String locationVisibility = ''; // Nueva variable para visibilidad de ubicación
  double lat = 0;
  double lon = 0;
  String? currentImageUrl;
  bool _isEditing = false;
  bool _isProcessing = false;
  bool _hasInternet = true;
  bool _isGettingLocation = false;
  bool _isAnalyzing = false;
  Map<String, double> _coords = {};
  
  // Contadores de caracteres para los campos de texto
  int _detailsCharCount = 0;
  int _notesCharCount = 0;
  static const int _maxCharacters = 255;
  
  // Checkbox para proporcionar imagen para mejorar modelo (solo nuevos registros)
  bool _allowImageForModel = true;

  // Expresiones regulares separadas para latitud y longitud
  final RegExp _latitudRegExp = RegExp(r'^-?([0-8]?[0-9](\.[0-9]+)?|90(\.0+)?)$');
  final RegExp _longitudRegExp = RegExp(r'^-?(1[0-7][0-9](\.[0-9]+)?|[0-9]?[0-9](\.[0-9]+)?|180(\.0+)?)$');

  @override
  void initState() {
    super.initState();
    
    _isEditing = widget.photoId != null;

    // Guardar valores originales para sincronización inmediata
    if (_isEditing) {
      _originalPhotoId = widget.photoId;
    }

    if (widget.coordenadas != null) {
      _coords = widget.coordenadas!;
      lat = _coords['x'] ?? 0;
      lon = _coords['y'] ?? 0;
      _latitudController.text = lat != 0 ? lat.toString() : '';
      _longitudController.text = lon != 0 ? lon.toString() : '';
    } else {
      if (!_isEditing) {
        _getCurrentLocation();
      }
    }
    
    className = widget.claseArtropodo ?? '';
    taxonOrder = widget.ordenTaxonomico ?? '';
    currentImageUrl = widget.imageUrl;

    // Inicializar visibilidad de ubicación según el modo
    if (_isEditing) {
      locationVisibility = 'Privada'; // Por defecto privada al editar
    } else {
      locationVisibility = 'Pública'; // Por defecto pública para nuevos registros
    }

    _checkInternetConnection();
    _startInternetMonitoring();

    if (widget.datosIniciales != null) {
      _loadDatosFromParam();
    } else if (_isEditing) {
      _loadPhotoData();
    }

    // Inicializar contadores de caracteres
    _detailsCharCount = details.length;
    _notesCharCount = notes.length;
    
    // Inicializar controllers
    _detailsController.text = details;
    _notesController.text = notes;
  }

  @override
  void dispose() {
    _internetCheckTimer?.cancel();
    _latitudController.dispose();
    _longitudController.dispose();
    _detailsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startInternetMonitoring() {
    // Verificar conexión cada 10 segundos (menos frecuente que detalle_registro)
    _internetCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _checkInternetConnection();
      }
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('dns.google');
      final hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      
      if (mounted && _hasInternet != hasConnection) {
        setState(() {
          _hasInternet = hasConnection;
        });
        
        // Mostrar notificaciones de conexión con iconos
        if (hasConnection) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Conexión a internet restablecida',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: AppColors.buttonGreen2,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Se perdió la conexión a internet',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else if (mounted && _hasInternet != hasConnection) {
        setState(() {
          _hasInternet = hasConnection;
        });
      }
    } catch (_) {
      if (mounted && _hasInternet) {
        setState(() {
          _hasInternet = false;
        });
        
        // Mostrar notificación de pérdida de conexión
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.wifi_off, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Se perdió la conexión a internet',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _loadDatosFromParam() {
    final data = widget.datosIniciales!;
    
    setState(() {
      taxonOrder = data['taxonOrder'] ?? '';
      className = data['class'] ?? '';
      // Guardar valores originales si no se han guardado
      _originalOrder ??= taxonOrder;
      _originalClass ??= className;
      habitat = data['habitat'] ?? '';
      details = data['details'] ?? '';
      notes = data['notes'] ?? '';
      
      final savedVisibility = data['locationVisibility'];
      
      // Solo cambiar si tenemos un valor válido desde los datos
      if (savedVisibility != null && savedVisibility.toString().isNotEmpty) {
        locationVisibility = savedVisibility.toString();
      }
      
      if (data['coords'] != null) {
        lat = data['coords']['x'] ?? 0;
        lon = data['coords']['y'] ?? 0;
        _latitudController.text = lat != 0 ? lat.toString() : '';
        _longitudController.text = lon != 0 ? lon.toString() : '';
      }
      
      // Actualizar contadores de caracteres
      _detailsCharCount = details.length;
      _notesCharCount = notes.length;
      
      // Actualizar controllers
      _detailsController.text = details;
      _notesController.text = notes;
    });
  }

  Future<void> _loadPhotoData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('insect_photos')
          .doc(widget.photoId)
          .get();
          
      if (doc.exists) {
        final data = doc.data()!;
        
        setState(() {
          taxonOrder = data['taxonOrder'] ?? '';
          className = data['class'] ?? '';
          // Guardar valores originales si no se han guardado
          _originalOrder ??= taxonOrder;
          _originalClass ??= className;
          habitat = data['habitat'] ?? '';
          details = data['details'] ?? '';
          notes = data['notes'] ?? '';
          
          final savedVisibility = data['locationVisibility'];
          
          // Solo cambiar si tenemos un valor válido desde la BD
          if (savedVisibility != null && savedVisibility.toString().isNotEmpty) {
            locationVisibility = savedVisibility.toString();
          }
          
          if (data['coords'] != null) {
            lat = data['coords']['x'] ?? 0;
            lon = data['coords']['y'] ?? 0;
            _latitudController.text = lat != 0 ? lat.toString() : '';
            _longitudController.text = lon != 0 ? lon.toString() : '';
          }
          
          // Actualizar contadores de caracteres
          _detailsCharCount = details.length;
          _notesCharCount = notes.length;
          
          // Actualizar controllers
          _detailsController.text = details;
          _notesController.text = notes;
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



  // void _updateCoordinatesFromFields() {
  //   // Actualizar las coordenadas desde los campos de texto
  //   final latText = _latitudController.text.trim();
  //   final lonText = _longitudController.text.trim();
    
  //   if (latText.isNotEmpty && _latitudRegExp.hasMatch(latText)) {
  //     final parsedLat = double.tryParse(latText);
  //     if (parsedLat != null && parsedLat >= -90 && parsedLat <= 90) {
  //       lat = parsedLat;
  //     }
  //   }
    
  //   if (lonText.isNotEmpty && _longitudRegExp.hasMatch(lonText)) {
  //     final parsedLon = double.tryParse(lonText);
  //     if (parsedLon != null && parsedLon >= -180 && parsedLon <= 180) {
  //       lon = parsedLon;
  //     }
  //   }
  // }

  /// SISTEMA DE VERIFICACIONES DE CONEXIÓN PARA CREACIÓN/ACTUALIZACIÓN DE REGISTROS:
  /// 
  /// Este método implementa múltiples verificaciones de conexión a internet durante todo el proceso
  /// para garantizar la integridad de los datos y evitar estados inconsistentes:
  /// 
  /// VERIFICACIONES IMPLEMENTADAS:
  /// 1. Verificación inicial antes de mostrar el indicador de progreso
  /// 2. Verificación final antes de la operación crítica principal
  /// 3. Verificaciones adicionales antes de subir imágenes (solo creación)
  /// 4. Verificaciones antes de crear/actualizar documentos en Firestore
  /// 5. Verificaciones antes de actualizar la actividad del usuario
  /// 
  /// RESULTADO: Si se pierde la conexión en cualquier punto crítico, todo el proceso
  /// se cancela para evitar registros incompletos o actividades de usuario desincronizadas.

  /// Método para subir imagen al dataset (sin verificaciones exhaustivas)
  Future<void> _subirImagenADataset(String userId, String photoId) async {
    try {
      // Normalizar nombres para las carpetas
      final String classFolder = className.toLowerCase();
      final String orderFolder = taxonOrder.toLowerCase();
      
      // Crear la ruta del dataset
      final String datasetPath = 'dataset/$classFolder/$orderFolder/$photoId.jpg';
      
      // Referencia al archivo en el dataset
      final ref = FirebaseStorage.instance.ref().child(datasetPath);
      
      // Subir la imagen al dataset
      await ref.putFile(widget.imageFile!);
      
      print('✅ Imagen subida al dataset: $datasetPath');
    } catch (e) {
      // "Ni modo" - solo log del error, no interrumpir el flujo
      print('⚠️ Error al subir imagen al dataset: $e');
    }
  }

  /// Método principal que implementa el patrón híbrido:
  /// - Batch para operaciones Firestore (atómicas)
  /// - Manejo especial para Firebase Storage
  Future<String> _guardarRegistroAtomico(String userId, String? photoId, String? imageUrl) async {
    print('🔄 Iniciando ${_isEditing ? 'actualización' : 'creación'} atómica del registro');
    
    // FASE 1: Preparar datos para el batch
    final batch = FirebaseFirestore.instance.batch();
    await _prepararActualizacionActividad(userId, batch);
    
    // FASE 2: Manejar Storage (fuera del batch)
    String? finalImageUrl = imageUrl;
    String? finalPhotoId = photoId;
    
    if (!_isEditing) {
      // Solo para registros nuevos: subir imagen
      finalPhotoId = FirebaseFirestore.instance.collection('insect_photos').doc().id;
      
      // Verificación adicional de conexión justo antes de subir imagen
      print('🔍 Verificación final de conectividad antes de subir imagen...');
      try {
        await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        print('✅ Conectividad confirmada para subida de imagen');
      } catch (e) {
        print('❌ Fallo en verificación final - cancelando creación');
        throw Exception('Se perdió la conexión a internet durante el proceso. La creación ha sido cancelada por seguridad.');
      }
      
      final ref = FirebaseStorage.instance
          .ref()
          .child('insect_photos/$userId/original/$finalPhotoId.jpg');
      await ref.putFile(widget.imageFile!);
      finalImageUrl = await ref.getDownloadURL();
      print('✅ Imagen subida a Storage: $finalImageUrl');
    }
    
    // FASE 3: Preparar documento principal en el batch
    final documentRef = FirebaseFirestore.instance.collection('insect_photos').doc(finalPhotoId);
    
    if (_isEditing) {
      // Actualizar registro existente
      batch.update(documentRef, {
        'taxonOrder': taxonOrder,
        'class': className,
        'habitat': habitat,
        'details': details,
        'notes': notes,
        'coords': {'x': lat, 'y': lon},
        'locationVisibility': locationVisibility,
        'lastModifiedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Crear nuevo registro
      batch.set(documentRef, {
        'userId': userId,
        'imageUrl': finalImageUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'lastModifiedAt': FieldValue.serverTimestamp(),
        'syncedAt': null,
        'taxonOrder': taxonOrder,
        'class': className,
        'habitat': habitat,
        'details': details,
        'notes': notes,
        'coords': {'x': lat, 'y': lon},
        'locationVisibility': locationVisibility,
      });
    }
    
    // FASE 4: Ejecutar todas las operaciones Firestore de forma atómica
    try {
      // Verificación final antes del batch commit
      print('🔍 Verificación final de conectividad antes del batch commit...');
      try {
        await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        print('✅ Conectividad final confirmada para batch commit');
      } catch (e) {
        print('❌ Fallo en verificación final - cancelando batch commit');
        throw Exception('Se perdió la conexión a internet durante el proceso. El batch ha sido cancelado por seguridad.');
      }
      
      await batch.commit();
      print('✅ Batch commit exitoso - Todas las operaciones Firestore completadas');
      
      // VERIFICACIÓN FINAL: Confirmar que todo el proceso se completó exitosamente
      print('✅ Proceso completo exitoso - ${_isEditing ? 'Registro actualizado' : 'Registro creado'} y actividad actualizada');
      
      return finalPhotoId!;
      
    } catch (e) {
      print('❌ Error en batch commit: $e');
      
      // ROLLBACK: Intentar eliminar imagen en Storage si fue subida y el batch falló
      if (!_isEditing && finalImageUrl != null) {
        print('🔄 Intentando rollback de Storage...');
        try {
          final ref = FirebaseStorage.instance.refFromURL(finalImageUrl);
          await ref.delete();
          print('✅ Rollback de Storage exitoso - imagen eliminada');
        } catch (rollbackError) {
          print('⚠️ Error en rollback de Storage: $rollbackError');
          print('⚠️ La imagen fue subida a Storage pero el batch falló. Revisar manualmente: $finalImageUrl');
        }
      }
      
      throw Exception('Error en ${_isEditing ? 'actualización' : 'creación'} atómica: $e');
    }
  }

  /// Preparar actualización de actividad de usuario y agregarla al batch
  Future<void> _prepararActualizacionActividad(String userId, WriteBatch batch) async {
    // VERIFICACIÓN 1: Conexión inicial antes de iniciar actualización de actividad
    print('🔍 Verificando conexión inicial para preparación de actividad del usuario...');
    await _checkInternetConnection();
    if (!_hasInternet) {
      print('❌ Sin conexión - cancelando preparación de actividad');
      throw Exception('Se requiere conexión a internet para preparar la actualización de actividad del usuario');
    }

    try {
      final activityRef = FirebaseFirestore.instance.collection('user_activity').doc(userId);
      final increment = _isEditing ? 0 : 1; // Solo incrementar para registros nuevos

      // VERIFICACIÓN 2: Conexión justo antes de operación crítica de lectura
      print('🔍 Verificación final de conectividad antes de leer documento de actividad...');
      try {
        await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        print('✅ Conectividad confirmada para lectura de actividad');
      } catch (e) {
        print('❌ Fallo en verificación final - cancelando lectura de actividad');
        throw Exception('Se perdió la conexión a internet durante la preparación de actividad. El proceso ha sido cancelado por seguridad.');
      }

      if (increment > 0) {
        // Solo actualizar actividad para registros nuevos
        final docSnapshot = await activityRef.get();

        Map<String, dynamic> updateData = {
          'userId': userId,
          'photosUploaded': FieldValue.increment(increment),
          'speciesIdentified.byTaxon.$taxonOrder': FieldValue.increment(increment),
          'speciesIdentified.byClass.$className': FieldValue.increment(increment),
          'lastActivity': FieldValue.serverTimestamp(),
        };

        if (docSnapshot.exists) {
          // El documento existe, verificar si son orden y clase nuevos
          final currentData = docSnapshot.data() as Map<String, dynamic>;

          // Verificar si es un orden nuevo
          final currentByTaxon = currentData['speciesIdentified']?['byTaxon'] as Map<String, dynamic>?;
          final isNewOrder = currentByTaxon == null || !currentByTaxon.containsKey(taxonOrder);

          // Verificar si es una clase nueva
          final currentByClass = currentData['speciesIdentified']?['byClass'] as Map<String, dynamic>?;
          final isNewClass = currentByClass == null || !currentByClass.containsKey(className);

          // Verificar si es un nuevo orden para esta clase específica
          final isNewOrderForClass = isNewOrder; // Si el orden es nuevo globalmente, también es nuevo para la clase

          // Solo incrementar totales si son orden/clase nuevos
          if (isNewOrder) {
            updateData['speciesIdentified.totalByTaxon'] = FieldValue.increment(1);
            print('🆕 New taxon detected: $taxonOrder');
          }

          if (isNewClass) {
            updateData['speciesIdentified.totalByClass'] = FieldValue.increment(1);
            print('🆕 New class detected: $className');
          }

          // Manejar el contador de taxonomías por clase
          if (isNewOrderForClass) {
            updateData['speciesIdentified.byClassTaxonomy.$className'] = FieldValue.increment(1);
            print('🆕 New taxonomy for class $className: $taxonOrder');
          }

          // Agregar actualización al batch
          batch.update(activityRef, updateData);

        } else {
          // El documento no existe, crear uno nuevo con batch
          batch.set(activityRef, {
            'userId': userId,
            'fieldNotesCreated': 0,
            'photosUploaded': 1,
            'speciesIdentified': {
              'byTaxon': {
                taxonOrder: 1,
              },
              'byClass': {
                className: 1,
              },
              'byClassTaxonomy': {
                className: 1,  // Primera taxonomía para esta clase
              },
              'totalByTaxon': 1,
              'totalByClass': 1,
            },
            'lastActivity': FieldValue.serverTimestamp(),
          });
          print('🆕 Creating new user activity document');
        }
        
        print('✅ Actualización de actividad preparada para usuario: $userId');
      } else {
        print('ℹ️ Saltando actualización de actividad (modo edición)');
      }

    } catch (error) {
      print('❌ Error preparando actualización de actividad: $error');
      throw Exception('Error en preparación de actividad del usuario: $error');
    }
  }

  Future<void> _guardarDatos() async {
    if (_isProcessing) return;

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor corrige los errores en el formulario'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Validaciones adicionales para clase, orden y hábitat
    if (className.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una clase de artrópodo'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (taxonOrder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un orden taxonómico'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (habitat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un hábitat'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // VERIFICACIÓN 1: Conexión inicial antes de mostrar proceso
    print('🔍 Verificando conexión inicial antes de ${_isEditing ? 'actualizar' : 'guardar'}...');
    await _checkInternetConnection();
    if (!_hasInternet) {
      String mensaje = _isEditing 
        ? 'Se requiere conexión a internet para actualizar registros. Verifica tu conexión e inténtalo de nuevo.'
        : 'Se requiere conexión a internet para guardar registros. Verifica tu conexión e inténtalo de nuevo.';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Sincronizar valores de los controllers con las variables globales
    // Si están vacíos, usar valores por defecto
    details = _detailsController.text.trim().isEmpty ? 'Sin detalles' : _detailsController.text.trim();
    notes = _notesController.text.trim().isEmpty ? 'Sin notas' : _notesController.text.trim();

    setState(() => _isProcessing = true);

    // Mostrar indicador de progreso
    final operacionTexto = _isEditing ? 'Actualizando' : 'Guardando';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$operacionTexto registro... No cierres la aplicación.',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.slateGreen,
        duration: const Duration(seconds: 30), // Duración larga para cubrir el proceso
      ),
    );

    try {
      // VERIFICACIÓN 2: Conexión justo antes de la operación crítica
      print('🔍 Verificación final de conexión antes de ${_isEditing ? 'actualizar' : 'guardar'}...');
      await _checkInternetConnection();
      if (!_hasInternet) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Se perdió la conexión a internet. ${_isEditing ? 'La actualización' : 'El guardado'} ha sido cancelado por seguridad.',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      print('🔄 Iniciando ${_isEditing ? 'actualización' : 'guardado'} de registro...');

      if (_isEditing) {
        // Obtener datos actuales para comparar clase/orden y estado de sincronización
        final docRef = FirebaseFirestore.instance.collection('insect_photos').doc(widget.photoId);
        final docSnap = await docRef.get();
        final prevData = docSnap.data();
        final prevClass = prevData?['class'] ?? '';
        final prevOrder = prevData?['taxonOrder'] ?? '';
        final prevSyncedAt = prevData?['syncedAt'];

        final classChanged = prevClass != className;
        final orderChanged = prevOrder != taxonOrder;
        final wasSynced = prevSyncedAt != null;

        // Si cambió clase/orden y estaba sincronizado, preguntar al usuario
        if (wasSynced && (classChanged || orderChanged)) {
          final shouldSync = await showDialog<bool>(
            // ignore: use_build_context_synchronously
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppColors.backgroundCard,
              title: const Text('¿Sincronizar cambios en Google Drive?', style: TextStyle(color: AppColors.textWhite)),
              content: const Text(
                'Has cambiado la clase y/o el orden taxonómico de un registro ya sincronizado.\n\n¿Deseas sincronizar el registro editado en Google Drive? (Esto eliminará los archivos anteriores y subirá los nuevos en la carpeta correspondiente).',
                style: TextStyle(color: AppColors.textWhite),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No', style: TextStyle(color: AppColors.warning)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.buttonGreen2),
                  child: const Text('Sí, sincronizar'),
                ),
              ],
            ),
          );

          if (shouldSync == true) {
            // 1. Eliminar archivos viejos de Drive y subir los nuevos usando los valores originales
            try {
              // Usar patrón atómico para actualización con sincronización
              await _guardarRegistroAtomico(user.uid, widget.photoId, currentImageUrl);
              
              // Obtener datos actualizados para metadatos
              final updatedSnap = await docRef.get();
              final updatedData = updatedSnap.data()!;
              
              // Llamar al servicio de Drive usando los valores originales
              await GoogleDriveService.resyncPhotoWithNewClassOrder(
                photoId: _originalPhotoId!,
                prevClass: _originalClass!,
                prevOrder: _originalOrder!,
                newClass: className,
                newOrder: taxonOrder,
                photoData: updatedData,
              );
              
              print('🔄 Resyncing photo ${_originalPhotoId!} from Class $_originalClass, Order $_originalOrder to Class $className, Order $taxonOrder');
              
              // NOTIFICAR AL PERFIL: Informar que se actualizó un registro (puede afectar contadores si cambió clase/orden)
              ProfileNotifier().notifyProfileChanged();
              print('🔔 Notificado al ProfileScreen: registro actualizado con sincronización (cambio de taxonomía)');
              
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.cloud_done, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Datos y archivos sincronizados correctamente en Drive.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.buttonGreen2,
                    duration: Duration(seconds: 3),
                  ),
                );
                Navigator.of(context).pop(true);
              }
              return;
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al sincronizar con Drive: $e')),
                );
              }
              return;
            }
          } else {
            // Usuario NO quiere sincronizar, usar patrón atómico y marcar como pendiente
            try {
              await _guardarRegistroAtomico(user.uid, widget.photoId, currentImageUrl);
              
              // Marcar como pendiente de sincronización
              await docRef.update({'syncedAt': null});
              
              // NOTIFICAR AL PERFIL: Informar que se actualizó un registro (puede afectar contadores si cambió clase/orden)
              ProfileNotifier().notifyProfileChanged();
              print('🔔 Notificado al ProfileScreen: registro actualizado sin sincronización (cambio de taxonomía)');
              
              if (mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Datos actualizados. El registro se marcará como pendiente de sincronización.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.buttonGreen2,
                    duration: const Duration(seconds: 3),
                  ),
                );
                Navigator.of(context).pop(true);
              }
              return;
            } catch (e) {
              throw e; // Re-lanzar para manejo en catch principal
            }
          }
        }

        // Edición normal (sin cambio de clase/orden o no estaba sincronizado)
        // Usar patrón híbrido: Batch para Firestore
        await _guardarRegistroAtomico(user.uid, widget.photoId, currentImageUrl);
        
        // NOTIFICAR AL PERFIL: Informar que se actualizó un registro (edición normal)
        ProfileNotifier().notifyProfileChanged();
        print('🔔 Notificado al ProfileScreen: registro actualizado (edición normal)');
        
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Registro actualizado exitosamente',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: AppColors.buttonGreen2,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // Modo nuevo: usar patrón híbrido para crear registro
        final String newPhotoId = await _guardarRegistroAtomico(user.uid, null, null);
        
        // NOTIFICAR AL PERFIL: Informar que se creó un nuevo registro
        ProfileNotifier().notifyRegistroCreado();
        print('🔔 Notificado al ProfileScreen: nuevo registro creado (Clase: $className, Orden: $taxonOrder)');
        
        // SUBIR AL DATASET: Si el usuario lo permitió, subir imagen al dataset
        if (_allowImageForModel) {
          print('🔄 Subiendo imagen al dataset...');
          await _subirImagenADataset(user.uid, newPhotoId);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Registro guardado exitosamente',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              backgroundColor: AppColors.buttonGreen2,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Pequeña pausa para que se vea el SnackBar antes de las notificaciones
          await Future.delayed(const Duration(milliseconds: 1000));
          
          // Verificar y mostrar notificaciones de nuevas insignias
          try {
            // ignore: use_build_context_synchronously
            await GaleriaInsigniasScreen.checkAndShowNotifications(context);
          } catch (e) {
            // No mostrar error al usuario, ya que el guardado fue exitoso
          }
          
          if (mounted) {
            Navigator.of(context).pop('saved');
          }
        }
      }
    } catch (e) {
      print('❌ Error al ${_isEditing ? 'actualizar' : 'guardar'} registro: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        // Extraer mensaje limpio del error
        String errorMessage = 'No se pudo ${_isEditing ? 'actualizar' : 'guardar'} el registro. Inténtalo de nuevo.';
        IconData errorIcon = Icons.error_outline;
        
        String cleanErrorMessage = e.toString();
        if (cleanErrorMessage.startsWith('Exception: ')) {
          cleanErrorMessage = cleanErrorMessage.substring(11);
        }
        
        final errorString = cleanErrorMessage.toLowerCase();
        
        if (errorString.contains('servidor no está disponible') ||
            errorString.contains('unavailable') ||
            errorString.contains('network') || 
            errorString.contains('internet') || 
            errorString.contains('connection') ||
            errorString.contains('timeout') ||
            errorString.contains('cancelado por seguridad') ||
            errorString.contains('actividad del usuario') ||
            errorString.contains('actividad ha sido cancelada')) {
          errorMessage = 'Problema de conexión. Verifica tu internet e inténtalo de nuevo.';
          errorIcon = Icons.wifi_off;
        } else if (errorString.contains('permisos') ||
                   errorString.contains('permission') || 
                   errorString.contains('unauthorized')) {
          errorMessage = 'No tienes permisos para realizar esta operación.';
          errorIcon = Icons.lock;
        } else if (errorString.contains('sesión ha expirado') ||
                   errorString.contains('inicia sesión')) {
          errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente.';
          errorIcon = Icons.account_circle_outlined;
        } else if (errorString.contains('cuota') ||
                   errorString.contains('quota')) {
          errorMessage = 'Se ha superado el límite de uso. Inténtalo más tarde.';
          errorIcon = Icons.hourglass_empty;
        } else if (errorString.contains('cancelada por seguridad')) {
          errorMessage = cleanErrorMessage;
          errorIcon = Icons.shield_outlined;
        } else if (errorString.length > 10 && errorString.length < 80) {
          errorMessage = cleanErrorMessage;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: () => _guardarDatos(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }



  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;
    
    setState(() => _isGettingLocation = true);
    
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          setState(() => _isGettingLocation = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
        );
        setState(() => _isGettingLocation = false);
        return;
      }
      
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      
      setState(() {
        lat = position.latitude;
        lon = position.longitude;
        _latitudController.text = lat.toStringAsFixed(6);
        _longitudController.text = lon.toStringAsFixed(6);
        _isGettingLocation = false;
      });
      
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación obtenida correctamente'),
          backgroundColor: AppColors.buttonGreen2,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() => _isGettingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    }
  }

  Future<void> _openLocationPicker() async {
    if (_isProcessing) return;

    try {
      // Obtener coordenadas actuales de los campos de texto
      double? currentLat;
      double? currentLon;

      if (_latitudController.text.isNotEmpty) {
        currentLat = double.tryParse(_latitudController.text);
      }
      if (_longitudController.text.isNotEmpty) {
        currentLon = double.tryParse(_longitudController.text);
      }

      // Abrir el selector de ubicación
      final result = await Navigator.of(context).push<Map<String, double>>(
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            initialLatitude: currentLat,
            initialLongitude: currentLon,
            taxonOrder: taxonOrder.isNotEmpty ? taxonOrder : widget.ordenTaxonomico, // Pasar el orden taxonómico
          ),
        ),
      );

      // Si el usuario seleccionó una ubicación, actualizar los campos
      if (result != null && result.containsKey('latitude') && result.containsKey('longitude')) {
        setState(() {
          lat = result['latitude']!;
          lon = result['longitude']!;
          _latitudController.text = lat.toStringAsFixed(6);
          _longitudController.text = lon.toStringAsFixed(6);
        });

        // Mostrar confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación seleccionada desde el mapa'),
            backgroundColor: AppColors.buttonGreen2,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el mapa: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    }
  }

  String? _validateLatitud(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La latitud es requerida';
    }
    
    if (!_latitudRegExp.hasMatch(value.trim())) {
      return 'Formato de latitud inválido';
    }
    
    final lat = double.tryParse(value.trim());
    if (lat == null || lat < -90 || lat > 90) {
      return 'La latitud debe estar entre -90 y 90';
    }
    
    return null;
  }

  String? _validateLongitud(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La longitud es requerida';
    }
    
    if (!_longitudRegExp.hasMatch(value.trim())) {
      return 'Formato de longitud inválido';
    }
    
    final lon = double.tryParse(value.trim());
    if (lon == null || lon < -180 || lon > 180) {
      return 'La longitud debe estar entre -180 y 180';
    }
    
    return null;
  }

  List<DropdownMenuItem<String>> _getClassesArthropods() {
    return [
      'Insecta',
      'Arachnida'
    ].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _getTaxonOrder() {
    return [
      'Acari', // Arachnida
      'Amblypygi', // Arachnida
      'Araneae', // Arachnida
      'Scorpiones', // Arachnida
      'Solifugae', // Arachnida
      'Dermaptera', // Insecta
      'Lepidoptera', // Insecta
      'Mantodea', // Insecta
      'Orthoptera', // Insecta
      'Thysanoptera', // Insecta
    ].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _getFilteredTaxonOrder() {
    // Definir qué órdenes pertenecen a cada clase con tipado explícito
    final Map<String, List<String>> classToOrders = {
      'Arachnida': ['Acari', 'Amblypygi', 'Araneae', 'Scorpiones', 'Solifugae'],
      'Insecta': ['Dermaptera', 'Lepidoptera', 'Mantodea', 'Orthoptera', 'Thysanoptera'],
    };

    // Obtener los órdenes para la clase seleccionada, o lista vacía si no hay clase
    final List<String> orders = className.isNotEmpty
        ? classToOrders[className] ?? <String>[]
        : <String>[];

    return orders.map<DropdownMenuItem<String>>((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  String? _getValidClassesValue() {
    if (className.isNotEmpty && _getClassesArthropods().any((item) => item.value == className)) {
      return className;
    }
    return null;
  }
  String? _getValidTaxonValue() {
    if (taxonOrder.isNotEmpty && _getTaxonOrder().any((item) => item.value == taxonOrder)) {
      return taxonOrder;
    }
    return null;
  }

  List<DropdownMenuItem<String>> _getHabitatItems() {
    return [
      'Jardín urbano',
      'Parque',
      'Bosque',
      'Campo abierto',
      'Zona húmeda',
      'Interior de casa',
      'Cultivo',
      'Otro'
    ].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  String? _getValidHabitatValue() {
    if (habitat.isNotEmpty && _getHabitatItems().any((item) => item.value == habitat)) {
      return habitat;
    }
    return null;
  }

  List<DropdownMenuItem<String>> _getLocationVisibilityItems() {
    return [
      'Pública',
      'Privada'
    ].map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  String? _getValidLocationVisibilityValue() {
    if (locationVisibility.isNotEmpty && _getLocationVisibilityItems().any((item) => item.value == locationVisibility)) {
      return locationVisibility;
    }
    return null;
  }

  void _updateDetailsCharCount(String text) {
    setState(() {
      _detailsCharCount = text.length;
    });
  }

  void _updateNotesCharCount(String text) {
    setState(() {
      _notesCharCount = text.length;
    });
  }

  // Función helper para limitar saltos de línea
  String _limitLineBreaks(String text, int maxLines) {
    // Contar los saltos de línea en el texto
    final lineBreaks = '\n'.allMatches(text).length;
    
    if (lineBreaks <= maxLines - 1) {
      return text; // Permitir el texto si no excede el límite (maxLines - 1 porque la primera línea no necesita \n)
    }
    
    // Si excede el límite, recortar el texto hasta el último salto de línea permitido
    final lines = text.split('\n');
    if (lines.length > maxLines) {
      return lines.take(maxLines).join('\n');
    }
    
    return text;
  }

  // Función para manejar cambios en el campo de detalles con validación de saltos de línea
  void _onDetailsChanged(String value) {
    final limitedText = _limitLineBreaks(value, 3);
    if (limitedText != value) {
      // Si el texto fue limitado, actualizar el controller sin triggear onChanged
      _detailsController.value = _detailsController.value.copyWith(
        text: limitedText,
        selection: TextSelection.collapsed(offset: limitedText.length),
      );
    }
    details = limitedText;
    _updateDetailsCharCount(limitedText);
  }

  // Función para manejar cambios en el campo de notas con validación de saltos de línea
  void _onNotesChanged(String value) {
    final limitedText = _limitLineBreaks(value, 3);
    if (limitedText != value) {
      // Si el texto fue limitado, actualizar el controller sin triggear onChanged
      _notesController.value = _notesController.value.copyWith(
        text: limitedText,
        selection: TextSelection.collapsed(offset: limitedText.length),
      );
    }
    notes = limitedText;
    _updateNotesCharCount(limitedText);
  }

  // Verificar si el error es relacionado con la conexión
  bool _isConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('connection') || 
           errorString.contains('internet') ||
           errorString.contains('timeout') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('socketexception') ||
           errorString.contains('httpexception') ||
           errorString.contains('clientexception') ||
           errorString.contains('no address associated with hostname') ||
           errorString.contains('unreachable');
  }

  // Función para analizar la imagen con IA
  Future<void> _analizarImagen() async {
    if (_isAnalyzing || _isProcessing) return;
    if (widget.imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay imagen disponible para analizar'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    // Verificar conexión a internet
    await _checkInternetConnection();
    if (!_hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se requiere conexión a internet para analizar la imagen'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isAnalyzing = true);

    try {
      // Verificación adicional de conexión justo antes del análisis
      await _checkInternetConnection();
      
      if (!_hasInternet) {
        throw Exception('Se perdió la conexión a internet durante el análisis');
      }

      final Map<String, dynamic> response = await AIService.analyzeImage(widget.imageFile!);

      final String clasificacion = response['predicted_class'];
      final double confianza = response['confidence'];

      final List<String> taxonomia = clasificacion.split('-');
      final String claseArtropodo = taxonomia[0];
      final String ordenTaxonomico = taxonomia[1];

      if (mounted) {
        if (confianza >= 0.75) {
          // Análisis exitoso - rellenar campos automáticamente
          setState(() {
            className = claseArtropodo;
            taxonOrder = ordenTaxonomico;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Análisis completado\nClase: $claseArtropodo, Orden: $ordenTaxonomico\nConfianza: ${(confianza * 100).toStringAsFixed(2)}%'),
              backgroundColor: AppColors.buttonGreen2,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          // Confianza baja - mostrar opciones
          await _mostrarOpcionesBajaConfianza(claseArtropodo, ordenTaxonomico, confianza);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al analizar la imagen';
        
        if (_isConnectionError(e)) {
          await _checkInternetConnection();
          errorMessage = 'Error de conexión. Verifica tu conexión a internet e inténtalo de nuevo.';
        } else {
          errorMessage = 'Error al analizar: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // Mostrar opciones cuando la confianza es baja
  Future<void> _mostrarOpcionesBajaConfianza(
    String claseArtropodo,
    String ordenTaxonomico,
    double confianza
  ) async {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'El nivel de confianza es insuficiente para una clasificación automática.',
                style: TextStyle(color: AppColors.textWhite),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: AppColors.textWhite),
                  children: [
                    const TextSpan(
                      text: 'Clase sugerida: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: claseArtropodo),
                    const TextSpan(
                      text: '\nOrden sugerido: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ordenTaxonomico),
                    const TextSpan(
                      text: '\nConfianza: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: '${(confianza * 100).toStringAsFixed(2)}%',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Usar sugerencia',
                style: TextStyle(color: AppColors.buttonGreen2),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() {
                  className = claseArtropodo;
                  taxonOrder = ordenTaxonomico;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Campos rellenados con la sugerencia de la IA'),
                    backgroundColor: AppColors.buttonGreen2,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            TextButton(
              child: const Text(
                'Seleccionar manualmente',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.backgroundPrimary, // Cambiar de gradiente a color sólido
        child: SafeArea(
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
                                height: 210,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: _isEditing && currentImageUrl != null
                                      ? Image.network(currentImageUrl!, fit: BoxFit.cover)
                                      : (widget.imageFile != null 
                                          ? Image.file(widget.imageFile!, fit: BoxFit.cover)
                                          : Container(
                                              color: AppColors.paleGreen.withValues(alpha: 0.2),
                                              child: const Icon(Icons.image_outlined, color: AppColors.textPaleGreen, size: 80),
                                            )),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Formulario
                            Column(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Clase - Convertido a Dropdown
                                    const Text(
                                      'Clase:',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    IgnorePointer(
                                      ignoring: _isProcessing,
                                      child: DropdownButtonFormField<String>(
                                        value: _getValidClassesValue(),
                                        decoration: InputDecoration(
                                          hintText: 'Selecciona una opción',
                                          labelStyle: const TextStyle(color: AppColors.textWhite),
                                          filled: true,
                                          fillColor: _isProcessing
                                              ? AppColors.paleGreen.withValues(alpha: 0.5)
                                              : AppColors.paleGreen,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        dropdownColor: AppColors.paleGreen,
                                        style: TextStyle(
                                          color: _isProcessing
                                              ? AppColors.textBlack.withValues(alpha: 0.5)
                                              : AppColors.textBlack,
                                        ),
                                        items: _getClassesArthropods(),
                                        onChanged: _isProcessing
                                            ? null
                                            : (value) {
                                          setState(() {
                                            className = value ?? '';
                                            // Reset taxonOrder cuando cambia la clase
                                            taxonOrder = '';
                                          });
                                        },
                                        validator: (value) => value?.trim().isEmpty ?? true
                                            ? 'La clase es requerida' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Orden taxonómico - Convertido a Dropdown dependiente
                                    const Text(
                                      'Orden taxonómico:',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    IgnorePointer(
                                      ignoring: _isProcessing || className.isEmpty,
                                      child: DropdownButtonFormField<String>(
                                        value: _getValidTaxonValue(),
                                        decoration: InputDecoration(
                                          hintText: 'Selecciona una opción',
                                          labelStyle: const TextStyle(color: AppColors.textWhite),
                                          filled: true,
                                          fillColor: _isProcessing || className.isEmpty
                                              ? AppColors.slateGrey.withValues(alpha: 0.3)
                                              : AppColors.paleGreen,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          suffixIcon: className.isEmpty
                                              ? const Icon(Icons.lock, color: AppColors.textPaleGreen)
                                              : null,
                                        ),
                                        dropdownColor: AppColors.paleGreen,
                                        style: TextStyle(
                                          color: _isProcessing || className.isEmpty
                                              ? AppColors.textBlack.withValues(alpha: 0.5)
                                              : AppColors.textBlack,
                                        ),
                                        items: _getFilteredTaxonOrder(),
                                        onChanged: _isProcessing || className.isEmpty
                                            ? null
                                            : (value) => setState(() => taxonOrder = value ?? ''),
                                        validator: (value) => value?.trim().isEmpty ?? true
                                            ? 'El orden taxonómico es requerido' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Botón de análisis con IA
                                if (widget.imageFile != null) ...[
                                  ElevatedButton.icon(
                                    icon: _isAnalyzing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: AppColors.textBlack,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.auto_fix_high),
                                    label: Text(
                                      _isAnalyzing
                                          ? 'Analizando...'
                                          : 'Analizar con IA',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isAnalyzing || !_hasInternet
                                          ? AppColors.textPaleGreen.withValues(alpha: 0.7)
                                          : AppColors.textPaleGreen,
                                      foregroundColor: AppColors.textBlack,
                                      minimumSize: const Size(double.infinity, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: (_isAnalyzing || _isProcessing || !_hasInternet) ? null : _analizarImagen,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Coordenadas mejoradas
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.slateGreen.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.buttonGreen2.withValues(alpha: 0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Header de coordenadas
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, color: AppColors.buttonGreen2, size: 20),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Ubicación',
                                              style: TextStyle(
                                                color: AppColors.textWhite,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          // Botón de mapa más compacto
                                          Container(
                                            margin: const EdgeInsets.only(right: 4),
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.buttonBrown2,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.map, size: 18),
                                              color: AppColors.textBlack,
                                              onPressed: _isProcessing ? null : _openLocationPicker,
                                              tooltip: 'Mapa',
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                          // Botón de ubicación actual más compacto
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.buttonGreen2,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: IconButton(
                                              icon: _isGettingLocation
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child: CircularProgressIndicator(
                                                        color: AppColors.textBlack,
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(Icons.my_location, size: 18),
                                              color: AppColors.textBlack,
                                              onPressed: (_isProcessing || _isGettingLocation) ? null : _getCurrentLocation,
                                              tooltip: 'Ubicación actual',
                                              padding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Campo Latitud
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Latitud:',
                                            style: TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          TextFormField(
                                            controller: _latitudController,
                                            enabled: !_isProcessing,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                            decoration: InputDecoration(
                                              hintText: 'ej: 19.432608',
                                              hintStyle: const TextStyle(color: AppColors.textBlack),
                                              filled: true,
                                              fillColor: AppColors.paleGreen,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: AppColors.warning, width: 2),
                                              ),
                                              prefixIcon: const Icon(Icons.arrow_upward, color: AppColors.textBlack),
                                            ),
                                            style: const TextStyle(color: AppColors.textBlack),
                                            validator: _validateLatitud,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Campo Longitud
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Longitud:',
                                            style: TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          TextFormField(
                                            controller: _longitudController,
                                            enabled: !_isProcessing,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                                            decoration: InputDecoration(
                                              hintText: 'ej: -99.133209',
                                              hintStyle: const TextStyle(color: AppColors.textBlack),
                                              filled: true,
                                              fillColor: AppColors.paleGreen,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: const BorderSide(color: AppColors.warning, width: 2),
                                              ),
                                              prefixIcon: const Icon(Icons.arrow_forward, color: AppColors.textBlack),
                                            ),
                                            style: const TextStyle(color: AppColors.textBlack),
                                            validator: _validateLongitud,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Campo Visibilidad de Ubicación
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Visibilidad de ubicación:',
                                            style: TextStyle(
                                              color: AppColors.textWhite,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          DropdownButtonFormField<String>(
                                            value: _getValidLocationVisibilityValue(),
                                            decoration: InputDecoration(
                                              hintText: 'Seleccionar visibilidad',
                                              hintStyle: const TextStyle(color: AppColors.textBlack),
                                              filled: true,
                                              fillColor: _isProcessing 
                                                  ? AppColors.paleGreen.withValues(alpha: 0.5) 
                                                  : AppColors.paleGreen,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide.none,
                                              ),
                                              prefixIcon: const Icon(Icons.visibility, color: AppColors.textBlack),
                                            ),
                                            dropdownColor: AppColors.paleGreen,
                                            style: TextStyle(
                                              color: _isProcessing 
                                                  ? AppColors.textBlack.withValues(alpha: 0.5) 
                                                  : AppColors.textBlack,
                                            ),
                                            items: _getLocationVisibilityItems(),
                                            onChanged: _isProcessing 
                                                ? null 
                                                : (value) => setState(() => locationVisibility = value ?? ''),
                                            validator: (value) => value?.trim().isEmpty ?? true 
                                                ? 'La visibilidad es requerida' : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Hábitat
                                    const Text(
                                      'Hábitat:',
                                      style: TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    IgnorePointer(
                                      ignoring: _isProcessing,
                                      child: DropdownButtonFormField<String>(
                                        value: _getValidHabitatValue(),
                                        decoration: InputDecoration(
                                          hintText: 'Selecciona una opción',
                                          labelStyle: const TextStyle(color: AppColors.textWhite),
                                          filled: true,
                                          fillColor: _isProcessing 
                                              ? AppColors.paleGreen.withValues(alpha: 0.5) 
                                              : AppColors.paleGreen,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        dropdownColor: AppColors.paleGreen,
                                        style: TextStyle(
                                          color: _isProcessing 
                                              ? AppColors.textBlack.withValues(alpha: 0.5) 
                                              : AppColors.textBlack,
                                        ),
                                        items: _getHabitatItems(),
                                        onChanged: _isProcessing 
                                            ? null 
                                            : (value) => setState(() => habitat = value ?? ''),
                                        validator: (value) => value?.trim().isEmpty ?? true 
                                            ? 'El hábitat es requerido' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Detalles
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Detalles adicionales:',
                                          style: TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '$_detailsCharCount/$_maxCharacters',
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    TextFormField(
                                      controller: _detailsController,
                                      enabled: !_isProcessing,
                                      maxLength: _maxCharacters,
                                      onChanged: _onDetailsChanged,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'Ej: Encontrado bajo una roca cerca de un arroyo',
                                        labelStyle: const TextStyle(color: AppColors.textWhite),
                                        filled: true,
                                        fillColor: AppColors.paleGreen,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        counterText: '', // Ocultar el contador por defecto
                                      ),
                                      style: const TextStyle(color: AppColors.textBlack),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Notas
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Notas personales:',
                                          style: TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          '$_notesCharCount/$_maxCharacters',
                                          style: const TextStyle(
                                            color: AppColors.textWhite,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    TextFormField(
                                      controller: _notesController,
                                      enabled: !_isProcessing,
                                      maxLength: _maxCharacters,
                                      onChanged: _onNotesChanged,
                                      maxLines: 3,
                                      decoration: InputDecoration(
                                        hintText: 'Ej: Parecía inofensivo pero tenía un patrón interesante',
                                        labelStyle: const TextStyle(color: AppColors.textWhite),
                                        filled: true,
                                        fillColor: AppColors.paleGreen,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide.none,
                                        ),
                                        counterText: '', // Ocultar el contador por defecto
                                      ),
                                      style: const TextStyle(color: AppColors.textBlack),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Checkbox para mejorar modelo (solo nuevos registros)
                                if (!_isEditing) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.slateGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.slateGreen.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Checkbox(
                                          value: _allowImageForModel,
                                          onChanged: _isProcessing || _isAnalyzing 
                                              ? null 
                                              : (bool? value) {
                                                  setState(() {
                                                    _allowImageForModel = value ?? true;
                                                  });
                                                },
                                          activeColor: AppColors.buttonGreen2,
                                          checkColor: AppColors.textBlack,
                                          side: const BorderSide(
                                            color: AppColors.textWhite,
                                            width: 1.5,
                                          ),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _isProcessing || _isAnalyzing 
                                                ? null 
                                                : () {
                                                    setState(() {
                                                      _allowImageForModel = !_allowImageForModel;
                                                    });
                                                  },
                                            child: const Text(
                                              'Permitir usar esta imagen para mejorar el modelo de IA',
                                              style: TextStyle(
                                                color: AppColors.textWhite,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                // Botón guardar/actualizar
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.buttonBrown2,
                                          foregroundColor: AppColors.textBlack,
                                          minimumSize: const Size(0, 48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: (_isProcessing || _isAnalyzing) ? null : () => Navigator.pop(context),
                                        child: const Text(
                                          'Cancelar',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: (_isProcessing || _isAnalyzing)
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: AppColors.textBlack,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Icon(_isEditing ? Icons.update : Icons.save),
                                        label: Text(
                                          _isAnalyzing
                                              ? 'Analizando...'
                                              : _isProcessing
                                                  ? (_isEditing ? 'Actualizando...' : 'Guardando...')
                                                  : !_hasInternet
                                                      ? 'Sin conexión'
                                                      : (_isEditing ? 'Actualizar' : 'Guardar'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: !_hasInternet 
                                              ? AppColors.warning.withValues(alpha: 0.7)
                                              : (_isAnalyzing || _isProcessing)
                                                  ? AppColors.buttonGreen2.withValues(alpha: 0.7)
                                                  : AppColors.buttonGreen2,
                                          foregroundColor: AppColors.textBlack,
                                          minimumSize: const Size(0, 48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: (_isProcessing || _isAnalyzing || !_hasInternet) ? null : _guardarDatos,
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_hasInternet) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.warning),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.warning, color: AppColors.warning),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Sin conexión a internet. No se pueden guardar los datos.',
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
      ),
    );
  }
}