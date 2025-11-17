import 'dart:io';
import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:biodetect/views/user/cambiar_contrasena.dart';
import 'package:biodetect/views/user/eliminar_cuenta.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:async';

class EditarPerfil extends StatefulWidget {
  const EditarPerfil({super.key});

  @override
  State<EditarPerfil> createState() => _EditarPerfilState();
}

class _EditarPerfilState extends State<EditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  bool _loading = false;
  String? _profileUrl;
  bool _hasInternet = true;
  Timer? _internetTimer;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _checkInternet();
    _internetTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkInternet();
    });
  }

  @override
  void dispose() {
    _internetTimer?.cancel();
    _nombreController.dispose();
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
          // Diferir la navegación hasta después del frame actual
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Se requiere conexión a internet para editar el perfil')),
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
        // Diferir la navegación hasta después del frame actual
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Se requiere conexión a internet para editar el perfil')),
            );
          }
        });
      }
    }
  }

  Future<void> _cargarDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      _nombreController.text = data['fullname'] ?? '';
      _profileUrl = data['profilePicture'];
    } else {
      _nombreController.text = user.displayName ?? '';
      _profileUrl = user.photoURL;
    }
    setState(() {});
  }

  Future<void> _pickImage() async {
    // 1. Verificación inicial de conectividad antes de abrir el seleccionador
    print('🔍 EditarPerfil: Verificando conexión para seleccionar imagen...');
    try {
      // Usar lookup DNS para verificación más robusta de conectividad
      final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('No internet connection');
      }
      print('✅ EditarPerfil: Conectividad confirmada para selección de imagen');
    } catch (e) {
      print('❌ EditarPerfil: No hay conexión a internet');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay conexión a internet. Por favor, verifica tu conectividad e intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (picked != null) {
      try {
        final file = File(picked.path);
        final fileSizeInBytes = await file.length();
        const maxSizeInBytes = 8 * 1024 * 1024; // 8 MB en bytes
        
        if (kDebugMode) {
          final fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(2);
          print('📷 Imagen de perfil seleccionada:');
          print('   - Tamaño: ${fileSizeInMB}MB');
          print('   - Límite: 8MB');
          print('   - Válida: ${fileSizeInBytes <= maxSizeInBytes}');
        }
        
        if (fileSizeInBytes <= maxSizeInBytes) {
          // Si la imagen es válida, proceder con la subida
          await _uploadProfileImage(picked);
          
          // Mostrar confirmación del tamaño
          // final fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1);
          // if (mounted) {
          //   ScaffoldMessenger.of(context).showSnackBar(
          //     SnackBar(
          //       content: Text('Foto de perfil actualizada: ${fileSizeInMB}MB'),
          //       backgroundColor: AppColors.buttonGreen2,
          //       duration: const Duration(seconds: 2),
          //     ),
          //   );
          // }
        } else {
          // La imagen es muy grande
          final fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'La imagen es muy grande (${fileSizeInMB}MB).\n'
                  'El tamaño máximo permitido es 8MB.\n'
                  'Por favor, selecciona una imagen más pequeña.',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Cambiar imagen',
                  textColor: Colors.white,
                  onPressed: () {
                    _pickImage(); // Permitir seleccionar otra imagen
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error verificando tamaño de imagen de perfil: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al validar la imagen: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _uploadProfileImage(XFile image) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _loading = true);
    
    try {
      print('🔍 EditarPerfil: Iniciando proceso de actualización de foto de perfil...');
      
      // 1. Verificación inicial de conectividad
      print('🌐 EditarPerfil: Verificando conexión a internet...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EditarPerfil: Conexión inicial confirmada con DNS lookup');
      } catch (e) {
        print('❌ EditarPerfil: No hay conexión a internet');
        throw Exception('No hay conexión a internet. Por favor, verifica tu conectividad e intenta nuevamente.');
      }

      // 2. Subir imagen a Storage
      print('📁 EditarPerfil: Subiendo imagen a Firebase Storage...');
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putData(await image.readAsBytes());
      final url = await ref.getDownloadURL();
      print('✅ EditarPerfil: Imagen subida exitosamente');

      // 3. Verificación adicional de conexión antes de actualizar Firestore
      print('🔍 EditarPerfil: Verificación final de conectividad antes de actualizar perfil...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EditarPerfil: Conectividad final confirmada con DNS lookup');
      } catch (e) {
        print('❌ EditarPerfil: Fallo en verificación final - cancelando actualización');
        // Si falló la verificación, eliminar la imagen subida para evitar archivos huérfanos
        try {
          await ref.delete();
          print('🗑️ EditarPerfil: Imagen eliminada por falta de conectividad');
        } catch (deleteError) {
          print('⚠️ EditarPerfil: Error al eliminar imagen: $deleteError');
        }
        throw Exception('Se perdió la conexión a internet durante el proceso. La actualización ha sido cancelada por seguridad.');
      }

      // 4. Actualizar documento en Firestore
      print('💾 EditarPerfil: Actualizando documento de usuario...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profilePicture': url,
      });
      print('✅ EditarPerfil: Perfil actualizado exitosamente');
      
      setState(() {
        _profileUrl = url;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto de perfil actualizada'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      print('❌ EditarPerfil: Error en actualización de foto - $e');
      
      if (mounted) {
        String errorMessage;
        
        // Detectar errores específicos de Firebase y proporcionar mensajes amigables
        if (errorString.contains('unavailable') || 
            errorString.contains('timeout') || 
            errorString.contains('network') || 
            errorString.contains('connection')) {
          errorMessage = 'El servidor no está disponible temporalmente. Verifica tu conexión a internet e inténtalo de nuevo en unos momentos.';
        } else if (errorString.contains('permission-denied') || 
                   errorString.contains('unauthorized')) {
          errorMessage = 'No tienes permisos para actualizar tu foto de perfil. Verifica tu cuenta.';
        } else if (errorString.contains('unauthenticated') ||
                   (errorString.contains('user') && errorString.contains('auth'))) {
          errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente e inténtalo de nuevo.';
        } else if (errorString.contains('quota-exceeded') ||
                   errorString.contains('resource-exhausted')) {
          errorMessage = 'Se ha superado la cuota de uso. Inténtalo más tarde.';
        } else if (errorString.contains('deadline-exceeded') ||
                   errorString.contains('cancelled')) {
          errorMessage = 'La operación tardó demasiado tiempo. Verifica tu conexión e inténtalo de nuevo.';
        } else if (errorString.contains('perdió') && errorString.contains('conexión')) {
          errorMessage = e.toString(); // Usar mensaje específico de pérdida de conexión
        } else {
          // Para cualquier otro error, usar un mensaje genérico y amigable
          errorMessage = 'No se pudo actualizar la foto de perfil. Verifica tu conexión a internet e inténtalo de nuevo.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);

    try {
      print('🔍 EditarPerfil: Iniciando proceso de actualización de nombre...');
      
      // 1. Verificación inicial de conectividad
      print('🌐 EditarPerfil: Verificando conexión a internet...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EditarPerfil: Conexión inicial confirmada con DNS lookup');
      } catch (e) {
        print('❌ EditarPerfil: No hay conexión a internet');
        throw Exception('No hay conexión a internet. Por favor, verifica tu conectividad e intenta nuevamente.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado. Inicia sesión e inténtalo de nuevo.');
      }

      final nuevoNombre = _nombreController.text.trim();
      
      // Validar que el nombre no esté vacío
      if (nuevoNombre.isEmpty) {
        throw Exception('El nombre no puede estar vacío.');
      }

      print('📝 EditarPerfil: Procesando actualización de nombre: "$nuevoNombre"');

      // 2. Verificación adicional de conexión antes de las operaciones críticas
      print('🔍 EditarPerfil: Verificación final de conectividad antes de actualizar...');
      try {
        // Usar lookup DNS para verificación más robusta de conectividad
        final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          throw Exception('No internet connection');
        }
        print('✅ EditarPerfil: Conectividad final confirmada con DNS lookup');
      } catch (e) {
        print('❌ EditarPerfil: Fallo en verificación final - cancelando actualización');
        throw Exception('Se perdió la conexión a internet durante el proceso. La actualización ha sido cancelada por seguridad.');
      }

      // 3. Actualizar documento en Firestore
      print('💾 EditarPerfil: Actualizando documento de usuario en Firestore...');
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fullname': nuevoNombre,
      });
      print('✅ EditarPerfil: Documento en Firestore actualizado');
      
      // 4. Actualizar display name en Firebase Auth
      print('🔐 EditarPerfil: Actualizando display name en Firebase Auth...');
      await user.updateDisplayName(nuevoNombre);
      await user.reload();
      print('✅ EditarPerfil: Display name actualizado');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      print('❌ EditarPerfil: Error en actualización de nombre - $e');
      
      if (mounted) {
        String errorMessage;
        
        // Detectar errores específicos de Firebase y proporcionar mensajes amigables
        if (errorString.contains('unavailable') || 
            errorString.contains('timeout') || 
            errorString.contains('network') || 
            errorString.contains('connection')) {
          errorMessage = 'El servidor no está disponible temporalmente. Verifica tu conexión a internet e inténtalo de nuevo en unos momentos.';
        } else if (errorString.contains('permission-denied') || 
                   errorString.contains('unauthorized')) {
          errorMessage = 'No tienes permisos para actualizar tu perfil. Verifica tu cuenta.';
        } else if (errorString.contains('unauthenticated') ||
                   (errorString.contains('user') && errorString.contains('auth'))) {
          errorMessage = 'Tu sesión ha expirado. Inicia sesión nuevamente e inténtalo de nuevo.';
        } else if (errorString.contains('quota-exceeded') ||
                   errorString.contains('resource-exhausted')) {
          errorMessage = 'Se ha superado la cuota de uso. Inténtalo más tarde.';
        } else if (errorString.contains('deadline-exceeded') ||
                   errorString.contains('cancelled')) {
          errorMessage = 'La operación tardó demasiado tiempo. Verifica tu conexión e inténtalo de nuevo.';
        } else if (errorString.contains('perdió') && errorString.contains('conexión')) {
          errorMessage = e.toString(); // Usar mensaje específico de pérdida de conexión
        } else if (errorString.contains('vacío')) {
          errorMessage = 'El nombre no puede estar vacío.';
        } else if (errorString.contains('usuario') && errorString.contains('autenticado')) {
          errorMessage = e.toString(); // Usar mensaje específico de autenticación
        } else {
          // Para cualquier otro error, usar un mensaje genérico y amigable
          errorMessage = 'No se pudo actualizar el perfil. Verifica tu conexión a internet e inténtalo de nuevo.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _mostrarDialogoEliminarCuenta() async {
    // Verificación inicial de conectividad antes de navegar
    print('🔍 EditarPerfil: Verificando conexión para eliminar cuenta...');
    try {
      // Usar lookup DNS para verificación más robusta de conectividad
      final result = await InternetAddress.lookup('dns.google').timeout(const Duration(seconds: 10));
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw Exception('No internet connection');
      }
      print('✅ EditarPerfil: Conectividad confirmada para eliminación de cuenta');
    } catch (e) {
      print('❌ EditarPerfil: No hay conexión a internet para eliminar cuenta');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay conexión a internet. Se requiere conectividad estable para eliminar tu cuenta de forma segura.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Navegar a la pantalla de eliminar cuenta
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EliminarCuenta()),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AbsorbPointer(
        absorbing: !_hasInternet,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: AppColors.backgroundPrimary,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(0),
              children: [
                Container(
                  color: AppColors.slateGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: AppColors.white,
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Editar Perfil',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _mostrarDialogoEliminarCuenta();
                        },
                        child: const Text(
                          'Eliminar cuenta',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_hasInternet)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.warning,
                    child: const Text(
                      'No tienes conexión a internet. No puedes editar tu perfil.',
                      style: TextStyle(color: AppColors.textWhite),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Center(
                          child: Stack(
                            children: [
                              Card(
                                shape: const CircleBorder(),
                                color: Colors.transparent,
                                elevation: 4,
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundColor: AppColors.forestGreen,
                                  backgroundImage: (_profileUrl != null && _profileUrl!.isNotEmpty)
                                      ? NetworkImage(_profileUrl!)
                                      : null,
                                  child: (_profileUrl == null || _profileUrl!.isEmpty)
                                      ? const Icon(Icons.person, size: 60, color: AppColors.slateGrey)
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: FloatingActionButton(
                                  mini: true,
                                  backgroundColor: AppColors.buttonGreen3,
                                  onPressed: _loading ? null : _pickImage,
                                  child: const Icon(Icons.edit, color: AppColors.textWhite),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: _nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre completo',
                            labelStyle: const TextStyle(color: AppColors.textWhite),
                            filled: true,
                            fillColor: AppColors.slateGreen,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.person_outline, color: AppColors.textWhite),
                          ),
                          style: const TextStyle(color: AppColors.textWhite),
                          validator: (value) =>
                              value == null || value.trim().isEmpty ? 'Ingresa tu nombre' : null,
                        ),
                        const SizedBox(height: 32),
                        
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonBrown2,
                                  foregroundColor: AppColors.textBlack,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonGreen2,
                                  foregroundColor: AppColors.textBlack,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: _loading ? null : _guardarCambios,
                                child: _loading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CambiarContrasenaScreen()),
                              );
                            },
                            child: const Text(
                              'Cambiar contraseña',
                              style: TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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