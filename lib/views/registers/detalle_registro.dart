import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:biodetect/services/offline_storage_service.dart';
import 'package:biodetect/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'datos.dart';

class DetalleRegistro extends StatefulWidget {
  final Map<String, dynamic> registro;

  const DetalleRegistro({super.key, required this.registro});

  @override
  State<DetalleRegistro> createState() => _DetalleRegistroState();
}

class _DetalleRegistroState extends State<DetalleRegistro> {
  late Map<String, dynamic> _registro;
  bool _isDeleting = false;
  bool _hasInternet = true;

  @override
  void initState() {
    super.initState();
    _registro = Map<String, dynamic>.from(widget.registro);
    _checkInternetConnection();
  }

  Future<void> _checkInternetConnection() async {
    final hasInternet = await SyncService.hasInternetConnection();
    setState(() {
      _hasInternet = hasInternet;
    });
  }

  Future<void> _refrescarRegistro() async {
    try {
      final isOnline = _registro['isOnline'] ?? false;
      
      if (isOnline) {
        // Registro online: refrescar desde Firestore
        final doc = await FirebaseFirestore.instance
            .collection('insect_photos')
            .doc(_registro['photoId'])
            .get();
        
        if (doc.exists) {
          setState(() {
            _registro = {...doc.data()!, 'photoId': doc.id, 'isOnline': true};
          });
        }
      } else {
        // Registro offline: obtener desde SQLite
        final db = await OfflineStorageService.database;
        final result = await db.query(
          'offline_photos',
          where: 'id = ?',
          whereArgs: [_registro['id'] ?? _registro['photoId']],
        );
        
        if (result.isNotEmpty) {
          setState(() {
            _registro = {...result.first, 'photoId': result.first['id'], 'isOnline': false};
          });
        }
      }
    } catch (e) {
      print('Error al refrescar registro: $e');
    }
  }

  String _formatCoords(Map<String, dynamic> registro) {
    double? lat, lon;
    
    // Para registros online
    if (registro['coords'] != null) {
      lat = registro['coords']['x'];
      lon = registro['coords']['y'];
    } 
    // Para registros offline
    else {
      lat = registro['coordsX'];
      lon = registro['coordsY'];
    }
    
    if (lat == null || lon == null || (lat == 0 && lon == 0)) {
      return 'Coordenadas: No disponibles';
    }
    
    return 'Coordenadas: ${lat.toStringAsFixed(6)}°, ${lon.toStringAsFixed(6)}°';
  }

