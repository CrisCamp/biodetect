import 'package:flutter/material.dart';
import '../../themes.dart';

class GaleriaInsigniasScreen extends StatelessWidget {
  const GaleriaInsigniasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista vacía, esperando datos reales
    final List insignias = [];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header como en otras vistas
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
                      'Galería de Insignias',
                      style: TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Grid de insignias o mensaje vacío
              Expanded(
                child: insignias.isEmpty
                    ? Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.emoji_events_outlined, color: AppColors.textPaleGreen, size: 64),
                          SizedBox(height: 24),
                          Text(
                            'Aún no tienes badges.\n¡Participa para ganar tus primeras badges!',
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: insignias.length,
                  itemBuilder: (context, index) {
                    final insignia = insignias[index];
                    // Aquí deberás mapear los datos reales a los parámetros del widget
                    return InsigniaCard(
                      icon: insignia['icon'],
                      nombre: insignia['nombre'],
                      nombreColor: insignia['nombreColor'],
                      progreso: insignia['progreso'],
                      progresoTexto: insignia['progresoTexto'],
                      cantidad: insignia['cantidad'],
                      cantidadColor: insignia['cantidadColor'],
                      descripcion: insignia['descripcion'],
                      motivacion: insignia['motivacion'],
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

class InsigniaCard extends StatelessWidget {
  final IconData icon;
  final String nombre;
  final Color nombreColor;
  final double progreso;
  final String progresoTexto;
  final String cantidad;
  final Color cantidadColor;
  final String descripcion;
  final String motivacion;

  const InsigniaCard({
    super.key,
    required this.icon,
    required this.nombre,
    required this.nombreColor,
    required this.progreso,
    required this.progresoTexto,
    required this.cantidad,
    required this.cantidadColor,
    required this.descripcion,
    required this.motivacion,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header: Icono y nombre
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.backgroundLightGradient,
                  ),
                  child: Icon(icon, size: 36, color: nombreColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    nombre,
                    style: TextStyle(
                      color: nombreColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progreso circular simulado
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: progreso,
                    backgroundColor: AppColors.slateGreen,
                    valueColor: AlwaysStoppedAnimation<Color>(nombreColor),
                    strokeWidth: 6,
                  ),
                ),
                Text(
                  progresoTexto,
                  style: const TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              cantidad,
              style: TextStyle(
                color: cantidadColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              descripcion,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              motivacion,
              style: const TextStyle(
                color: AppColors.textBlack,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}