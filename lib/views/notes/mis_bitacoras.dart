import 'package:flutter/material.dart';
import '../../themes.dart';
import 'crear_editar_bitacora_screen.dart';

class MisBitacorasScreen extends StatelessWidget {
  const MisBitacorasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aquí deberás conectar tu base de datos y obtener la lista real
    final List<Map<String, dynamic>> bitacoras = []; // Lista vacía por defecto

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.buttonGreen2,
        foregroundColor: AppColors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrearEditarBitacoraScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Nueva bitácora',
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
                        'Mis Bitácoras',
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
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar mis bitácoras...',
                    hintStyle: const TextStyle(color: AppColors.textPaleGreen),
                    prefixIcon: const Icon(Icons.search, color: AppColors.white),
                    filled: true,
                    fillColor: AppColors.slateGreen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  style: const TextStyle(color: AppColors.white),
                ),
              ),
              // Chips de filtrado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Públicas'),
                      selected: false,
                      backgroundColor: AppColors.buttonGreen2,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.brownDark3, width: 1),
                      ),
                      labelStyle: const TextStyle(color: AppColors.white),
                      onSelected: (_) {},
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Privadas'),
                      selected: false,
                      backgroundColor: AppColors.buttonGreen2,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.brownDark3, width: 1),
                      ),
                      labelStyle: const TextStyle(color: AppColors.white),
                      onSelected: (_) {},
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Exportadas'),
                      selected: false,
                      backgroundColor: AppColors.buttonGreen2,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.brownDark3, width: 1),
                      ),
                      labelStyle: const TextStyle(color: AppColors.white),
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
              // Lista de bitácoras o mensaje si está vacía
              Expanded(
                child: bitacoras.isEmpty
                    ? const Center(
                  child: Text(
                    'No hay bitácoras disponibles.',
                    style: TextStyle(
                      color: AppColors.textPaleGreen,
                      fontSize: 16,
                    ),
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: bitacoras.length,
                  itemBuilder: (context, index) {
                    final bitacora = bitacoras[index];
                    return MisBitacoraListItem(
                      titulo: bitacora['titulo'] ?? '',
                      registros: bitacora['registros'] ?? 0,
                      onEdit: () {},
                      onDelete: () {},
                      onExport: () {},
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MisBitacoraListItem extends StatelessWidget {
  final String titulo;
  final int registros;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const MisBitacoraListItem({
    super.key,
    required this.titulo,
    required this.registros,
    required this.onEdit,
    required this.onDelete,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.slateGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.white, width: 2),
      ),
      elevation: 10,
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Portada
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.slateGreen,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Icon(Icons.menu_book, size: 64, color: AppColors.white),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 2),
            child: Text(
              titulo,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
            child: Text(
              'Por: Yo  •  $registros registros',
              style: const TextStyle(
                color: AppColors.textSand,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Acciones rápidas
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.white),
                  tooltip: 'Editar',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.warning),
                  tooltip: 'Eliminar',
                  onPressed: onDelete,
                ),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: AppColors.buttonGreen2),
                  tooltip: 'Exportar',
                  onPressed: onExport,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}