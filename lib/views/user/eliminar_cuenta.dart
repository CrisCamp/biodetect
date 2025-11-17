import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biodetect/views/session/inicio_sesion.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:async';

class EliminarCuenta extends StatefulWidget {
  const EliminarCuenta({super.key});

  @override
  State<EliminarCuenta> createState() => _EliminarCuentaState();
}

class _EliminarCuentaState extends State<EliminarCuenta> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isDeleting = false;
  bool _hasInternet = true;
  Timer? _internetTimer;

  @override
  void initState() {
    super.initState();
    _checkInternet();
    _internetTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkInternet();
    });
  }

  @override
  void dispose() {
    _internetTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _checkInternet() async {
    try {
      final result = await InternetAddress.lookup('dns.google');
      final hasInternet = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (mounted) {
        setState(() {
          _hasInternet = hasInternet;
        });
        if (!hasInternet) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Se requiere conexión a internet para eliminar la cuenta')),
              );
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasInternet = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se requiere conexión a internet para eliminar la cuenta')),
            );
          }
        });
      }
    }
  }

  Future<void> _eliminarCuentaCompleta() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    try {
      print('🔍 EliminarCuenta: Iniciando eliminación completa de cuenta...');

      // 1. Verificación inicial de conectividad para eliminación
      print('🌐 EliminarCuenta: Verificando conexión a internet para eliminación...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EliminarCuenta: Conexión inicial confirmada para eliminación con DNS lookup');
      } catch (e) {
        print('❌ EliminarCuenta: No hay conexión a internet para eliminar cuenta');
        throw Exception('No hay conexión a internet. Se requiere conectividad estable para eliminar tu cuenta de forma segura.');
      }

      // 2. PRIMERO: Eliminar archivos de Storage (antes de Firestore)
      print('📁 EliminarCuenta: Paso 1 - Eliminando archivos de Storage...');
      
      // Eliminar fotos de perfil
      try {
        final profilePicturesRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures/${user.uid}');
        final profileItems = await profilePicturesRef.listAll();
        for (final item in profileItems.items) {
          await item.delete();
          print('Foto de perfil eliminada: ${item.name}');
        }
      } catch (e) {
        print('Error al eliminar fotos de perfil: $e');
      }

      // Eliminar toda la carpeta del usuario en insect_photos
      try {
        final userInsectRef = FirebaseStorage.instance
            .ref()
            .child('insect_photos/${user.uid}');
        final userInsectItems = await userInsectRef.listAll();
        
        // Eliminar archivos en subcarpetas
        for (final prefix in userInsectItems.prefixes) {
          final items = await prefix.listAll();
          for (final item in items.items) {
            await item.delete();
            print('Archivo eliminado: ${item.fullPath}');
          }
        }
        
        // Eliminar archivos directos
        for (final item in userInsectItems.items) {
          await item.delete();
          print('Archivo directo eliminado: ${item.fullPath}');
        }
      } catch (e) {
        print('Error al eliminar carpeta de insectos: $e');
      }

      // Eliminar archivos de bitácoras si existen
      try {
        final fieldNotesRef = FirebaseStorage.instance
            .ref()
            .child('field_notes/${user.uid}');
        final fieldNotesItems = await fieldNotesRef.listAll();
        for (final item in fieldNotesItems.items) {
          await item.delete();
          print('Archivo de bitácora eliminado: ${item.name}');
        }
      } catch (e) {
        print('Error al eliminar archivos de bitácoras: $e');
      }

      // Eliminar archivos del chat grupal si existen
      try {
        final chatRef = FirebaseStorage.instance
            .ref()
            .child('group_chat/${user.uid}');
        final chatItems = await chatRef.listAll();
        for (final item in chatItems.items) {
          await item.delete();
          print('Archivo de chat eliminado: ${item.name}');
        }
      } catch (e) {
        print('Error al eliminar archivos de chat: $e');
      }

      print('✅ EliminarCuenta: Paso 1 completado - Archivos de Storage eliminados');

      // 3. Verificación intermedia de conexión antes de Firestore
      print('🔍 EliminarCuenta: Verificación intermedia de conectividad antes de Firestore...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EliminarCuenta: Conectividad intermedia confirmada con DNS lookup');
      } catch (e) {
        print('❌ EliminarCuenta: Fallo en verificación intermedia - cancelando eliminación');
        throw Exception('Se perdió la conexión a internet durante el proceso. La eliminación de cuenta ha sido cancelada por seguridad.');
      }

      // 4. SEGUNDO: Eliminar documentos de Firestore usando batch atómico
      print('💾 EliminarCuenta: Paso 2 - Eliminando documentos de Firestore con batch atómico...');
      final batch = FirebaseFirestore.instance.batch();
      
      // Eliminar fotos de artrópodos identificados
      final insectPhotosQuery = await FirebaseFirestore.instance
          .collection('insect_photos')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (final doc in insectPhotosQuery.docs) {
        batch.delete(doc.reference);
      }
      print('Marcadas ${insectPhotosQuery.docs.length} fotos identificadas para eliminar');

      // Eliminar fotos no identificadas
      final unidentifiedQuery = await FirebaseFirestore.instance
          .collection('unidentified')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (final doc in unidentifiedQuery.docs) {
        batch.delete(doc.reference);
      }
      print('Marcadas ${unidentifiedQuery.docs.length} fotos no identificadas para eliminar');

      // Eliminar bitácoras
      final fieldNotesQuery = await FirebaseFirestore.instance
          .collection('field_notes')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (final doc in fieldNotesQuery.docs) {
        batch.delete(doc.reference);
      }
      print('Marcadas ${fieldNotesQuery.docs.length} bitácoras para eliminar');

      // Eliminar mensajes del foro
      final chatQuery = await FirebaseFirestore.instance
          .collection('group_chat')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      for (final doc in chatQuery.docs) {
        batch.delete(doc.reference);
      }
      print('Marcados ${chatQuery.docs.length} mensajes de chat para eliminar');

      // Eliminar actividad del usuario
      batch.delete(FirebaseFirestore.instance.collection('user_activity').doc(user.uid));

      // Eliminar perfil del usuario
      batch.delete(FirebaseFirestore.instance.collection('users').doc(user.uid));

      // 5. Verificación final de conexión antes del commit del batch
      print('🔍 EliminarCuenta: Verificación final de conectividad antes del batch commit...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EliminarCuenta: Conectividad final confirmada con DNS lookup');
      } catch (e) {
        print('❌ EliminarCuenta: Fallo en verificación final - cancelando batch commit');
        throw Exception('Se perdió la conexión a internet durante el proceso. La eliminación de cuenta ha sido cancelada por seguridad.');
      }

      // 6. Ejecutar batch atómico
      print('💾 EliminarCuenta: Ejecutando batch atómico de eliminación...');
      await batch.commit();
      print('✅ EliminarCuenta: Paso 2 completado - Documentos de Firestore eliminados con batch atómico');

      // 7. TERCERO: Limpiar datos locales
      print('🧹 EliminarCuenta: Paso 3 - Limpiando datos locales...');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        print('✅ EliminarCuenta: Preferencias locales limpiadas');
      } catch (e) {
        print('⚠️ EliminarCuenta: Error al limpiar preferencias: $e');
      }

      // 8. CUARTO: Cerrar sesión de Google si aplica
      print('🔓 EliminarCuenta: Paso 4 - Cerrando sesión de Google...');
      try {
        await GoogleSignIn().signOut();
        print('✅ EliminarCuenta: Sesión de Google cerrada');
      } catch (e) {
        print('⚠️ EliminarCuenta: Error al cerrar sesión de Google (puede ser normal si no usó Google): $e');
      }

      // 9. Verificación final antes de eliminar cuenta de Auth
      print('🔍 EliminarCuenta: Verificación final antes de eliminar cuenta de Firebase Auth...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EliminarCuenta: Conectividad final confirmada para eliminación de Auth');
      } catch (e) {
        print('❌ EliminarCuenta: Fallo en verificación final para Auth - cancelando eliminación');
        throw Exception('Se perdió la conexión a internet durante el proceso. La eliminación de cuenta ha sido cancelada por seguridad.');
      }

      // 10. QUINTO: Eliminar cuenta de Firebase Auth (SIEMPRE AL FINAL)
      print('🔐 EliminarCuenta: Paso 5 - Eliminando cuenta de Firebase Auth...');
      await user.delete();
      print('✅ EliminarCuenta: Cuenta de Firebase Auth eliminada');

      print('🎉 EliminarCuenta: Eliminación completa de cuenta exitosa');

    } catch (e) {
      final errorString = e.toString().toLowerCase();
      print('❌ EliminarCuenta: Error en eliminación de cuenta - $e');
      
      // Detectar errores específicos y proporcionar mensajes amigables
      if (errorString.contains('unavailable') || 
          errorString.contains('timeout') || 
          errorString.contains('network') || 
          errorString.contains('connection')) {
        throw Exception('El servidor no está disponible temporalmente. Verifica tu conexión a internet e inténtalo de nuevo en unos momentos.');
      } else if (errorString.contains('permission-denied') || 
                 errorString.contains('unauthorized')) {
        throw Exception('No tienes permisos para eliminar esta cuenta. Verifica tu autenticación.');
      } else if (errorString.contains('unauthenticated') ||
                 (errorString.contains('user') && errorString.contains('auth'))) {
        throw Exception('Tu sesión ha expirado. Inicia sesión nuevamente e inténtalo de nuevo.');
      } else if (errorString.contains('quota-exceeded') ||
                 errorString.contains('resource-exhausted')) {
        throw Exception('Se ha superado la cuota de uso. Inténtalo más tarde.');
      } else if (errorString.contains('deadline-exceeded') ||
                 errorString.contains('cancelled')) {
        throw Exception('La operación tardó demasiado tiempo. Verifica tu conexión e inténtalo de nuevo.');
      } else if (errorString.contains('perdió') && errorString.contains('conexión')) {
        rethrow; // Usar mensaje específico de pérdida de conexión
      } else if (errorString.contains('requires-recent-login')) {
        throw Exception('Por seguridad, necesitas iniciar sesión nuevamente antes de eliminar tu cuenta.');
      } else {
        // Para cualquier otro error, usar un mensaje genérico y amigable
        throw Exception('No se pudo eliminar la cuenta. Verifica tu conexión a internet e inténtalo de nuevo. Si el problema persiste, contacta al soporte técnico.');
      }
    }
  }

  Future<void> _confirmarEliminacion() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.person_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No hay usuario autenticado. Inicia sesión e inténtalo de nuevo.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final inputText = _emailController.text.trim();
    
    if (inputText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Por favor introduce tu email para confirmar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    
    if (inputText.toLowerCase() != user.email?.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'El email no coincide con tu cuenta actual',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Verificación de conectividad antes de proceder
    print('🔍 EliminarCuenta: Verificando conexión para eliminación...');
    try {
      final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('No internet connection');
      }
      print('✅ EliminarCuenta: Conectividad confirmada para eliminación');
    } catch (e) {
      print('❌ EliminarCuenta: No hay conexión a internet para eliminar cuenta');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sin conexión a internet. Se requiere conectividad estable para eliminar la cuenta.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _eliminarCuentaCompleta();
      
      if (mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cuenta eliminada exitosamente. Serás redirigido al inicio de sesión.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Esperar un momento antes de navegar para que el usuario vea el mensaje
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const InicioSesion()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error al eliminar cuenta: $e');
      
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
        
        final errorString = e.toString().toLowerCase();
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        
        // Mostrar snackbar de error específico
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Si el error es crítico, navegar al login de todas formas
        if (errorString.contains('unauthenticated') || 
            errorString.contains('session') ||
            errorString.contains('auth')) {
          
          // Mostrar snackbar adicional para errores críticos
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Serás redirigido al inicio de sesión por seguridad.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
          
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const InicioSesion()),
                (route) => false,
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      body: AbsorbPointer(
        absorbing: !_hasInternet || _isDeleting,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.backgroundPrimary,
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  color: AppColors.slateGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: AppColors.white,
                        onPressed: _isDeleting ? null : () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          '⚠️ Eliminar Cuenta',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Para balancear el botón de atrás
                    ],
                  ),
                ),
                
                // Indicador de conexión
                if (!_hasInternet)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.warning,
                    child: const Text(
                      'No tienes conexión a internet. Se requiere conectividad para eliminar la cuenta.',
                      style: TextStyle(color: AppColors.textWhite),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Contenido principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icono de advertencia grande
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.warning, width: 3),
                              ),
                              child: const Icon(
                                Icons.warning_amber_rounded,
                                size: 60,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 28),
                          
                          // Título de advertencia
                          const Center(
                            child: Text(
                              'ACCIÓN IRREVERSIBLE',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Descripción de lo que se eliminará
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Esta acción eliminará permanentemente:',
                                  style: TextStyle(
                                    color: AppColors.textWhite,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 12),
                                _ListItem(text: 'Tu perfil y datos personales'),
                                _ListItem(text: 'Todas tus fotos de artrópodos'),
                                _ListItem(text: 'Tus bitácoras de campo'),
                                _ListItem(text: 'Mensajes del foro'),
                                _ListItem(text: 'Estadísticas de actividad'),
                                _ListItem(text: 'Archivos en la nube'),
                                SizedBox(height: 12),
                                Text(
                                  '⚠️ Esta acción NO se puede deshacer',
                                  style: TextStyle(
                                    color: AppColors.warning,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 28),
                          
                          // Instrucciones para confirmación
                          const Text(
                            'Para confirmar la eliminación, introduce tu dirección de email actual:',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Campo de email
                          TextFormField(
                            controller: _emailController,
                            enabled: !_isDeleting,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Escribe tu email exacto',
                              hintText: 'example@correo.com',
                              labelStyle: const TextStyle(color: AppColors.textWhite),
                              hintStyle: TextStyle(color: AppColors.textWhite.withOpacity(0.6)),
                              filled: true,
                              fillColor: AppColors.slateGreen,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.aquaBlue, width: 2),
                              ),
                              prefixIcon: const Icon(
                                Icons.email_outlined, 
                                color: AppColors.textWhite,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                            style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Por favor introduce tu email';
                              }
                              if (value.trim().toLowerCase() != user?.email?.toLowerCase()) {
                                return 'El email no coincide con tu cuenta actual';
                              }
                              return null;
                            },

                          ),

                          
                          const SizedBox(height: 20),
                          
                          // Botón de eliminación
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: AppColors.textWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                minimumSize: const Size(0, 56),
                              ),
                              onPressed: _isDeleting ? null : _confirmarEliminacion,
                              child: _isDeleting
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Eliminando...',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'ELIMINAR CUENTA',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Nota adicional de seguridad
                          if (_isDeleting) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.aquaBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.aquaBlue, width: 1),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.aquaBlue, size: 24),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Procesando eliminación de cuenta...\nEsto puede tomar unos momentos.',
                                      style: TextStyle(
                                        color: AppColors.aquaBlue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String text;
  
  const _ListItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}