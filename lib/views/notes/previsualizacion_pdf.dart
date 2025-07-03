import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class PrevisualizacionBitacoraScreen extends StatelessWidget {
  const PrevisualizacionBitacoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Centra todo el contenido
            children: [
              // Header con botón de retroceso y título centrado
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: AppColors.textBlack,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Explorar bitácoras públicas',
                        style: const TextStyle(
                          color: AppColors.textBlack,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 35),
                ],
              ),
              // Portada del PDF centrada
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    // Logo centrado
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        child: Image.asset(
                          'assets/ic_logo_biodetect.png', // Cambia la ruta según tu proyecto
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Título de la bitácora centrado
                    Center(
                      child: Text(
                        '', // Aquí irá el título dinámico
                        style: const TextStyle(
                          color: AppColors.textBlack,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Usuario centrado
                    Center(
                      child: Text(
                        '', // Aquí irá el usuario dinámico
                        style: const TextStyle(
                          color: AppColors.textGraphite,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Fecha centrada
                    Center(
                      child: Text(
                        '', // Aquí irá la fecha dinámica
                        style: const TextStyle(
                          color: AppColors.textBlack,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Título de registros centrado
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'Registros',
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // Lista de registros (diseño listo para datos dinámicos)
              Column(
                children: [
                  // Cuando conectes tu base de datos, usa un ListView.builder o similar aquí
                  // Ejemplo de uso:
                  // ... registros.map((registro) => RegistroCard(...)).toList(),
                ],
              ),
              // Botones de acción centrados
              Padding(
                padding: const EdgeInsets.only(top: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonBlue1,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('Descargar PDF'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonGreen1,
                        foregroundColor: AppColors.textWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('Compartir'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistroCard extends StatelessWidget {
  final String imagen;
  final String orden;
  final String clase;
  final String verificado;
  final String coordenadas;
  final String habitat;
  final String detalles;
  final String observaciones;

  const RegistroCard({
    super.key,
    required this.imagen,
    required this.orden,
    required this.clase,
    required this.verificado,
    required this.coordenadas,
    required this.habitat,
    required this.detalles,
    required this.observaciones,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagen,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orden: $orden',
              style: const TextStyle(
                color: AppColors.textBlack,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              'Clase: $clase',
              style: const TextStyle(
                color: AppColors.textBlack,
                fontSize: 14,
              ),
            ),
            Text(
              'Verificado: $verificado',
              style: const TextStyle(
                color: AppColors.textGraphite,
                fontSize: 14,
              ),
            ),
            Text(
              'Coordenadas: $coordenadas',
              style: const TextStyle(
                color: AppColors.textGraphite,
                fontSize: 14,
              ),
            ),
            Text(
              'Hábitat: $habitat',
              style: const TextStyle(
                color: AppColors.textBlack,
                fontSize: 14,
              ),
            ),
            Text(
              'Detalles: $detalles',
              style: const TextStyle(
                color: AppColors.textBlack,
                fontSize: 14,
              ),
            ),
            Text(
              'Observaciones: $observaciones',
              style: const TextStyle(
                color: AppColors.textBlack,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}