import 'package:flutter/material.dart';
import '../../../themes.dart';

class AlbumFotos extends StatelessWidget {
  const AlbumFotos({super.key});

  @override
  Widget build(BuildContext context) {
    // Simula una consulta real, reemplaza por tu consulta a base de datos
    final List<Map<String, dynamic>> registros = [
      // Si no hay registros, deja la lista vacía
      // {'nombre': 'Lepidoptera', 'icono': 'assets/ic_directory.png'},
      // {'nombre': 'Coleoptera', 'icono': 'assets/ic_directory.png'},
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                    const Expanded(
                      child: Text(
                        'Álbum de registers',
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
              const SizedBox(height: 8),
              // Si hay registros, muestra el grid, si no, muestra el mensaje vacío
              Expanded(
                child: registros.isEmpty
                    ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.photo_library_outlined, color: AppColors.textPaleGreen, size: 64),
                          SizedBox(height: 24),
                          Text(
                            'No hay registros en el álbum.',
                            style: TextStyle(
                              color: AppColors.textPaleGreen,
                              fontSize: 18,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1,
                  ),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    final registro = registros[index];
                    return Card(
                      color: AppColors.backgroundCard,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.brownLight2, width: 1),
                      ),
                      elevation: 4,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Acción al abrir la carpeta o registro
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              registro['icono'],
                              height: 60,
                              width: 60,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              registro['nombre'],
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Botón de sincronizar
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.sync, color: AppColors.textBlack),
                    label: const Text(
                      'Sincronizar con Drive',
                      style: TextStyle(
                        color: AppColors.textBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Acción real de sincronizar con Drive
                    },
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