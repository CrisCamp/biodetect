import 'package:flutter/material.dart';
import '../../../themes.dart';

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

  void _onRegistrar() {
    if (!_aceptaTerminos) {
      setState(() {
        _error = 'Debes aceptar los términos y condiciones.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    // Simulación de proceso de registro
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _loading = false;
        // Aquí iría la lógica real de registro
      });
    });
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
                        visible: false, // Cambia a true si quieres mostrar la advertencia
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
                          onPressed: _loading ? null : () {
                            // Acción para registro con Google
                          },
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