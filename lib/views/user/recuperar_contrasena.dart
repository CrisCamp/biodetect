import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class RecuperarContrasena extends StatefulWidget {
  const RecuperarContrasena({super.key});

  @override
  State<RecuperarContrasena> createState() => _RecuperarContrasenaState();
}

class _RecuperarContrasenaState extends State<RecuperarContrasena> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  void _onRecuperar() {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Simulación de proceso de recuperación
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _loading = false;
        // Aquí iría la lógica real de recuperación
        // Si hay error, asigna un mensaje a _error
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: AppColors.backgroundCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/ic_logo_biodetect.png',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: 16),
                    // Título
                    const Text(
                      'Recuperar Contraseña',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Instrucciones
                    const Text(
                      'Ingresa tu correo electrónico para recibir un enlace de restablecimiento.',
                      style: TextStyle(
                        color: AppColors.textBlack,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    // Campo: Correo Electrónico
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Correo electrónico',
                        filled: true,
                        fillColor: AppColors.paleGreen,
                        hintStyle: const TextStyle(color: AppColors.textBlack),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textBlack),
                    ),
                    const SizedBox(height: 16),
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
                    // Botón: Recuperar Contraseña
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.seaGreen,
                          foregroundColor: AppColors.white,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _loading ? null : _onRecuperar,
                        child: _loading
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text('Enviar enlace de recuperación'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Enlace: Volver a Iniciar Sesión
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Volver a Iniciar Sesión',
                        style: TextStyle(
                          color: AppColors.textBlack,
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
    );
  }
}