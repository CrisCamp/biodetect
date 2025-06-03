import 'package:flutter/material.dart';
import '../../views/user/recuperar_contrasena.dart';
import '../../views/session/registro.dart';
import '../../../themes.dart';

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

  void _onLogin() {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Simulación de proceso de login
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _loading = false;
        // Aquí iría la lógica real de autenticación
        // Si hay error, asigna un mensaje a _error
      });
    });
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
                          onPressed: _loading ? null : () {
                            // Acción para login con Google
                          },
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