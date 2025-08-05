import 'package:biodetect/themes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class RegDatos extends StatefulWidget {
  final String photoId;
  final String imageUrl;
  final String ordenTaxonomico;

  const RegDatos({
    super.key,
    required this.photoId,
    required this.imageUrl,
    required this.ordenTaxonomico,
  });

  @override
  State<RegDatos> createState() => _RegDatosState();
}

class _RegDatosState extends State<RegDatos> {
  final _formKey = GlobalKey<FormState>();
  String taxonOrder = '';
  String className = '';
  String habitat = '';
  String details = '';
  String notes = '';
  double lat = 0;
  double lon = 0;

  @override
  void initState() {
    super.initState();
    taxonOrder = widget.ordenTaxonomico;
    _loadPhotoData();
  }

  Future<void> _loadPhotoData() async {
    final doc = await FirebaseFirestore.instance.collection('insect_photos').doc(widget.photoId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        taxonOrder = data['taxonOrder'] ?? '';
        className = data['class'] ?? '';
        habitat = data['habitat'] ?? '';
        details = data['details'] ?? '';
        notes = data['notes'] ?? '';
        if (data['coords'] != null) {
          lat = data['coords']['x'] ?? 0;
          lon = data['coords']['y'] ?? 0;
        }
      });
    }
  }

  Future<void> _actualizarActividadUsuario() async {
    final doc = await FirebaseFirestore.instance.collection('insect_photos').doc(widget.photoId).get();
    final userId = doc.data()?['userId'];
    if (userId != null) {
      final activityRef = FirebaseFirestore.instance.collection('user_activity').doc(userId);
      await activityRef.set({
        'userId': userId,
        'photosUploaded': FieldValue.increment(1),
        'speciesIdentified.total': FieldValue.increment(1),
        'speciesIdentified.byTaxon.${taxonOrder}': FieldValue.increment(1),
        'lastActivity': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> _guardarDatos({bool publicar = false}) async {
    await FirebaseFirestore.instance.collection('insect_photos').doc(widget.photoId).update({
      'taxonOrder': taxonOrder,
      'class': className,
      'habitat': habitat,
      'details': details,
      'notes': notes,
      'coords': {'x': lat, 'y': lon},
      'isPublic': publicar,
    });
    if (publicar) {
      await _actualizarActividadUsuario();
      Navigator.pop(context);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(publicar ? 'Registro publicado' : 'Datos guardados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
            child: Column(
              children: [
                // Card principal
                Card(
                  color: AppColors.backgroundCard,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: AppColors.white, width: 2),
                  ),
                  elevation: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Header: Título y botón de cierre
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new),
                                color: AppColors.white,
                                onPressed: () => Navigator.pop(context),
                                iconSize: 28,
                              ),
                              const Expanded(
                                child: Text(
                                  'Datos del Registro',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Imagen relacionada al registro
                          Card(
                            color: AppColors.backgroundCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.white, width: 1),
                            ),
                            elevation: 4,
                            margin: EdgeInsets.zero,
                            child: SizedBox(
                              height: 180,
                              width: double.infinity,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  widget.imageUrl,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Formulario de datos
                          Column(
                            children: [
                              // Orden taxonómico SOLO LECTURA
                              TextFormField(
                                initialValue: taxonOrder,
                                enabled: false, // Solo lectura
                                decoration: InputDecoration(
                                  labelText: 'Orden taxonómico',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Clase
                              TextFormField(
                                initialValue: className,
                                onChanged: (v) => className = v,
                                decoration: InputDecoration(
                                  labelText: 'Clase',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Ubicación
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonBlue1,
                                        foregroundColor: AppColors.textWhite,
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      onPressed: () async {
                                        LocationPermission permission = await Geolocator.checkPermission();
                                        if (permission == LocationPermission.denied) {
                                          permission = await Geolocator.requestPermission();
                                          if (permission == LocationPermission.denied) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Permiso de ubicación denegado')),
                                            );
                                            return;
                                          }
                                        }
                                        if (permission == LocationPermission.deniedForever) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Permiso de ubicación denegado permanentemente')),
                                          );
                                          return;
                                        }
                                        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
                                        setState(() {
                                          lat = position.latitude;
                                          lon = position.longitude;
                                        });
                                      },
                                      child: const Text('Obtener ubicación'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Lat: $lat\nLon: $lon',
                                      style: const TextStyle(
                                        color: AppColors.textWhite,
                                        fontSize: 15,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Hábitat
                              DropdownButtonFormField<String>(
                                value: habitat.isNotEmpty ? habitat : null,
                                decoration: InputDecoration(
                                  labelText: 'Hábitat',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                dropdownColor: AppColors.paleGreen,
                                items: const [
                                  DropdownMenuItem(value: 'Bosque', child: Text('Bosque')),
                                  DropdownMenuItem(value: 'Selva', child: Text('Selva')),
                                  DropdownMenuItem(value: 'Desierto', child: Text('Desierto')),
                                  DropdownMenuItem(value: 'Urbano', child: Text('Urbano')),
                                ],
                                onChanged: (value) => setState(() => habitat = value ?? ''),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Detalles
                              TextFormField(
                                initialValue: details,
                                onChanged: (v) => details = v,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Detalles del hallazgo',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 16),
                              // Notas
                              TextFormField(
                                initialValue: notes,
                                onChanged: (v) => notes = v,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'Notas u observaciones',
                                  filled: true,
                                  fillColor: AppColors.paleGreen,
                                  labelStyle: const TextStyle(color: AppColors.textWhite),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: const TextStyle(color: AppColors.textWhite),
                              ),
                              const SizedBox(height: 24),
                              // Botones de acción
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonBlue2,
                                        foregroundColor: AppColors.textWhite,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      onPressed: () => _guardarDatos(),
                                      child: const Text(
                                        'Guardar',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.buttonGreen1,
                                        foregroundColor: AppColors.textWhite,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        minimumSize: const Size(0, 48),
                                      ),
                                      onPressed: () => _guardarDatos(publicar: true),
                                      child: const Text(
                                        'Publicar',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}