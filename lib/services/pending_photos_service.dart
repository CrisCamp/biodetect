import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class PendingPhotosService {
  static Database? _database;
  static const String _dbName = 'pending_photos.db';
  static const String _tableName = 'pending_photos';

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
      version: 1,
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        localImagePath TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        createdAt INTEGER NOT NULL,
        needsClassification INTEGER DEFAULT 1
      )
    ''');
  }

  /// Guardar foto pendiente offline
  static Future<String> savePendingPhoto({
    required String userId,
    required File imageFile,
    double? latitude,
    double? longitude,
  }) async {
    final db = await database;
    final photoId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Crear directorio para fotos pendientes
    final appDir = await getApplicationDocumentsDirectory();
    final pendingDir = Directory('${appDir.path}/pending_photos');
    if (!await pendingDir.exists()) {
      await pendingDir.create(recursive: true);
    }
    
    // Copiar imagen al directorio de pendientes
    final localImagePath = '${pendingDir.path}/$photoId.jpg';
    await imageFile.copy(localImagePath);

    // Guardar en SQLite
    await db.insert(_tableName, {
      'id': photoId,
      'userId': userId,
      'localImagePath': localImagePath,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'needsClassification': 1,
    });

    return photoId;
  }

  /// Obtener todas las fotos pendientes del usuario
  static Future<List<Map<String, dynamic>>> getPendingPhotos(String userId) async {
    final db = await database;
    return await db.query(
      _tableName,
      where: 'userId = ? AND needsClassification = 1',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  /// Marcar foto como clasificada
  static Future<void> markAsClassified(String photoId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'needsClassification': 0},
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }

  /// Eliminar foto pendiente
  static Future<void> deletePendingPhoto(String photoId) async {
    final db = await database;
    
    // Obtener la ruta de la imagen antes de eliminar
    final result = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [photoId],
    );
    
    if (result.isNotEmpty) {
      final localImagePath = result.first['localImagePath'] as String;
      final imageFile = File(localImagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
      
      await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [photoId],
      );
    }
  }

  /// Obtener el número de fotos pendientes
  static Future<int> getPendingCount(String userId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_tableName WHERE userId = ? AND needsClassification = 1',
      [userId],
    );
    return result.first['count'] as int;
  }
}