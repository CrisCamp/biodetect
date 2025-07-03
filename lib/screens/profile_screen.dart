import 'package:biodetect/views/notes/mis_bitacoras.dart';
import 'package:biodetect/views/user/editar_perfil.dart';
import 'package:biodetect/views/session/inicio_sesion.dart';
import 'package:flutter/material.dart';
import 'package:biodetect/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _cerrarSesion(BuildContext context) async {
    // Mostrar diálogo de confirmación
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundCard,
          title: const Text(
            '¿Cerrar sesión?',
            style: TextStyle(color: AppColors.textWhite),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: AppColors.textWhite),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppColors.textWhite),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Cerrar sesión',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
          ],
        );
      },
    );

    // Si el usuario confirmó, cerrar sesión
    if (confirmar == true && context.mounted) {
      try {
        // Mostrar indicador de carga
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.mintGreen),
          ),
        );

        // Cerrar sesión en Firebase
        await FirebaseAuth.instance.signOut();

        // Cerrar diálogo de carga
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Navegar a la pantalla de inicio de sesión
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InicioSesion()),
            (route) => false, // Elimina todas las pantallas anteriores
          );
        }
      } catch (e) {
        // Cerrar diálogo de carga si está abierto
        if (context.mounted) {
          Navigator.of(context).pop();
        }

        // Mostrar error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: $e'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Valores por defecto o mensaje si no hay datos
    final String nombre = "Nombre no disponible";
    final String correo = "Correo no disponible";
    final bool verificado = false;
    final int identificaciones = 0;
    final int bitacoras = 0;
    final int insignias = 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil de Usuario',
          style: TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.backgroundNavBarsLigth,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
        centerTitle: false, // Título alineado a la izquierda
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          children: [
            const SizedBox(height: 32),
            // Sección 1: Header
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Foto de perfil
                Card(
                  shape: const CircleBorder(),
                  color: Colors.transparent,
                  elevation: 4,
                  child: CircleAvatar(
                    radius: 75,
                    backgroundColor: AppColors.forestGreen,
                    child: CircleAvatar(
                      radius: 72,
                      backgroundImage: const AssetImage('assets/ic_default_profile.png'),
                      backgroundColor: AppColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nombre
                Text(
                  nombre.isNotEmpty ? nombre : "Nombre no disponible",
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Correo + verificación
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      correo.isNotEmpty ? correo : "Correo no disponible",
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 14,
                      ),
                    ),
                    if (verificado)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.verified, color: AppColors.aquaBlue, size: 20),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Sección 2: Estadísticas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _EstadisticaCard(
                    icon: Icons.bug_report,
                    label: "Identificaciones",
                    value: identificaciones,
                    iconColor: AppColors.textBlueNormal,
                  ),
                  _EstadisticaCard(
                    icon: Icons.menu_book,
                    label: "Bitácoras",
                    value: bitacoras,
                    iconColor: AppColors.textBlueNormal,
                  ),
                  _EstadisticaCard(
                    icon: Icons.emoji_events,
                    label: "Insignias",
                    value: insignias,
                    iconColor: AppColors.textBlueNormal,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            // Sección 3: Acciones
            Column(
              children: [
                _AccionPerfilTile(
                  icon: Icons.menu_book,
                  iconColor: AppColors.textBlueNormal,
                  label: "Mis Bitácoras",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MisBitacorasScreen(),
                      ),
                    );
                  },
                  trailing: Icons.arrow_forward_ios,
                ),
                _DividerPerfil(),
                _AccionPerfilTile(
                  icon: Icons.settings,
                  iconColor: AppColors.textBlueNormal,
                  label: "Editar Perfil",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditarPerfil(),
                      ),
                    );
                  },
                  trailing: Icons.arrow_forward_ios,
                ),
                _DividerPerfil(),
                _AccionPerfilTile(
                  icon: Icons.logout,
                  iconColor: AppColors.warning, // Cambiar color a warning
                  label: "Cerrar Sesión",
                  onTap: () => _cerrarSesion(context), // Llamar a la función
                  trailing: null,
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _EstadisticaCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color iconColor;

  const _EstadisticaCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          height: 120,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccionPerfilTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;

  const _AccionPerfilTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: const TextStyle(
          color: AppColors.textWhite,
          fontSize: 16,
        ),
      ),
      trailing: trailing != null
          ? Icon(trailing, color: AppColors.textWhite, size: 20)
          : null,
      onTap: onTap,
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: const Border(
        bottom: BorderSide(color: Colors.transparent),
      ),
    );
  }
}

class _DividerPerfil extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 1,
      color: AppColors.brownLight2,
    );
  }
}