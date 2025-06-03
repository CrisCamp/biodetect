import 'package:flutter/material.dart';
import '../../../themes.dart';

class EditarPerfil extends StatelessWidget {
  const EditarPerfil({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              // Header igual a MisBitacorasScreen
              Container(
                color: AppColors.slateGreen,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Editar Perfil',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Foto de perfil editable
                    Center(
                      child: Stack(
                        children: [
                          Card(
                            shape: const CircleBorder(),
                            color: Colors.transparent,
                            elevation: 4,
                            child: CircleAvatar(
                              radius: 60,
                              backgroundColor: AppColors.forestGreen,
                              child: CircleAvatar(
                                radius: 57,
                                backgroundImage: const AssetImage('assets/ic_default_profile.png'),
                                backgroundColor: AppColors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: FloatingActionButton(
                              mini: true,
                              backgroundColor: AppColors.buttonGreen3,
                              onPressed: () {
                                // Acción para editar foto
                              },
                              child: const Icon(Icons.edit, color: AppColors.textWhite),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Campo: Nombre completo
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nombre completo',
                        labelStyle: const TextStyle(color: AppColors.textWhite),
                        filled: true,
                        fillColor: AppColors.slateGreen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textWhite),
                    ),
                    const SizedBox(height: 16),
                    // Campo: Correo electrónico
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: const TextStyle(color: AppColors.textWhite),
                        filled: true,
                        fillColor: AppColors.slateGreen,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textWhite),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    // Botones de acción
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonBrown2,
                              foregroundColor: AppColors.textBlack,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.buttonGreen2,
                              foregroundColor: AppColors.textBlack,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () {
                              // Acción para guardar cambios
                            },
                            child: const Text('Guardar cambios', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    // Enlace para cambiar contraseña
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Acción para cambiar contraseña
                        },
                        child: const Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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