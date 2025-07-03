import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- Agregar import
import 'package:biodetect/views/user/recuperar_contrasena.dart';
import 'package:biodetect/views/session/registro.dart';
import 'package:biodetect/menu.dart';

class InicioSesion extends StatefulWidget {
  const InicioSesion({super.key});

  @override
  State<InicioSesion> createState() => _InicioSesionState();
}

class _InicioSesionState extends State<InicioSesion> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _remember = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función para login con Google
  Future<void> _onGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      print('Iniciando Google Sign-In...'); // Debug

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        // El usuario canceló el login
        setState(() {
          _loading = false;
        });
        return;
      }

      print('Usuario Google seleccionado: ${googleUser.email}'); // Debug

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credentials
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      print('Login con Google exitoso: ${user?.email}'); // Debug

      if (user != null) {
        // Verifica si el documento del usuario existe
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        
        if (!docSnapshot.exists) {
          // Si no existe, créalo con los datos de Google
          await userDoc.set({
            'uid': user.uid,
            'email': user.email,
            'fullname': user.displayName ?? '',
            'profilePicture': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'loginAt': FieldValue.serverTimestamp(),
            'badges': [],
          });
          print('Documento de usuario creado en Firestore'); // Debug
        } else {
          // Si existe, actualiza la fecha de último login
          await userDoc.update({
            'loginAt': FieldValue.serverTimestamp(),
          });
          print('Documento de usuario actualizado en Firestore'); // Debug
        }

        // Navegar a la pantalla principal
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainMenu(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase Auth: ${e.code} - ${e.message}'); // Debug
      setState(() {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            _error = 'Ya existe una cuenta con este correo usando otro método.';
            break;
          case 'invalid-credential':
            _error = 'Las credenciales de Google son inválidas.';
            break;
          case 'operation-not-allowed':
            _error = 'El login con Google no está habilitado.';
            break;
          default:
            _error = e.message ?? 'Error al iniciar sesión con Google.';
        }
      });
    } catch (e) {
      print('Error general: $e'); // Debug
      setState(() {
        _error = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onLogin() async {
    // Agregar validación básica
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = 'Por favor completa todos los campos.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    
    try {
      print('Intentando login con: ${_emailController.text.trim()}'); // Debug
      
      // Autenticación con correo y contraseña
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      print('Login exitoso: ${credential.user?.email}'); // Debug
      
      final user = credential.user;
      if (user != null) {
        // Verifica si el documento del usuario existe
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          // Si no existe, créalo con los datos básicos
          await userDoc.set({
            'uid': user.uid,
            'email': user.email,
            'fullname': user.displayName ?? '',
            'profilePicture': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'loginAt': FieldValue.serverTimestamp(),
            'badges': [],
          });
        } else {
          // Si existe, actualiza la fecha de último login
          await userDoc.update({
            'loginAt': FieldValue.serverTimestamp(),
          });
        }
        // Aquí puedes navegar a la pantalla principal de tu app
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainMenu(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      print('Error de Firebase: ${e.code} - ${e.message}'); // Debug
      setState(() {
        switch (e.code) {
          case 'user-not-found':
            _error = 'No existe una cuenta con este correo.';
            break;
          case 'wrong-password':
            _error = 'Contraseña incorrecta.';
            break;
          case 'invalid-email':
            _error = 'El correo no es válido.';
            break;
          default:
            _error = e.message ?? 'Error al iniciar sesión.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/ic_logo_biodetect.png',
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 24),
                      // Campo: Correo Electrónico
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Correo',
                          filled: true,
                          fillColor: AppColors.slateGreen,
                          hintStyle: const TextStyle(color: AppColors.textWhite),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textWhite),
                      ),
                      const SizedBox(height: 16),
                      // Campo: Contraseña
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          filled: true,
                          fillColor: AppColors.slateGreen,
                          hintStyle: const TextStyle(color: AppColors.textWhite),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textWhite),
                      ),
                      const SizedBox(height: 8),
                      // Recordar sesión
                      Row(
                        children: [
                          Checkbox(
                            value: _remember,
                            onChanged: (value) {
                              setState(() {
                                _remember = value ?? false;
                              });
                            },
                            activeColor: AppColors.buttonGreen2,
                          ),
                          const Text(
                            'Recordar sesión',
                            style: TextStyle(color: AppColors.textWhite),
                          ),
                        ],
                      ),
                      // Mensaje de error
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      // Botón: Iniciar Sesión
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonGreen2,
                            foregroundColor: AppColors.textBlack,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _loading ? null : _onLogin,
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ¿Olvidaste tu contraseña?
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RecuperarContrasena(),
                            ),
                          );                        },
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Separador estilizado
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.brownDark3,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'O',
                              style: TextStyle(color: AppColors.textWhite),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.brownDark3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Botón: Iniciar con Google (ACTUALIZADO)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.textBlack,
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/ic_google.png',
                            width: 24,
                            height: 24,
                          ),
                          label: const Text(
                            'Continuar con Google',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: _loading ? null : _onGoogleSignIn, // <-- Cambiar aquí
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ¿No tienes cuenta? Regístrate
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Registro(),
                            ),
                          );                        },
                        child: const Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ProgressBar para carga
            if (_loading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.mintGreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}