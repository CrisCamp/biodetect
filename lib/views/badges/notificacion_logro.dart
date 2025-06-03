import 'package:flutter/material.dart';
import '../../themes.dart';
// Si usas Lottie, descomenta la siguiente línea y agrega el paquete lottie en pubspec.yaml
// import 'package:lottie/lottie.dart';

class NotificacionLogroScreen extends StatelessWidget {
  final String titulo;
  final String nombreInsignia;
  final String descripcion;
  final String? lottieAsset; // Ejemplo: 'assets/badge_unlocked_anim.json'
  final String? imagenInsignia; // Ejemplo: 'assets/ic_badge_expert.png'
  final VoidCallback? onOk;

  const NotificacionLogroScreen({
    super.key,
    this.titulo = '¡Insignia Desbloqueada!',
    this.nombreInsignia = 'Identificador Experto',
    this.descripcion = '¡Has identificado 50 especies y alcanzado el nivel Experto!',
    this.lottieAsset,
    this.imagenInsignia,
    this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepGreen,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animación Lottie (opcional)
              // Si tienes el paquete lottie y el asset, descomenta lo siguiente:
              // if (lottieAsset != null)
              //   Lottie.asset(
              //     lottieAsset!,
              //     width: 200,
              //     height: 200,
              //     repeat: false,
              //   ),
              const SizedBox(height: 16),
              // Card de notificación
              Card(
                color: AppColors.backgroundCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 8,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: AppColors.aquaBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      // Imagen de la insignia
                      Container(
                        width: 80,
                        height: 80,
                        margin: const EdgeInsets.only(top: 8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.aquaBlue,
                        ),
                        child: imagenInsignia != null
                            ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset(
                            imagenInsignia!,
                            fit: BoxFit.contain,
                          ),
                        )
                            : const Icon(
                          Icons.emoji_events,
                          color: AppColors.textWhite,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        nombreInsignia,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        descripcion,
                        style: const TextStyle(
                          color: AppColors.textSand,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonBlue1,
                          foregroundColor: AppColors.textWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: onOk ?? () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
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