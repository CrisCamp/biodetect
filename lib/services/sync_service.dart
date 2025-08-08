import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'offline_storage_service.dart';

class SyncService {
  static bool _isSyncing = false;

  // Verificar conectividad
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // Sincronizar todas las fotos pendientes
  static Future<void> syncPendingPhotos() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) return;

      final pendingPhotos = await OfflineStorageService.getPendingSyncPhotos();
      
      for (final photo in pendingPhotos) {
        try {
          await _syncSinglePhoto(photo);
          await OfflineStorageService.markPhotoAsSynced(photo['id'] as String);
        } catch (e) {
          print('Error syncing photo ${photo['id']}: $e');
          // Continúa con la siguiente foto
        }
      }

      // Sincronizar actividad de usuario
      await _syncUserActivity();
      
    } finally {
      _isSyncing = false;
    }
  }

  // Sincronizar una foto individual
  static Future<void> _syncSinglePhoto(Map<String, dynamic> photo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Subir imagen a Firebase Storage
    final localImagePath = photo['localImagePath'] as String;
    final imageFile = File(localImagePath);
    
    if (!await imageFile.exists()) {
      throw Exception('Archivo local no existe: $localImagePath');
    }

    final photoId = photo['id'] as String;
    final ref = FirebaseStorage.instance
        .ref()
        .child('insect_photos/${user.uid}/original/$photoId.jpg');
    
    await ref.putFile(imageFile);
    final imageUrl = await ref.getDownloadURL();

    // Crear documento en Firestore
    await FirebaseFirestore.instance
        .collection('insect_photos')
        .doc(photoId)
        .set({
      'userId': user.uid,
      'imageUrl': imageUrl,
      'uploadedAt': FieldValue.serverTimestamp(),
      'verificationDate': Timestamp.fromMillisecondsSinceEpoch(
        photo['createdAt'] as int
      ),
      'taxonOrder': photo['taxonOrder'],
      'class': photo['class'],
      'habitat': photo['habitat'],
      'details': photo['details'],
      'notes': photo['notes'],
      'coords': {
        'x': photo['coordsX'],
        'y': photo['coordsY'],
      },
    });
  }

  // Sincronizar actividad de usuario
  static Future<void> _syncUserActivity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final offlineActivity = await OfflineStorageService.getUserActivityOffline(user.uid);
    if (offlineActivity == null) return;

    final activityRef = FirebaseFirestore.instance
        .collection('user_activity')
        .doc(user.uid);

    await activityRef.set({
      'userId': user.uid,
      'photosUploaded': FieldValue.increment(
        offlineActivity['photosUploaded'] as int
      ),
      'speciesIdentified.total': FieldValue.increment(
        offlineActivity['speciesIdentifiedTotal'] as int
      ),
      'lastActivity': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Limpiar actividad offline después de sincronizar
    final db = await OfflineStorageService.database;
    await db.delete(
      'offline_user_activity',
      where: 'userId = ?',
      whereArgs: [user.uid],
    );
  }

  // Obtener registros combinados (online + offline)
  static Future<Map<String, List<Map<String, dynamic>>>> getCombinedPhotos(
    String userId
  ) async {
    final hasInternet = await hasInternetConnection();
    
    // Siempre obtener datos offline
    final offlinePhotos = await OfflineStorageService.getOfflinePhotosGrouped(userId);
    
    if (!hasInternet) {
      // Solo datos offline
      return _formatOfflinePhotosForDisplay(offlinePhotos);
    }

    try {
      // Obtener datos online
      final onlineQuery = await FirebaseFirestore.instance
          .collection('insect_photos')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, List<Map<String, dynamic>>> onlinePhotos = {};
      for (final doc in onlineQuery.docs) {
        final data = doc.data();
        final taxonOrder = data['taxonOrder'] as String;
        
        onlinePhotos.putIfAbsent(taxonOrder, () => []);
        onlinePhotos[taxonOrder]!.add({
          ...data,
          'photoId': doc.id,
          'isOnline': true,
        });
      }

      // Combinar online y offline (evitar duplicados)
      final combined = Map<String, List<Map<String, dynamic>>>.from(onlinePhotos);
      
      for (final entry in offlinePhotos.entries) {
        final taxonOrder = entry.key;
        final offlineList = entry.value;
        
        combined.putIfAbsent(taxonOrder, () => []);
        
        // Agregar fotos offline que no estén sincronizadas
        for (final offlinePhoto in offlineList) {
          if (offlinePhoto['isSynced'] == 0) {
            combined[taxonOrder]!.add({
              ...offlinePhoto,
              'isOnline': false,
              'photoId': offlinePhoto['id'],
            });
          }
        }
      }

      return combined;
      
    } catch (e) {
      // Error al obtener datos online, usar solo offline
      return _formatOfflinePhotosForDisplay(offlinePhotos);
    }
  }

  static Map<String, List<Map<String, dynamic>>> _formatOfflinePhotosForDisplay(
    Map<String, List<Map<String, dynamic>>> offlinePhotos
  ) {
    final formatted = <String, List<Map<String, dynamic>>>{};
    
    for (final entry in offlinePhotos.entries) {
      formatted[entry.key] = entry.value.map((photo) => {
        ...photo,
        'photoId': photo['id'],
        'isOnline': false,
        'imageUrl': photo['localImagePath'], // Usar ruta local
      }).toList();
    }
    
    return formatted;
  }
}