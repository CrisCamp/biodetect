import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class MapaIterativoScreen extends StatefulWidget {
  const MapaIterativoScreen({super.key});

  @override
  State<MapaIterativoScreen> createState() => _MapaIterativoScreenState();
}

class _MapaIterativoScreenState extends State<MapaIterativoScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: Column(
          children: [
            // Header con botón de retroceso
            Container(
              color: AppColors.backgroundCard,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    color: AppColors.textWhite,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Mapa Interactivo',
                    style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Contenido principal expandible
            Expanded(
              child: Stack(
                children: [
                  // Aquí iría el widget real del mapa (ej: MapboxMap, GoogleMap, etc.)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: AppColors.paleGreen.withOpacity(0.2),
                    child: const Center(
                      child: Text(
                        'Aquí va el map interactivo',
                        style: TextStyle(
                          color: AppColors.textSlateGrey,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  // Botón: Centrar en ubicación actual (abajo a la derecha)
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: FloatingActionButton(
                      backgroundColor: AppColors.buttonGreen3,
                      foregroundColor: AppColors.textBlack,
                      onPressed: () {
                        // Acción para centrar mapa en ubicación actual
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}