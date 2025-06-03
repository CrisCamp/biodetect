import 'package:flutter/material.dart';
import '../../../themes.dart';

class RegDatos extends StatelessWidget {
  const RegDatos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
            child: Column(
              children: [
                // Card principal
                Card(
                  color: AppColors.backgroundCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.white, width: 2),
                  ),
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Header: Título y botón de cierre
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new),
                              color: AppColors.white,
                              onPressed: () => Navigator.pop(context),
                              iconSize: 28,
                            ),
                            const Expanded(
                              child: Text(
                                'Datos del Registro',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Imagen relacionada al registro
                        Card(
                          color: AppColors.backgroundCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.white, width: 1),
                          ),
                          elevation: 4,
                          margin: EdgeInsets.zero,
                          child: SizedBox(
                            height: 180,
                            width: double.infinity,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              // child: Image.asset(
                              //   'assets/images/IMAGEN_DE_EJEMPLO.jpg',
                              //   fit: BoxFit.cover,
                              // ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Formulario de datos
                        Column(
                          children: [
                            // Orden taxonómico (solo lectura)
                            TextFormField(
                              enabled: false,
                              decoration: InputDecoration(
                                labelText: 'Orden taxonómico',
                                filled: true,
                                fillColor: AppColors.paleGreen,
                                labelStyle: const TextStyle(color: AppColors.textWhite),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: AppColors.textWhite),
                            ),
                            const SizedBox(height: 16),
                            // Clase
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Clase',
                                filled: true,
                                fillColor: AppColors.paleGreen,
                                labelStyle: const TextStyle(color: AppColors.textWhite),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: AppColors.textWhite),
                            ),
                            const SizedBox(height: 16),
                            // Ubicación
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.buttonBlue1,
                                      foregroundColor: AppColors.textWhite,
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      minimumSize: const Size(0, 48),
                                    ),
                                    onPressed: () {
                                      // Acción para obtener ubicación
                                    },
                                    child: const Text('Obtener ubicación'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Lat: 0\nLon: 0',
                                    style: const TextStyle(
                                      color: AppColors.textWhite,
                                      fontSize: 15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Hábitat (dropdown)
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Hábitat',
                                filled: true,
                                fillColor: AppColors.paleGreen,
                                labelStyle: const TextStyle(color: AppColors.textWhite),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              dropdownColor: AppColors.paleGreen,
                              items: const [
                                DropdownMenuItem(value: 'Bosque', child: Text('Bosque')),
                                DropdownMenuItem(value: 'Selva', child: Text('Selva')),
                                DropdownMenuItem(value: 'Desierto', child: Text('Desierto')),
                                DropdownMenuItem(value: 'Urbano', child: Text('Urbano')),
                              ],
                              onChanged: (value) {},
                              style: const TextStyle(color: AppColors.textWhite),
                            ),
                            const SizedBox(height: 16),
                            // Detalles del hallazgo
                            TextFormField(
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Detalles del hallazgo',
                                filled: true,
                                fillColor: AppColors.paleGreen,
                                labelStyle: const TextStyle(color: AppColors.textWhite),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: AppColors.textWhite),
                            ),
                            const SizedBox(height: 16),
                            // Notas u observaciones
                            TextFormField(
                              maxLines: 4,
                              decoration: InputDecoration(
                                labelText: 'Notas u observaciones',
                                filled: true,
                                fillColor: AppColors.paleGreen,
                                labelStyle: const TextStyle(color: AppColors.textWhite),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              style: const TextStyle(color: AppColors.textWhite),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonBlue2,
                                  foregroundColor: AppColors.textWhite,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  // Guardar
                                },
                                child: const Text(
                                  'Guardar',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.buttonGreen1,
                                  foregroundColor: AppColors.textWhite,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  minimumSize: const Size(0, 48),
                                ),
                                onPressed: () {
                                  // Publicar
                                },
                                child: const Text(
                                  'Publicar',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}