  String _formatDate(Map<String, dynamic> registro) {
    try {
      // Para registros online
      if (registro['verificationDate'] != null) {
        final date = registro['verificationDate'];
        final dt = date is DateTime ? date : date.toDate();
        return 'Verificado: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
      // Para registros offline
      else if (registro['createdAt'] != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(registro['createdAt'] as int);
        return 'Creado: ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    } catch (_) {}
    
    return 'Fecha: No disponible';
  }

  Future<void> _actualizarActividadUsuario(String userId, String taxonOrder) async {
    if (!_hasInternet) return; // Solo actualizar si hay internet
    
    final activityRef = FirebaseFirestore.instance.collection('user_activity').doc(userId);
    await activityRef.set({
      'userId': userId,
      'photosUploaded': FieldValue.increment(-1),
      'speciesIdentified.total': FieldValue.increment(-1),
      'speciesIdentified.byTaxon.$taxonOrder': FieldValue.increment(-1),
      'lastActivity': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _eliminarRegistro(BuildContext context) async {
    if (_isDeleting) return;

    setState(() => _isDeleting = true);

    try {
      final isOnline = _registro['isOnline'] ?? false;
      final photoId = _registro['photoId'];
      final userId = _registro['userId'];
      final taxonOrder = _registro['taxonOrder'] ?? '';

      if (isOnline) {
        // Eliminar registro online
        if (!_hasInternet) {
          throw Exception('Se requiere conexión a internet para eliminar registros sincronizados');
        }

        // Eliminar imagen de Storage
        final imageUrl = _registro['imageUrl'];
        if (imageUrl != null && imageUrl.toString().isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(imageUrl);
            await ref.delete();
          } catch (e) {
            print('Error al eliminar imagen de Storage: $e');
          }
        }

        // Eliminar documento de Firestore
        await FirebaseFirestore.instance.collection('insect_photos').doc(photoId).delete();

        // Actualizar actividad del usuario
        if (userId != null && taxonOrder.isNotEmpty) {
          await _actualizarActividadUsuario(userId, taxonOrder);
        }

      } else {
        // Eliminar registro offline
        await OfflineStorageService.deleteOfflinePhoto(photoId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isOnline 
                ? 'Registro eliminado correctamente' 
                : 'Registro local eliminado'),
            backgroundColor: AppColors.buttonGreen2,
          ),
        );
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Widget _buildImageWidget() {
    final isOnline = _registro['isOnline'] ?? false;
    final imageSource = isOnline ? _registro['imageUrl'] : _registro['localImagePath'];

    if (isOnline) {
      return CachedNetworkImage(
        imageUrl: imageSource,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: AppColors.paleGreen.withOpacity(0.2),
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.buttonGreen2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.paleGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: AppColors.warning, size: 50),
              SizedBox(height: 8),
              Text(
                'Error al cargar imagen',
                style: TextStyle(color: AppColors.textPaleGreen),
              ),
            ],
          ),
        ),
      );
    } else {
      // Imagen offline
      final imageFile = File(imageSource);
      if (imageFile.existsSync()) {
        return Image.file(
          imageFile,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        );
      } else {
        return Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.paleGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, color: AppColors.textPaleGreen, size: 50),
              SizedBox(height: 8),
              Text(
                'Imagen local no encontrada',
                style: TextStyle(color: AppColors.textPaleGreen),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = _registro['isOnline'] ?? false;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: AppColors.backgroundCard,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header con indicador de estado
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new),
                            color: AppColors.textWhite,
                            onPressed: _isDeleting ? null : () => Navigator.pop(context),
                            iconSize: 28,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Detalles del Hallazgo',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                // Indicador de estado
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isOnline ? AppColors.buttonGreen2 : AppColors.buttonBrown3,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isOnline ? Icons.cloud_done : Icons.smartphone,
                                        size: 14,
                                        color: AppColors.textBlack,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isOnline ? 'Sincronizado' : 'Local',
                                        style: const TextStyle(
                                          color: AppColors.textBlack,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Botón de refresh (solo para registros online)
                          if (isOnline)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              color: AppColors.textWhite,
                              onPressed: _isDeleting ? null : _refrescarRegistro,
                              iconSize: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      // Imagen
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(),
                      ),
                      const SizedBox(height: 24),
                      // Detalles
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.paleGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.paleGreen.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Orden taxonómico', _registro['taxonOrder'] ?? 'Sin especificar'),
                            _buildDetailRow('Clase', _registro['class'] ?? 'Sin especificar'),
                            _buildDetailRow('Hábitat', _registro['habitat'] ?? 'Sin especificar'),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(_registro),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatCoords(_registro),
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Detalles del hallazgo:',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _registro['details'] ?? 'Sin detalles',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Observaciones:',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _registro['notes'] ?? 'Sin observaciones',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Botones de acción
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.edit),
                              label: const Text('Editar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blueLight,
                                foregroundColor: AppColors.textBlack,
                                minimumSize: const Size(0, 48),
                                elevation: _isDeleting ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: (_isDeleting || (!isOnline && !_hasInternet)) ? null : () async {
                                Map<String, dynamic> datosParaEdicion;
                                
                                if (isOnline) {
                                  // Datos para registro online
                                  datosParaEdicion = {
                                    'taxonOrder': _registro['taxonOrder'] ?? '',
                                    'class': _registro['class'] ?? '',
                                    'habitat': _registro['habitat'] ?? '',
                                    'details': _registro['details'] ?? '',
                                    'notes': _registro['notes'] ?? '',
                                    'coords': _registro['coords'],
                                  };
                                } else {
                                  // Datos para registro offline (no se puede editar offline sin internet)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Los registros offline no se pueden editar sin conexión'),
                                      backgroundColor: AppColors.warning,
                                    ),
                                  );
                                  return;
                                }
                                
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => RegDatos(
                                      photoId: _registro['photoId'],
                                      imageUrl: _registro['imageUrl'],
                                      ordenTaxonomico: _registro['taxonOrder'] ?? '',
                                      datosIniciales: datosParaEdicion,
                                    ),
                                  ),
                                );
                                
                                if (result == true) {
                                  await _refrescarRegistro();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: _isDeleting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.textBlack,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Icon(Icons.delete),
                              label: Text(_isDeleting ? 'Eliminando...' : 'Eliminar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: AppColors.textBlack,
                                minimumSize: const Size(0, 48),
                                elevation: _isDeleting ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _isDeleting ? null : () async {
                                final confirmacion = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.backgroundCard,
                                    title: const Text(
                                      'Confirmar eliminación',
                                      style: TextStyle(color: AppColors.textWhite),
                                    ),
                                    content: Text(
                                      isOnline 
                                          ? '¿Estás seguro de que quieres eliminar este registro? Esta acción no se puede deshacer.'
                                          : '¿Estás seguro de que quieres eliminar este registro local?',
                                      style: const TextStyle(color: AppColors.textWhite),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text(
                                          'Cancelar',
                                          style: TextStyle(color: AppColors.textPaleGreen),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Eliminar',
                                          style: TextStyle(color: AppColors.warning),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmacion == true) {
                                  await _eliminarRegistro(context);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      // Advertencia para registros offline
                      if (!isOnline) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.buttonBrown3.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.buttonBrown3, width: 1),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.buttonBrown3, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Este registro está guardado localmente. Se sincronizará automáticamente cuando tengas conexión a internet.',
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}