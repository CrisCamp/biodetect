import 'package:biodetect/themes.dart';
import 'package:biodetect/services/bitacora_service.dart';
import 'package:biodetect/views/notes/seleccionar_registros_screen.dart';
import 'package:flutter/material.dart';

class CrearEditarBitacoraScreen extends StatefulWidget {
  final String? bitacoraId; // null = crear nueva, no-null = editar
  final Map<String, dynamic>? bitacoraData; // datos existentes para editar

  const CrearEditarBitacoraScreen({
    super.key,
    this.bitacoraId,
    this.bitacoraData,
  });

  @override
  State<CrearEditarBitacoraScreen> createState() => _CrearEditarBitacoraScreenState();
}

class _CrearEditarBitacoraScreenState extends State<CrearEditarBitacoraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  List<String> _selectedPhotoIds = [];
  List<Map<String, dynamic>> _selectedPhotos = [];
  bool _isPublic = false;
  bool _isLoading = false;
  bool _isSaving = false;

  bool get _isEditing => widget.bitacoraId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing && widget.bitacoraData != null) {
      _loadExistingData();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadExistingData() {
    final data = widget.bitacoraData!;
    _titleController.text = data['title'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _isPublic = data['isPublic'] ?? false;
    _selectedPhotoIds = List<String>.from(data['selectedPhotos'] ?? []);
    
    // Cargar fotos seleccionadas
    _loadSelectedPhotos();
  }

  Future<void> _loadSelectedPhotos() async {
    if (_selectedPhotoIds.isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final photos = await BitacoraService.getPhotosByIds(_selectedPhotoIds);
      setState(() {
        _selectedPhotos = photos;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar fotos: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToSelectPhotos() async {
    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (context) => SeleccionarRegistrosScreen(
          selectedPhotoIds: _selectedPhotoIds,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPhotos = result;
        _selectedPhotoIds = result.map((photo) => photo['photoId'] as String).toList();
      });
    }
  }

  Future<void> _guardarBitacora() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPhotoIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un registro'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await BitacoraService.updateBitacora(
          bitacoraId: widget.bitacoraId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          selectedPhotoIds: _selectedPhotoIds,
          isPublic: _isPublic,
        );
      } else {
        await BitacoraService.createBitacora(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          selectedPhotoIds: _selectedPhotoIds,
          isPublic: _isPublic,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Bitácora actualizada' : 'Bitácora creada exitosamente'),
            backgroundColor: AppColors.buttonGreen2,
          ),
        );
        Navigator.of(context).pop(true); // Indica que se guardó correctamente
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
      _selectedPhotoIds.removeAt(index);
    });
  }

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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: _isSaving ? null : () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Editar Bitácora' : 'Nueva Bitácora',
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: _isSaving 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: AppColors.textWhite,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save),
                      color: AppColors.textWhite,
                      onPressed: _isSaving ? null : _guardarBitacora,
                    ),
                  ],
                ),
              ),
              // Formulario
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título de la Bitácora
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isSaving,
                          decoration: InputDecoration(
                            labelText: 'Título de la bitácora',
                            labelStyle: const TextStyle(color: AppColors.textPaleGreen),
                            filled: true,
                            fillColor: AppColors.textWhite,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.brownDark3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.brownDark3, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.warning),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.warning, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: const TextStyle(fontSize: 18, color: AppColors.textBlack),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El título es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Descripción
                        TextFormField(
                          controller: _descriptionController,
                          enabled: !_isSaving,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            labelStyle: const TextStyle(color: AppColors.textPaleGreen),
                            filled: true,
                            fillColor: AppColors.textWhite,
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.brownDark3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.brownDark3, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.warning),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: AppColors.warning, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          style: const TextStyle(color: AppColors.textBlack),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La descripción es obligatoria';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        // Switch para hacer pública
                        Row(
                          children: [
                            Switch(
                              value: _isPublic,
                              onChanged: _isSaving ? null : (value) {
                                setState(() {
                                  _isPublic = value;
                                });
                              },
                              activeColor: AppColors.buttonGreen2,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Hacer pública la bitácora',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Título de registros
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Registros seleccionados (${_selectedPhotos.length}):',
                              style: const TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.add_photo_alternate, color: AppColors.buttonBlue2),
                              label: const Text(
                                'Seleccionar',
                                style: TextStyle(color: AppColors.buttonBlue2),
                              ),
                              onPressed: _isSaving ? null : _navigateToSelectPhotos,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Lista de registros seleccionados
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.buttonGreen2,
                                ),
                              )
                            : _selectedPhotos.isEmpty
                                ? Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppColors.textWhite.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.textPaleGreen.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'No hay registros seleccionados.\nToca "Seleccionar" para añadir registros.',
                                      style: TextStyle(color: AppColors.textPaleGreen),
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : Container(
                                    constraints: const BoxConstraints(maxHeight: 300),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _selectedPhotos.length,
                                      itemBuilder: (context, index) {
                                        final photo = _selectedPhotos[index];
                                        return Card(
                                          color: AppColors.backgroundCard,
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            leading: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                photo['imageUrl'] ?? '',
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    width: 50,
                                                    height: 50,
                                                    color: AppColors.paleGreen.withValues(alpha: 0.3),
                                                    child: const Icon(
                                                      Icons.image_not_supported,
                                                      color: AppColors.textPaleGreen,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            title: Text(
                                              photo['taxonOrder'] ?? 'Sin clasificar',
                                              style: const TextStyle(
                                                color: AppColors.textWhite,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Text(
                                              'Hábitat: ${photo['habitat'] ?? 'No especificado'}',
                                              style: const TextStyle(
                                                color: AppColors.textPaleGreen,
                                              ),
                                            ),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.remove_circle, color: AppColors.warning),
                                              onPressed: _isSaving ? null : () => _removePhoto(index),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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
    );
  }
}