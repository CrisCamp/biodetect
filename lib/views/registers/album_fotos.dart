import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/views/registers/lista_registros.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _checkInternetConnection();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar fotos: $e')),
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
                    _hasInternet ? 'Online' : 'Cache',
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
                              _hasInternet ? 'Conectado' : 'Modo Cache',
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
                      onPressed: _isLoading ? null : () {
                        _checkInternetConnection();
                        _loadPhotos();
                      },
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
                                    color: AppColors.textPaleGreen,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPhotos,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _photoGroups.length,
                              itemBuilder: (context, index) {
                                final entry = _photoGroups.entries.toList()[index];
                                return _buildPhotoTile(entry.key, entry.value);
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