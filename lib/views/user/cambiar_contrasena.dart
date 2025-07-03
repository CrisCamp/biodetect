import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class CambiarContrasenaScreen extends StatefulWidget {
  const CambiarContrasenaScreen({super.key});

  @override
  State<CambiarContrasenaScreen> createState() => _CambiarContrasenaScreenState();
}

class _CambiarContrasenaScreenState extends State<CambiarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
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

  void _onGuardar() {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Simulación de proceso
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _loading = false;
        // Aquí iría la lógica real de cambio de contraseña
      });
    });
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
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
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                child: Card(
                  color: AppColors.backgroundCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Título
                          const Text(
                            'Cambiar Contraseña',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          // Campo: Contraseña actual
                          TextFormField(
                            controller: _currentController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Contraseña actual',
                              filled: true,
                              fillColor: AppColors.paleGreen,
                              hintStyle: const TextStyle(color: AppColors.textBlack),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: AppColors.textWhite),
                          ),
                          const SizedBox(height: 16),
                          // Campo: Nueva contraseña
                          TextFormField(
                            controller: _newController,
                            obscureText: true,
                            onChanged: _checkPasswordStrength,
                            decoration: InputDecoration(
                              hintText: 'Nueva contraseña',
                              filled: true,
                              fillColor: AppColors.paleGreen,
                              hintStyle: const TextStyle(color: AppColors.textBlack),
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
                          // Campo: Confirmar nueva contraseña
                          TextFormField(
                            controller: _confirmController,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: 'Confirmar nueva contraseña',
                              filled: true,
                              fillColor: AppColors.paleGreen,
                              hintStyle: const TextStyle(color: AppColors.textBlack),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            style: const TextStyle(color: AppColors.textWhite),
                          ),
                          const SizedBox(height: 24),
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
                          // Botones de acción
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.buttonBrown2,
                                    foregroundColor: AppColors.textBlack,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _loading
                                      ? null
                                      : () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    'Cancelar',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.buttonGreen2,
                                    foregroundColor: AppColors.textBlack,
                                    minimumSize: const Size(0, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _onGuardar,
                                  child: const Text(
                                    'Guardar cambios',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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