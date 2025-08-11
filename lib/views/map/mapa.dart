import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/detalle_registro.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapaIterativoScreen extends StatefulWidget {
  const MapaIterativoScreen({super.key});

  @override
  State<MapaIterativoScreen> createState() => _MapaIterativoScreenState();
}

class _MapaIterativoScreenState extends State<MapaIterativoScreen> {
  mapbox.MapboxMap? mapboxMap;
  mapbox.PointAnnotationManager? pointAnnotationManager;
  geolocator.Position? _currentPosition;
  List<Map<String, dynamic>> _userPhotos = [];
  List<mapbox.PointAnnotation> _createdAnnotations = [];
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _requestLocationPermission();
    await _loadUserPhotos();
    print('Mapbox token configurado en main.dart');
  }

  Future<void> _requestLocationPermission() async {
    try {
      PermissionStatus permission = await Permission.locationWhenInUse.request();
      
      if (permission.isGranted) {
        setState(() {
          _hasLocationPermission = true;
        });
        await _getCurrentLocation();
      } else {
        setState(() {
          _hasLocationPermission = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos de ubicación necesarios para el mapa'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      print('Error solicitando permisos: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (!_hasLocationPermission) return;
      
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      setState(() {
        _currentPosition = position;
      });
      
      print('Ubicación obtenida: ${position.latitude}, ${position.longitude}');
      
      // Si el mapa ya está creado, centrar en la ubicación actual
      if (mapboxMap != null) {
        await _centerOnCurrentLocation();
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      // Usar ubicación por defecto si no se puede obtener la actual
      setState(() {
        _currentPosition = geolocator.Position(
          latitude: 19.4326,
          longitude: -99.1332,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }
  }

  Future<void> _loadUserPhotos() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Consultar directamente desde Firestore con cache
      final query = await FirebaseFirestore.instance
          .collection('insect_photos')
          .where('userId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      List<Map<String, dynamic>> photosWithCoords = [];

      for (final doc in query.docs) {
        final data = doc.data();
        double? lat, lon;
        
        if (data['coords'] != null && data['coords']['x'] != null && data['coords']['y'] != null) {
          lat = data['coords']['x'];
          lon = data['coords']['y'];
          
          if (lat != null && lon != null && lat != 0 && lon != 0) {
            photosWithCoords.add({
              ...data,
              'lat': lat,
              'lon': lon,
              'taxonOrder': data['taxonOrder'],
              'photoId': doc.id,
            });
          }
        }
      }

      setState(() {
        _userPhotos = photosWithCoords;
        _isLoading = false;
      });

      if (pointAnnotationManager != null) {
        await _addPhotoMarkers();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addPhotoMarkers() async {
    if (pointAnnotationManager == null) return;

    try {
      // Limpiar marcadores existentes
      if (_createdAnnotations.isNotEmpty) {
        await pointAnnotationManager!.deleteAll();
        _createdAnnotations.clear();
      }

      List<mapbox.PointAnnotationOptions> annotations = [];
      
      for (int i = 0; i < _userPhotos.length; i++) {
        final photo = _userPhotos[i];

        final annotation = mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position.named(
              lng: photo['lon'],
              lat: photo['lat'],
            ),
          ),
          textField: photo['taxonOrder'] ?? 'Registro',
          textSize: 12.0,
          textColor: Colors.white.toARGB32(),
          textHaloColor: Colors.black.toARGB32(),
          textHaloWidth: 2.0,
          iconSize: 1.5,
          iconColor: AppColors.buttonGreen2.toARGB32(),
        );
        
        annotations.add(annotation);
      }
      
      if (annotations.isNotEmpty) {
        final createdAnnotations = await pointAnnotationManager!.createMulti(annotations);
        _createdAnnotations = createdAnnotations.where((annotation) => annotation != null)
            .map((annotation) => annotation!)
            .toList();
        print('Marcadores agregados: ${_createdAnnotations.length}');
      }
    } catch (e) {
      print('Error agregando marcadores: $e');
    }
  }

  void _onAnnotationTapped(mapbox.PointAnnotation annotation) {
    try {
      // Encontrar la foto correspondiente por índice
      final annotationIndex = _createdAnnotations.indexOf(annotation);
      
      if (annotationIndex >= 0 && annotationIndex < _userPhotos.length) {
        final photo = _userPhotos[annotationIndex];
        
        // Navegar al detalle del registro
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => DetalleRegistro(registro: photo),
          ),
        ).then((result) {
          // Si se modificó o eliminó el registro, recargar los datos
          if (result == true) {
            _loadUserPhotos();
          }
        });
      }
    } catch (e) {
      print('Error al manejar tap en marcador: $e');
    }
  }

  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    print('Mapa creado, configurando...');
    this.mapboxMap = mapboxMap;
    
    try {
      // Crear el manager de anotaciones
      pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
      print('PointAnnotationManager creado');
      
      // Configurar listener para taps en marcadores usando la API que funciona
      pointAnnotationManager!.addOnPointAnnotationClickListener(_AnnotationClickListener(this));
      
      // Habilitar componente de ubicación
      if (_hasLocationPermission) {
        await mapboxMap.location.updateSettings(
          mapbox.LocationComponentSettings(
            enabled: true,
            puckBearingEnabled: true,
            locationPuck: mapbox.LocationPuck(
              locationPuck2D: mapbox.LocationPuck2D(
                bearingImage: null,
                shadowImage: null,
                topImage: null,
              ),
            ),
          ),
        );
        print('Componente de ubicación habilitado');
      }
      
      // Agregar marcadores si ya están cargados
      if (_userPhotos.isNotEmpty) {
        await _addPhotoMarkers();
      }
      
      // Centrar en ubicación actual si está disponible
      if (_currentPosition != null) {
        await _centerOnCurrentLocation();
      }
      
      print('Mapa completamente configurado');
      
    } catch (e) {
      print('Error configurando mapa: $e');
      setState(() {
        _mapError = e.toString();
      });
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    if (_currentPosition != null && mapboxMap != null) {
      try {
        final cameraOptions = mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position.named(
              lng: _currentPosition!.longitude,
              lat: _currentPosition!.latitude,
            ),
          ),
          zoom: 15.0,
          bearing: 0,
          pitch: 0,
        );
        
        await mapboxMap!.flyTo(cameraOptions, mapbox.MapAnimationOptions(duration: 2000));
        print('Cámara centrada en ubicación actual');
      } catch (e) {
        print('Error centrando cámara: $e');
      }
    } else if (!_hasLocationPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permisos de ubicación no concedidos'),
          backgroundColor: AppColors.warning,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ubicación no disponible'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cámara inicial basada ÚNICAMENTE en ubicación actual del usuario
    mapbox.CameraOptions initialCamera = mapbox.CameraOptions(
      center: _currentPosition != null
          ? mapbox.Point(
              coordinates: mapbox.Position.named(
                lng: _currentPosition!.longitude,
                lat: _currentPosition!.latitude,
              ),
            )
          : mapbox.Point(
              coordinates: mapbox.Position.named(lng: 0, lat: 0), // Ubicación temporal hasta obtener la real
            ),
      zoom: _currentPosition != null ? 15.0 : 2.0, // Zoom bajo si no hay ubicación
      bearing: 0,
      pitch: 0,
    );

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: AppColors.backgroundCard,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Mapa Interactivo',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${_userPhotos.length} registros en el mapa',
                            style: const TextStyle(
                              color: AppColors.textPaleGreen,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      color: AppColors.textWhite,
                      onPressed: _isLoading ? null : () async {
                        setState(() => _isLoading = true);
                        await _loadUserPhotos();
                      },
                    ),
                  ],
                ),
              ),
              // Mapa
              Expanded(
                child: Stack(
                  children: [
                    // Widget del mapa
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: mapbox.MapWidget(
                        key: const ValueKey("mapbox_map"),
                        cameraOptions: initialCamera,
                        onMapCreated: _onMapCreated,
                        styleUri: mapbox.MapboxStyles.OUTDOORS,
                      ),
                    ),
                    
                    // Indicador de error del mapa
                    if (_mapError != null)
                      Container(
                        color: Colors.red.withValues(alpha: 0.8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 50),
                              const SizedBox(height: 16),
                              Text(
                                'Error del mapa: $_mapError',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Indicador de carga
                    if (_isLoading)
                      Container(
                        color: Colors.black26,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.buttonGreen2,
                          ),
                        ),
                      ),
                    
                    // Botón de ubicación
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton(
                        backgroundColor: AppColors.buttonGreen3,
                        child: Icon(_hasLocationPermission ? Icons.my_location : Icons.location_disabled),
                        onPressed: _centerOnCurrentLocation,
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

  @override
  void dispose() {
    // No necesitamos limpiar listeners con esta API
    super.dispose();
  }
}

// Añadir la clase listener al final del archivo
class _AnnotationClickListener extends mapbox.OnPointAnnotationClickListener {
  final _MapaIterativoScreenState mapState;

  _AnnotationClickListener(this.mapState);

  @override
  void onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    mapState._onAnnotationTapped(annotation);
  }
}