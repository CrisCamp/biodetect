import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
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
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadRememberPreference(); // <-- Cargar preferencia al iniciar
    _checkAutoLogin(); // <-- Verificar login automático
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Cargar preferencia de "recordar sesión"
  Future<void> _loadRememberPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email') ?? '';
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    setState(() {
      _remember = rememberMe;
      if (rememberMe && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    });
  }

  // Verificar si hay una sesión activa para login automático
  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final autoLogin = prefs.getBool('auto_login') ?? false;
    
    // Verificar si hay usuario logueado en Firebase
    final user = FirebaseAuth.instance.currentUser;
    
    if (autoLogin && user != null) {
      // Si está marcado "recordar sesión" y hay usuario activo, ir al menu
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenu()),
          );
        }
      });
    }
  }

  // Guardar preferencias de "recordar sesión"
  Future<void> _saveRememberPreference(String email, bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (remember) {
      // Guardar email y preferencias
      await prefs.setString('saved_email', email);
      await prefs.setBool('remember_me', true);
      await prefs.setBool('auto_login', true);
    } else {
      // Limpiar preferencias
      await prefs.remove('saved_email');
      await prefs.setBool('remember_me', false);
      await prefs.setBool('auto_login', false);
    }
  }

  // Función para login con Google (actualizada)
  Future<void> _onGoogleSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      if (googleUser == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Crear/actualizar documento del usuario
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        
        if (!docSnapshot.exists) {
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
          await userDoc.update({
            'loginAt': FieldValue.serverTimestamp(),
          });
        }

        // Guardar preferencias si "recordar sesión" está marcado
        await _saveRememberPreference(user.email ?? '', _remember);

        // Navegar al menu principal
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenu()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
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
      setState(() {
        _error = 'Error inesperado: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // Función para login con correo/contraseña (actualizada)
  Future<void> _onLogin() async {
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
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      final user = credential.user;
      if (user != null) {
        // Crear/actualizar documento del usuario
        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();
        
        if (!docSnapshot.exists) {
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
          await userDoc.update({
            'loginAt': FieldValue.serverTimestamp(),
          });
        }

        // Guardar preferencias si "recordar sesión" está marcado
        await _saveRememberPreference(_emailController.text.trim(), _remember);

        // Navegar al menu principal
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainMenu()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
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
          case 'too-many-requests':
            _error = 'Demasiados intentos fallidos. Intenta más tarde.';
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
                      // Campo: Contraseña con ojo dinámico
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Contraseña',
                          filled: true,
                          fillColor: AppColors.slateGreen,
                          hintStyle: const TextStyle(color: AppColors.textWhite),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textWhite.withOpacity(0.7),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textWhite),
                      ),
                      const SizedBox(height: 8),
                      // Recordar sesión (actualizado)
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
                            checkColor: AppColors.textBlack,
                          ),
                          const Text(
                            'Recordar sesión',
                            style: TextStyle(color: AppColors.textWhite),
                          ),
                          // Agregar icono de información
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Mantiene tu sesión activa para no tener que iniciar sesión cada vez.',
                                      style: TextStyle(color: AppColors.textWhite),
                                    ),
                                    backgroundColor: AppColors.slateGreen,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              },
                              child: Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppColors.textWhite.withOpacity(0.7),
                              ),
                            ),
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
                          );
                        },
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
                      // Botón: Iniciar con Google
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
                          onPressed: _loading ? null : _onGoogleSignIn,
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
                          );
                        },
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