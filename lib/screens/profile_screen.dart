import 'package:biodetect/views/notes/mis_bitacoras.dart';
import 'package:biodetect/views/user/editar_perfil.dart';
import 'package:biodetect/views/session/inicio_sesion.dart';
import 'package:flutter/material.dart';
import 'package:biodetect/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadUserData();
  }

  Future<Map<String, dynamic>> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado');

    // Obtener datos del usuario
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    // Obtener estadísticas de actividad
    final activityDoc = await FirebaseFirestore.instance.collection('user_activity').doc(user.uid).get();
    final activityData = activityDoc.data() ?? {};

    // Obtener insignias (detalles)
    List<Map<String, dynamic>> badgesData = [];
    if (userData['badges'] != null && userData['badges'] is List) {
      final badgeIds = List<String>.from(userData['badges']);
      if (badgeIds.isNotEmpty) {
        final badgesSnap = await FirebaseFirestore.instance
            .collection('badges')
            .where(FieldPath.documentId, whereIn: badgeIds)
            .get();
        badgesData = badgesSnap.docs.map((doc) => doc.data()).toList();
      }
    }

    return {
      'user': userData,
      'activity': activityData,
      'badges': badgesData,
    };
  }

  Future<void> _cerrarSesion(BuildContext context) async {
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

    if (confirmar == true && context.mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(color: AppColors.mintGreen),
          ),
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('auto_login', false);
        await FirebaseAuth.instance.signOut();
        if (context.mounted) Navigator.of(context).pop();
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const InicioSesion()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) Navigator.of(context).pop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perfil de Usuario',
          style: TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.backgroundNavBarsLigth,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _userDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.mintGreen));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar perfil: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.warning),
                ),
              );
            }

            final user = snapshot.data!['user'] ?? {};
            final activity = snapshot.data!['activity'] ?? {};
            final badges = snapshot.data!['badges'] ?? [];

            final String nombre = user['fullname'] ?? 'Nombre no disponible';
            final String correo = user['email'] ?? 'Correo no disponible';
            final String? foto = user['profilePicture'];
            final bool verificado = FirebaseAuth.instance.currentUser?.emailVerified ?? false;
            final int identificaciones = activity['speciesIdentified']?['total'] ?? 0;
            final int bitacoras = activity['fieldNotesCreated'] ?? 0;
            final int insignias = (user['badges'] as List?)?.length ?? 0;

            return ListView(
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
                        backgroundImage: (foto != null && foto.isNotEmpty)
                            ? NetworkImage(foto)
                            : const AssetImage('assets/ic_default_profile.png') as ImageProvider,
                        child: foto == null || foto.isEmpty
                            ? const Icon(Icons.person, size: 72, color: AppColors.slateGrey)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nombre
                    Text(
                      nombre,
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
                          correo,
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
                // Sección 2.1: Insignias (opcional, muestra iconos)
                if (badges.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: badges.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final badge = badges[i];
                          return Tooltip(
                            message: badge['name'] ?? '',
                            child: CircleAvatar(
                              backgroundColor: AppColors.slateGreen,
                              radius: 28,
                              backgroundImage: badge['iconUrl'] != null
                                  ? NetworkImage(badge['iconUrl'])
                                  : null,
                              child: badge['iconUrl'] == null
                                  ? const Icon(Icons.emoji_events, color: AppColors.textWhite)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (badges.isNotEmpty) const SizedBox(height: 32),
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
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditarPerfil(),
                          ),
                        );
                        if (result == true) {
                          setState(() {
                            _userDataFuture = _loadUserData();
                          });
                        }
                      },
                      trailing: Icons.arrow_forward_ios,
                    ),
                    _DividerPerfil(),
                    _AccionPerfilTile(
                      icon: Icons.logout,
                      iconColor: AppColors.warning,
                      label: "Cerrar Sesión",
                      onTap: () => _cerrarSesion(context),
                      trailing: null,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            );
          },
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