import 'package:biodetect/themes.dart';
import 'package:biodetect/services/sync_service.dart';
import 'package:biodetect/views/registers/detalle_registro.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

      final combinedPhotos = await SyncService.getCombinedPhotos(user.uid);

      List<Map<String, dynamic>> photosWithCoords = [];

      for (final entry in combinedPhotos.entries) {
        for (final photo in entry.value) {
          double? lat, lon;
          // Para registros online
          if (photo['coords'] != null && photo['coords']['x'] != null && photo['coords']['y'] != null) {
            lat = photo['coords']['x'];
            lon = photo['coords']['y'];
          }
          // Para registros offline
          else if (photo['coordsX'] != null && photo['coordsY'] != null) {
            lat = photo['coordsX'];
            lon = photo['coordsY'];
          }
          // Solo si las coordenadas existen y son válidas
          if (lat != null && lon != null && lat != 0 && lon != 0) {
            photosWithCoords.add({
              ...photo,
              'lat': lat,
              'lon': lon,
              'taxonOrder': entry.key,
            });
          }
        }
      }

      setState(() {
        _userPhotos = photosWithCoords;
        _isLoading = false;
      });

      print('Fotos cargadas para el mapa: ${_userPhotos.length}');

      if (pointAnnotationManager != null) {
        await _addPhotoMarkers();
      }
    } catch (e) {
      print('Error cargando fotos: $e');
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
        final isOnline = photo['isOnline'] ?? false;

        final annotation = mapbox.PointAnnotationOptions(
          geometry: mapbox.Point(
            coordinates: mapbox.Position.named(
              lng: photo['lon'],
              lat: photo['lat'],
            ),
          ),
          textField: photo['taxonOrder'] ?? 'Registro',
          textSize: 12.0,
          textColor: Colors.white.value,
          textHaloColor: Colors.black.value,
          textHaloWidth: 2.0,
          iconSize: 1.5,
          // Color diferente para registros locales y remotos
          iconColor: isOnline ? AppColors.buttonGreen2.value : AppColors.buttonBrown3.value,
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
      
      // Configurar listener para taps en marcadores - Versión corregida
      pointAnnotationManager!.addOnPointAnnotationClickListener(
        _AnnotationClickListener((annotation) => _onAnnotationTapped(annotation))
      );
      
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
    // Cámara inicial basada en ubicación actual o por defecto
    mapbox.CameraOptions initialCamera = mapbox.CameraOptions(
      center: _currentPosition != null
          ? mapbox.Point(
              coordinates: mapbox.Position.named(
                lng: _currentPosition!.longitude,
                lat: _currentPosition!.latitude,
              ),
            )
          : mapbox.Point(
              coordinates: mapbox.Position.named(lng: -99.1332, lat: 19.4326), // Ciudad de México
            ),
      zoom: _currentPosition != null ? 15.0 : 10.0,
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
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!_isLoading)
                            Text(
                              '${_userPhotos.length} registros con ubicación',
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
                        styleUri: mapbox.MapboxStyles.OUTDOORS, // Cambiar a un estilo más simple
                      ),
                    ),
                    
                    // Indicador de error del mapa
                    if (_mapError != null)
                      Container(
                        color: Colors.red.withOpacity(0.8),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, color: Colors.white, size: 48),
                              const SizedBox(height: 16),
                              const Text(
                                'Error cargando el mapa',
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _mapError!,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _mapError = null;
                                  });
                                  _loadUserPhotos();
                                },
                                child: const Text('Reintentar'),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.buttonGreen2,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Cargando registros...',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Botón de ubicación
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton(
                        backgroundColor: AppColors.buttonGreen3,
                        foregroundColor: AppColors.textBlack,
                        onPressed: _centerOnCurrentLocation,
                        heroTag: "center_location",
                        child: Icon(_hasLocationPermission ? Icons.my_location : Icons.location_disabled),
                      ),
                    ),
                    
                    // Panel de información
                    if (_userPhotos.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundCard.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Instrucciones:',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: AppColors.buttonGreen2,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Toca un marcador para ver detalles',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  @override
  void dispose() {
    super.dispose();
  }
}

// Clase auxiliar para manejar los clicks en anotaciones
class _AnnotationClickListener extends mapbox.OnPointAnnotationClickListener {
  final Function(mapbox.PointAnnotation) onTap;
  
  _AnnotationClickListener(this.onTap);
  
  @override
  bool onPointAnnotationClick(mapbox.PointAnnotation annotation) {
    onTap(annotation);
    return true; // Consume el evento
  }
}