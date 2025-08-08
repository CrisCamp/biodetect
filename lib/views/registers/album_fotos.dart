import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/lista_registros.dart';
import 'package:biodetect/services/sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _checkInternetAndSync();
  }

  Future<void> _checkInternetAndSync() async {
    final hasInternet = await SyncService.hasInternetConnection();
    setState(() {
      _hasInternet = hasInternet;
    });

    if (hasInternet) {
      // Intentar sincronizar fotos pendientes en segundo plano
      SyncService.syncPendingPhotos().then((_) {
        // Recargar después de sincronizar
        _loadPhotos();
      }).catchError((e) {
        print('Error durante sincronización: $e');
      });
    }
  }

  Future<void> _loadPhotos() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Obtener fotos combinadas (online + offline)
      final combinedPhotos = await SyncService.getCombinedPhotos(user.uid);
      
      setState(() {
        _photoGroups = combinedPhotos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar fotos: $e')),
        );
      }
    }
  }

  Widget _buildPhotoTile(String taxonOrder, List<Map<String, dynamic>> photos) {
    final firstPhoto = photos.first;
    final isOnline = firstPhoto['isOnline'] ?? false;
    final imageSource = isOnline ? firstPhoto['imageUrl'] : firstPhoto['localImagePath'];
    final offlineCount = photos.where((p) => !(p['isOnline'] ?? false)).length;

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
          ).then((_) => _loadPhotos()); // Recargar al volver
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
                  child: isOnline
                      ? CachedNetworkImage(
                          imageUrl: imageSource,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.paleGreen.withOpacity(0.3),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.buttonGreen2,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.paleGreen.withOpacity(0.3),
                            child: const Icon(
                              Icons.error_outline,
                              color: AppColors.warning,
                              size: 30,
                            ),
                          ),
                        )
                      : File(imageSource).existsSync()
                          ? Image.file(
                              File(imageSource),
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: AppColors.paleGreen.withOpacity(0.3),
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
                    if (offlineCount > 0) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.buttonBrown3,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$offlineCount sin sincronizar',
                          style: const TextStyle(
                            color: AppColors.textBlack,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Indicador de estado
              Column(
                children: [
                  Icon(
                    isOnline ? Icons.cloud_done : Icons.smartphone,
                    color: isOnline ? AppColors.buttonGreen2 : AppColors.buttonBrown3,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOnline ? 'Online' : 'Local',
                    style: TextStyle(
                      color: isOnline ? AppColors.buttonGreen2 : AppColors.buttonBrown3,
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
              // Header con indicador de conexión
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                            'Álbum de Fotografías',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          // Indicador de conexión
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _hasInternet ? AppColors.buttonGreen2 : AppColors.warning,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _hasInternet ? 'Conectado' : 'Sin conexión',
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
                    // Botón de sincronización manual
                    IconButton(
                      icon: const Icon(Icons.sync),
                      color: AppColors.white,
                      onPressed: _isLoading ? null : _checkInternetAndSync,
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
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 80,
                                  color: AppColors.textPaleGreen,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No tienes fotografías guardadas',
                                  style: TextStyle(
                                    color: AppColors.textPaleGreen,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Captura tu primera fotografía para\ncomenzar tu colección',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPhotos,
                            color: AppColors.buttonGreen2,
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: _photoGroups.length,
                              itemBuilder: (context, index) {
                                final taxonOrder = _photoGroups.keys.elementAt(index);
                                final photos = _photoGroups[taxonOrder]!;
                                return _buildPhotoTile(taxonOrder, photos);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}