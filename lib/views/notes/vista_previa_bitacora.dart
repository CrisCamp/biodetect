import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class VistaPreviaBitacoraScreen extends StatelessWidget {
  const VistaPreviaBitacoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cuando conectes tu base de datos, reemplaza esta lista por la real.
    final List<Map<String, dynamic>> registros = []; // Lista vacía por defecto

    return Scaffold(
      backgroundColor: AppColors.deepGreen,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonBlue1,
        foregroundColor: AppColors.textWhite,
        onPressed: () {
          // Acción para exportar a PDF
        },
        child: const Icon(Icons.picture_as_pdf),
        tooltip: 'Exportar a PDF',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Vista previa de bitácora',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              // Lista de registros o mensaje si está vacía
              registros.isEmpty
                  ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Text(
                    'No hay registros.',
                    style: TextStyle(
                      color: AppColors.textPaleGreen,
                      fontSize: 16,
                    ),
                  ),
                ),
              )
                  : Column(
                children: registros
                    .map((registro) => RegistroVistaPreviaCard(
                  imagen: registro['imagen'] ?? '',
                  mapa: registro['map'] ?? '',
                  orden: registro['orden'] ?? '',
                  clase: registro['clase'] ?? '',
                  verificado: registro['verificado'] ?? '',
                  coordenadas: registro['coordenadas'] ?? '',
                  habitat: registro['habitat'] ?? '',
                  detalles: registro['detalles'] ?? '',
                  observaciones: registro['observaciones'] ?? '',
                ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistroVistaPreviaCard extends StatelessWidget {
  final String imagen;
  final String mapa;
  final String orden;
  final String clase;
  final String verificado;
  final String coordenadas;
  final String habitat;
  final String detalles;
  final String observaciones;

  const RegistroVistaPreviaCard({
    super.key,
    required this.imagen,
    required this.mapa,
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
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.brownLight2, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagen,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            // Mapa
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                mapa,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Orden: $orden',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              'Clase: $clase',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
              ),
            ),
            Text(
              'Verificado: $verificado',
              style: const TextStyle(
                color: AppColors.textPaleGreen,
                fontSize: 14,
              ),
            ),
            Text(
              'Coordenadas: $coordenadas',
              style: const TextStyle(
                color: AppColors.textPaleGreen,
                fontSize: 14,
              ),
            ),
            Text(
              'Hábitat: $habitat',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
            ),
            Text(
              'Detalles: $detalles',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
            ),
            Text(
              'Observaciones: $observaciones',
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}