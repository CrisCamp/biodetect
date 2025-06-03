import 'package:flutter/material.dart';
import '../../../themes.dart';

class DetalleRegistro extends StatelessWidget {
  const DetalleRegistro({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Card(
            color: AppColors.backgroundCard,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header: botón de cerrar y título
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textWhite),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Detalles del Hallazgo',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 40), // Espacio para balancear el header
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Imagen del insecto (placeholder sin datos simulados)
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.paleGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textPaleGreen,
                        size: 80,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Lista de detalles (sin datos simulados)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        _DetalleCampo(label: 'Orden:', value: ''),
                        _DetalleCampo(label: 'Clase:', value: ''),
                        _DetalleCampo(label: 'Verificado:', value: ''),
                        _DetalleCampo(label: 'Coordenadas:', value: ''),
                        _DetalleCampo(label: 'Hábitat:', value: ''),
                        _DetalleCampo(label: 'Detalles:', value: ''),
                        _DetalleCampo(label: 'Observaciones:', value: ''),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Acciones (deshabilitadas si no hay datos)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blueLight.withOpacity(0.5),
                              foregroundColor: AppColors.textBlack,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning.withOpacity(0.5),
                              foregroundColor: AppColors.textBlack,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Eliminar'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Mensaje vacío si no hay datos
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'No hay detalles para mostrar.',
                          style: TextStyle(
                            color: AppColors.textPaleGreen,
                            fontSize: 18,
                          ),
                          textAlign: TextAlign.center,
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

class _DetalleCampo extends StatelessWidget {
  final String label;
  final String value;
  const _DetalleCampo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        value.isEmpty ? '$label —' : '$label $value',
        style: TextStyle(
          color: label == 'Orden:' ? AppColors.textBlack : AppColors.textWhite,
          fontWeight: label == 'Orden:' ? FontWeight.bold : FontWeight.normal,
          fontSize: 16,
        ),
      ),
    );
  }
}