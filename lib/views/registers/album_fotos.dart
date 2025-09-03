import 'dart:io';
import 'dart:async';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/lista_registros.dart';
import 'package:biodetect/views/registers/captura_foto.dart';
import 'package:biodetect/views/registers/fotos_pendientes.dart';
import 'package:biodetect/views/map/mapa.dart';
import 'package:biodetect/services/pending_photos_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AlbumFotos extends StatefulWidget {
  const AlbumFotos({super.key});

  @override
  State<AlbumFotos> createState() => _AlbumFotosState();
}

class _AlbumFotosState extends State<AlbumFotos> {
  Map<String, List<Map<String, dynamic>>> _photoGroups = {};
  bool _isLoading = true;
  bool _hasInternet = true;
  Timer? _connectionCheckTimer; // Timer para verificación de conexión automática
  int _pendingCount = 0; // Contador de fotos pendientes

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _loadPendingCount();
    _checkInternetConnection();
    _startPeriodicConnectionCheck(); // Iniciar verificación automática
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel(); // Limpiar Timer al destruir el widget
    super.dispose();
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

  // Verificación periódica de conexión (cada 10 segundos)
  void _startPeriodicConnectionCheck() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _checkInternetConnection();
      } else {
        timer.cancel(); // Cancelar si el widget ya no está montado
      }
    });
  }

  Future<void> _loadPendingCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final count = await PendingPhotosService.getPendingCount(user.uid);
      setState(() {
        _pendingCount = count;
      });
    }
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Usar cache de Firestore (igual que ProfileScreen)
      final query = await FirebaseFirestore.instance
          .collection('insect_photos')
          .where('userId', isEqualTo: user.uid)
          .get(const GetOptions(source: Source.serverAndCache));

      // Agrupar por taxonOrder
      final Map<String, List<Map<String, dynamic>>> photoGroups = {};
      for (final doc in query.docs) {
        final data = doc.data();
        final taxonOrder = data['taxonOrder'] as String? ?? 'Sin clasificar'; // Proteger contra null
        
        photoGroups.putIfAbsent(taxonOrder, () => []);
        photoGroups[taxonOrder]!.add({
          ...data,
          'photoId': doc.id,
          // Asegurar que todos los campos necesarios existan
          'imageUrl': data['imageUrl'] ?? '',
          'taxonOrder': taxonOrder,
          'habitat': data['habitat'] ?? 'No especificado',
          'details': data['details'] ?? 'Sin detalles',
          'notes': data['notes'] ?? 'Sin notas',
          'class': data['class'] ?? 'Sin clasificar',
        });
      }
      
      setState(() {
        _photoGroups = photoGroups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        // Verificar si es un error de conexión
        String errorMessage;
        
        if (_isConnectionError(e)) {
          // Es un error de conexión
          await _checkInternetConnection(); // Actualizar estado de conexión
          errorMessage = 'Error de conexión. Mostrando datos en caché si están disponibles.';
        } else {
          errorMessage = 'Error al cargar fotos: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: _isConnectionError(e) ? AppColors.warning : AppColors.warningDark,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildPhotoTile(String taxonOrder, List<Map<String, dynamic>> photos) {
    final firstPhoto = photos.first;
    final imageSource = firstPhoto['imageUrl'] ?? '';

    return Card(
      color: AppColors.backgroundCard,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListaRegistros(
                taxonOrder: taxonOrder,
                registros: photos,
              ),
            ),
          ).then((_) => _loadPhotos());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen de vista previa
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: imageSource.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageSource,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.paleGreen.withValues(alpha: 0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.buttonGreen2,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.paleGreen.withValues(alpha: 0.3),
                            child: const Icon(
                              Icons.error_outline,
                              color: AppColors.warning,
                              size: 30,
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.paleGreen.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppColors.textPaleGreen,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              // Información del taxon
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taxonOrder,
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${photos.length} ${photos.length == 1 ? 'registro' : 'registros'}',
                      style: const TextStyle(
                        color: AppColors.textPaleGreen,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de conexión
              Column(
                children: [
                  Icon(
                    _hasInternet ? Icons.cloud_done : Icons.cloud_off,
                    color: _hasInternet ? AppColors.buttonGreen2 : AppColors.warning,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _hasInternet ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _hasInternet ? AppColors.buttonGreen2 : AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textPaleGreen,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Título principal
                    const Text(
                      'Mis hallazgos',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Indicador de conexión y accesos rápidos
                    Row(
                      children: [
                        // Indicador de conexión
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _hasInternet ? AppColors.buttonGreen2 : AppColors.warning,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _hasInternet ? Icons.wifi : Icons.wifi_off,
                                size: 16,
                                color: AppColors.textBlack,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _hasInternet ? 'Conectado' : 'Sin conexión',
                                style: const TextStyle(
                                  color: AppColors.textBlack,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        
                        // Botones de acceso rápido
                        IconButton(
                          icon: Stack(
                            children: [
                              const Icon(Icons.schedule_outlined),
                              if (_pendingCount > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color.fromARGB(255, 255, 107, 107), width: 1),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 14,
                                      minHeight: 12,
                                    ),
                                    child: Text(
                                      _pendingCount > 9 ? '9+' : _pendingCount.toString(),
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 255, 255, 255),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          color: AppColors.white,
                          tooltip: 'Fotos Pendientes',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const FotosPendientes()),
                            ).then((_) => _loadPendingCount());
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_outlined),
                          color: AppColors.white,
                          tooltip: 'Capturar Foto',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const CapturaFoto()),
                            ).then((_) {
                              _loadPhotos();
                              _loadPendingCount();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.location_on_outlined),
                          color: AppColors.white,
                          tooltip: 'Ver mapa',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapaIterativoScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lista de taxones
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.buttonGreen2,
                        ),
                      )
                    : _photoGroups.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppColors.buttonGreen2.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_outlined,
                                      size: 80,
                                      color: AppColors.buttonGreen2,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  const Text(
                                    '¡Bienvenido a BioDetect!',
                                    style: TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Comienza tu aventura capturando tu primera fotografía de un artrópodo',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textPaleGreen,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundCard.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Column(
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.camera_alt, color: AppColors.buttonGreen2, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Toca el botón "Capturar" para empezar',
                                                style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.psychology, color: AppColors.buttonBlue2, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Nuestra IA identificará automáticamente la clase y el orden taxonómico',
                                                style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.collections, color: AppColors.buttonBrown1, size: 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Construye tu colección personal de descubrimientos',
                                                style: TextStyle(color: AppColors.textWhite, fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _photoGroups.length,
                            itemBuilder: (context, index) {
                              final entry = _photoGroups.entries.toList()[index];
                              return _buildPhotoTile(entry.key, entry.value);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}