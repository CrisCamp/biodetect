import 'package:biodetect/services/sync_service.dart';
import 'package:biodetect/services/offline_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:biodetect/menu.dart';
import 'package:biodetect/views/session/inicio_sesion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase (configuración básica)
  await Firebase.initializeApp();
  
  // Habilitar persistencia de Firestore para cache offline
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  // Inicializar base de datos SQLite offline
  try {
    await OfflineStorageService.database;
    print('Base de datos offline inicializada correctamente');
  } catch (e) {
    print('Error al inicializar base de datos offline: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BioDetect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  bool _hasCheckedSync = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Intentar sincronizar cuando la app regrese al primer plano
    if (state == AppLifecycleState.resumed) {
      _attemptSync();
    }
  }

  Future<void> _initializeApp() async {
    // Esperar un momento para que Firebase se inicialice completamente
    await Future.delayed(const Duration(milliseconds: 500));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !_hasCheckedSync) {
      _attemptSync();
    }
  }

  Future<void> _attemptSync() async {
    if (_hasCheckedSync) return;
    
    try {
      final hasInternet = await SyncService.hasInternetConnection();
      
      if (hasInternet) {
        print('Iniciando sincronización automática...');
        await SyncService.syncPendingPhotos();
        print('Sincronización completada');
      } else {
        print('Sin conexión a internet, sincronización pospuesta');
      }
    } catch (e) {
      print('Error durante sincronización automática: $e');
    } finally {
      setState(() {
        _hasCheckedSync = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostrar pantalla de carga mientras se verifica la autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
          );
        }
        
        // Usuario autenticado
        if (snapshot.hasData && snapshot.data != null) {
          // Intentar sincronizar solo una vez después del login
          if (!_hasCheckedSync) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _attemptSync();
            });
          }
          
          return const MainMenu();
        }
        
        // Usuario no autenticado
        return const InicioSesion();
      },
    );
  }
}