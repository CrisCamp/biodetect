import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';

class CrearEditarBitacoraScreen extends StatelessWidget {
  const CrearEditarBitacoraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonGreen1,
        foregroundColor: AppColors.textWhite,
        onPressed: () {},
        child: const Icon(Icons.save),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                color: AppColors.slateGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Editar Bitácora',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 35),
                  ],
                ),
              ),
              // Formulario y lista de registros
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título de la Bitácora
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Título de la bitácora',
                          labelStyle: const TextStyle(color: AppColors.textPaleGreen),
                          filled: true,
                          fillColor: AppColors.textWhite,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.brownDark3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.brownDark3, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(fontSize: 18, color: AppColors.textBlack),
                      ),
                      const SizedBox(height: 16),
                      // Descripción
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          labelStyle: const TextStyle(color: AppColors.textPaleGreen),
                          filled: true,
                          fillColor: AppColors.textWhite,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.brownDark3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.brownDark3, width: 2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textBlack),
                      ),
                      const SizedBox(height: 24),
                      // Título de registros
                      const Text(
                        'Registros seleccionados:',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Lista de registros seleccionados (vacía por defecto)
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.textWhite.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'No hay registros seleccionados.',
                          style: TextStyle(color: AppColors.textPaleGreen),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Botón "Añadir registros desde el álbum"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_photo_alternate, color: AppColors.textWhite),
                          label: const Text('Añadir registros desde el álbum'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonBlue2,
                            foregroundColor: AppColors.textWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón "Hacer pública la bitácora"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          child: const Text('Hacer pública la bitácora'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonGreen2,
                            foregroundColor: AppColors.textWhite,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}