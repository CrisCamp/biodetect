import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- Agregar import

class Registro extends StatefulWidget {
  const Registro({super.key});

  @override
  State<Registro> createState() => _RegistroState();
}

class _RegistroState extends State<Registro> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _aceptaTerminos = false;
  String? _error;
  int _passwordStrength = 0;

  void _checkPasswordStrength(String value) {
    int strength = 0;
    if (value.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(value)) strength++;
    if (RegExp(r'[a-z]').hasMatch(value)) strength++;
    if (RegExp(r'[0-9]').hasMatch(value)) strength++;
    if (RegExp(r'[!@#\$&*~]').hasMatch(value)) strength++;
    setState(() {
      _passwordStrength = strength;
    });
  }

  Future<void> _onRegistrar() async {
    if (!_aceptaTerminos) {
      setState(() {
        _error = 'Debes aceptar los términos y condiciones.';
      });
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Las contraseñas no coinciden.';
      });
      return;
    }
    if (_passwordStrength < 3) {
      setState(() {
        _error = 'La contraseña es demasiado débil.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Crear usuario en Firebase Auth
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user != null) {
        // Guardar datos en Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'fullname': _nombreController.text.trim(),
          'profilePicture': '',
          'createdAt': FieldValue.serverTimestamp(),
          'loginAt': FieldValue.serverTimestamp(),
          'badges': [],
        });
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? 'Error al registrar usuario.';
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

  // Función para registro con Google (idéntica al login)
  Future<void> _onGoogleSignUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

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

      if (user != null) {
        // Crear/actualizar documento del usuario
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'fullname': user.displayName ?? '',
          'profilePicture': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'loginAt': FieldValue.serverTimestamp(),
          'badges': [],
        }, SetOptions(merge: true)); // merge: true para no sobrescribir si existe

        // Regresar al login (registro exitoso)
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'account-exists-with-different-credential':
            _error = 'Ya existe una cuenta con este correo usando otro método.';
            break;
          default:
            _error = e.message ?? 'Error al registrarse con Google.';
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
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
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
                      // Advertencia institucional
                      Visibility(
                        visible: false,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            '⚠ Usa tu correo institucional (@cucba.edu.mx) para acceder al foro.',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      // Campo: Nombre completo
                      TextFormField(
                        controller: _nombreController,
                        decoration: InputDecoration(
                          hintText: 'Nombre completo',
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
                      // Campo: Correo institucional
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
                        onChanged: _checkPasswordStrength,
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
                      // Barra de fortaleza de contraseña
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: List.generate(5, (i) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.symmetric(horizontal: i == 1 || i == 3 ? 2 : 0),
                                decoration: BoxDecoration(
                                  color: i < _passwordStrength
                                      ? AppColors.mintGreen
                                      : AppColors.slateGrey,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      // Campo: Confirmar contraseña
                      TextFormField(
                        controller: _confirmController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Confirmar contraseña',
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
                      // Checkbox Términos y condiciones
                      Row(
                        children: [
                          Checkbox(
                            value: _aceptaTerminos,
                            onChanged: (value) {
                              setState(() {
                                _aceptaTerminos = value ?? false;
                              });
                            },
                            activeColor: AppColors.buttonGreen2,
                          ),
                          const Text(
                            'Acepto los ',
                            style: TextStyle(color: AppColors.textBlack),
                          ),
                          GestureDetector(
                            onTap: () {
                              // Acción para mostrar términos y condiciones
                            },
                            child: const Text(
                              'términos y condiciones',
                              style: TextStyle(
                                color: AppColors.textBlueNormal,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                      // Botón: Crear cuenta
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonGreen2,
                            foregroundColor: AppColors.textBlack,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _loading ? null : _onRegistrar,
                          child: _loading
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.textBlack,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Crear cuenta'),
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
                      // Botón: Registrarse con Google
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.textBlack,
                            textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: Image.asset(
                            'assets/ic_google.png',
                            width: 24,
                            height: 24,
                          ),
                          label: const Text('Registrarse con Google'),
                          onPressed: _loading ? null : _onGoogleSignUp, // <-- Cambiar aquí
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Enlace a Login
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
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
          ),
        ),
      ),
    );
  }
}