import 'package:flutter/material.dart';
import '../../themes.dart';

class BitacoraPublicaListItem extends StatelessWidget {
  final String titulo;
  final String autor;
  final int registros;
  final String? imagenUrl; // Puede ser null para mostrar un ícono por defecto

  const BitacoraPublicaListItem({
    super.key,
    required this.titulo,
    required this.autor,
    required this.registros,
    this.imagenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.slateGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.buttonGreen2, width: 1),
      ),
      elevation: 8,
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // Acción al tocar la bitácora (por ejemplo, navegar al detalle)
        },
        child: Row(
          children: [
            // Imagen de portada o ícono
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: imagenUrl != null
                  ? Image.network(
                imagenUrl!,
                width: 90,
                height: 90,
                fit: BoxFit.cover,
              )
                  : Container(
                width: 90,
                height: 90,
                color: AppColors.slateGreen,
                child: const Icon(Icons.menu_book, size: 48, color: AppColors.textWhite),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        color: AppColors.buttonGreen2,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Por: $autor',
                      style: const TextStyle(
                        color: AppColors.textSand,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$registros registros',
                      style: const TextStyle(
                        color: AppColors.textPaleGreen,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExplorarBitacorasPublicasScreen extends StatelessWidget {
  const ExplorarBitacorasPublicasScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                color: AppColors.slateGreen,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Explorar bitácoras públicas',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              // Barra de búsqueda
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar bitácoras...',
                    hintStyle: const TextStyle(color: AppColors.textPaleGreen),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textWhite),
                    filled: true,
                    fillColor: AppColors.slateGreen,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  style: const TextStyle(color: AppColors.textWhite),
                ),
              ),
              // Chips de filtrado
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Alfabetico'),
                      selected: false,
                      backgroundColor: AppColors.buttonGreen2,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.brownDark3, width: 1),
                      ),
                      labelStyle: const TextStyle(color: AppColors.textWhite),
                      onSelected: (_) {},
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Fecha'),
                      selected: false,
                      backgroundColor: AppColors.buttonGreen2,
                      shape: StadiumBorder(
                        side: BorderSide(color: AppColors.brownDark3, width: 1),
                      ),
                      labelStyle: const TextStyle(color: AppColors.textWhite),
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
              // Lista vacía (aquí conectarás Firebase más adelante)
              const Expanded(
                child: Center(
                  child: Text(
                    'No hay bitácoras públicas para mostrar.',
                    style: TextStyle(
                      color: AppColors.textPaleGreen,
                      fontSize: 16,
                    ),
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