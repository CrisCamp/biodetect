import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class OfflineStorageService {
  static Database? _database;
  static const String _dbName = 'biodetect_offline.db';
  static const int _dbVersion = 1;

  // Tablas
  static const String _tablePhotos = 'offline_photos';
  static const String _tableUserActivity = 'offline_user_activity';

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _dbName);
    
    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Tabla para fotos offline
    await db.execute('''
      CREATE TABLE $_tablePhotos (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        localImagePath TEXT NOT NULL,
        taxonOrder TEXT NOT NULL,
        class TEXT,
        habitat TEXT,
        details TEXT,
        notes TEXT,
        coordsX REAL,
        coordsY REAL,
        createdAt INTEGER NOT NULL,
        isSynced INTEGER DEFAULT 0,
        needsSync INTEGER DEFAULT 1
      )
    ''');

    // Tabla para actividad de usuario offline
    await db.execute('''
      CREATE TABLE $_tableUserActivity (
        userId TEXT PRIMARY KEY,
        photosUploaded INTEGER DEFAULT 0,
        speciesIdentifiedTotal INTEGER DEFAULT 0,
        lastActivity INTEGER,
        pendingSync INTEGER DEFAULT 1
      )
    ''');
  }

  // Guardar foto offline
  static Future<String> savePhotoOffline({
    required String userId,
    required File imageFile,
    required String taxonOrder,
    String? className,
    String? habitat,
    String? details,
    String? notes,
    double? lat,
    double? lon,
  }) async {
    final db = await database;
    final photoId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Guardar imagen localmente
    final appDir = await getApplicationDocumentsDirectory();
    final localImagesDir = Directory('${appDir.path}/offline_images');
    if (!await localImagesDir.exists()) {
      await localImagesDir.create(recursive: true);
    }
    
    final localImagePath = '${localImagesDir.path}/$photoId.jpg';
    await imageFile.copy(localImagePath);

    // Guardar en SQLite
    await db.insert(_tablePhotos, {
      'id': photoId,
      'userId': userId,
      'localImagePath': localImagePath,
      'taxonOrder': taxonOrder,
      'class': className,
      'habitat': habitat,
      'details': details,
      'notes': notes,
      'coordsX': lat,
      'coordsY': lon,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'isSynced': 0,
      'needsSync': 1,
    });

    // Actualizar actividad offline
    await _updateUserActivityOffline(userId);
    
    return photoId;
  }

  // Obtener fotos offline por taxonOrder
  static Future<List<Map<String, dynamic>>> getOfflinePhotosByTaxon(
    String userId, 
    String taxonOrder
  ) async {
    final db = await database;
    return await db.query(
      _tablePhotos,
      where: 'userId = ? AND taxonOrder = ?',
      whereArgs: [userId, taxonOrder],
      orderBy: 'createdAt DESC',
    );
  }

  // Obtener todas las fotos offline agrupadas por taxonOrder
  static Future<Map<String, List<Map<String, dynamic>>>> getOfflinePhotosGrouped(
    String userId
  ) async {
    final db = await database;
    final photos = await db.query(
      _tablePhotos,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final photo in photos) {
      final taxonOrder = photo['taxonOrder'] as String;
      grouped.putIfAbsent(taxonOrder, () => []);
      grouped[taxonOrder]!.add(photo);
    }
    
    return grouped;
  }

  // Obtener fotos pendientes de sincronización
  static Future<List<Map<String, dynamic>>> getPendingSyncPhotos() async {
    final db = await database;
    return await db.query(
      _tablePhotos,
      where: 'needsSync = 1',
      orderBy: 'createdAt ASC',
    );
  }

  // Marcar foto como sincronizada
  static Future<void> markPhotoAsSynced(String photoId) async {
    final db = await database;
    await db.update(
      _tablePhotos,
      {'isSynced': 1, 'needsSync': 0},
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  // Actualizar actividad de usuario offline
  static Future<void> _updateUserActivityOffline(String userId) async {
    final db = await database;
    
    final existing = await db.query(
      _tableUserActivity,
      where: 'userId = ?',
      whereArgs: [userId],
    );

    if (existing.isEmpty) {
      await db.insert(_tableUserActivity, {
        'userId': userId,
        'photosUploaded': 1,
        'speciesIdentifiedTotal': 1,
        'lastActivity': DateTime.now().millisecondsSinceEpoch,
        'pendingSync': 1,
      });
    } else {
      await db.update(
        _tableUserActivity,
        {
          'photosUploaded': (existing.first['photosUploaded'] as int) + 1,
          'speciesIdentifiedTotal': (existing.first['speciesIdentifiedTotal'] as int) + 1,
          'lastActivity': DateTime.now().millisecondsSinceEpoch,
          'pendingSync': 1,
        },
        where: 'userId = ?',
        whereArgs: [userId],
      );
    }
  }

  // Eliminar foto offline
  static Future<void> deleteOfflinePhoto(String photoId) async {
    final db = await database;
    
    // Obtener la ruta de la imagen antes de eliminar
    final photo = await db.query(
      _tablePhotos,
      where: 'id = ?',
      whereArgs: [photoId],
    );
    
    if (photo.isNotEmpty) {
      final localImagePath = photo.first['localImagePath'] as String;
      final imageFile = File(localImagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      await db.delete(
        _tablePhotos,
        where: 'id = ?',
        whereArgs: [photoId],
      );
    }
  }

  // Obtener actividad de usuario offline
  static Future<Map<String, dynamic>?> getUserActivityOffline(String userId) async {
    final db = await database;
    final result = await db.query(
      _tableUserActivity,
      where: 'userId = ?',
      whereArgs: [userId],
    );
    
    return result.isNotEmpty ? result.first : null;
  }
}