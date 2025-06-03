import 'package:flutter/material.dart';
import '../../views/registers/album_fotos.dart';
import '../../views/registers/captura_foto.dart';
import '../../views/map/mapa.dart';
import '../themes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio', style: TextStyle(color: AppColors.textWhite)),
        backgroundColor: AppColors.backgroundNavBarsLigth,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _MenuButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Álbum de Fotos',
                  color: AppColors.buttonBlue2,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AlbumFotos()),
                  ),
                ),
                const SizedBox(height: 18),
                _MenuButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Capturar Foto',
                  color: AppColors.buttonGreen2,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CapturaFoto()),
                  ),
                ),
                const SizedBox(height: 18),
                _MenuButton(
                  icon: Icons.map_outlined,
                  label: 'Mapa Interactivo',
                  color: AppColors.buttonBlue1,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapaIterativoScreen()),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: AppColors.textWhite, size: 28),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 6,
        alignment: Alignment.centerLeft,
      ),
      onPressed: onTap,
    );
  }
}