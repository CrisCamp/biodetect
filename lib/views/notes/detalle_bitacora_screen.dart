import 'package:biodetect/themes.dart';
import 'package:biodetect/services/bitacora_service.dart';
import 'package:biodetect/services/pdf_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetalleBitacoraScreen extends StatefulWidget {
  final Map<String, dynamic> bitacoraData;

  const DetalleBitacoraScreen({
    super.key,
    required this.bitacoraData,
  });

  @override
  State<DetalleBitacoraScreen> createState() => _DetalleBitacoraScreenState();
}

class _DetalleBitacoraScreenState extends State<DetalleBitacoraScreen> {
  List<Map<String, dynamic>> _registros = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  bool _isSharing = false;
  String _authorName = 'Usuario';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar registros
      final selectedPhotos = widget.bitacoraData['selectedPhotos'] as List<dynamic>? ?? [];
      final photoIds = selectedPhotos.cast<String>();
      
      // Obtener el nombre del autor desde los datos de la bitácora
      _authorName = widget.bitacoraData['authorName'] ?? 'Usuario desconocido';
      
      // Cargar registros
      if (photoIds.isNotEmpty) {
        final registros = await BitacoraService.getPhotosByIds(photoIds);
        setState(() {
          _registros = registros;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Sin fecha';
    
    try {
      final dt = date is DateTime ? date : date.toDate();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return 'Sin fecha';
    }
  }

  String _formatCoords(Map<String, dynamic> registro) {
    if (registro['coords'] == null) return 'Sin coordenadas';
    
    final lat = registro['coords']['x'];
    final lon = registro['coords']['y'];
    
    if (lat == null || lon == null || (lat == 0 && lon == 0)) {
      return 'Sin coordenadas';
    }
    
    return '${lat.toStringAsFixed(6)}°, ${lon.toStringAsFixed(6)}°';
  }

  Future<void> _generarPdf() async {
    if (_registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay registros para generar el PDF'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final titulo = widget.bitacoraData['title'] ?? 'Sin título';
      final fileName = 'Bitacora_${titulo.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      
      final pdfBytes = await PdfService.generateBitacoraPdf(
        bitacoraData: widget.bitacoraData,
        registros: _registros,
        authorName: _authorName,
      );

      // Vista previa del PDF
      await PdfService.previewPdf(pdfBytes, fileName);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _compartirBitacora() async {
    if (_registros.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay registros para compartir'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSharing = true);

    try {
      final titulo = widget.bitacoraData['title'] ?? 'Sin título';
      final fileName = 'Bitacora_${titulo.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';
      
      final pdfBytes = await PdfService.generateBitacoraPdf(
        bitacoraData: widget.bitacoraData,
        registros: _registros,
        authorName: _authorName,
      );

      await PdfService.sharePdf(pdfBytes, fileName);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al compartir PDF: $e'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titulo = widget.bitacoraData['title'] ?? 'Sin título';
    final descripcion = widget.bitacoraData['description'] ?? 'Sin descripción';
    final fechaCreacion = _formatDate(widget.bitacoraData['createdAt']);
    final isPublic = widget.bitacoraData['isPublic'] ?? false;

    return Scaffold(
      backgroundColor: AppColors.deepGreen,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: AppColors.buttonBlue1,
            foregroundColor: AppColors.textWhite,
            heroTag: "generate_pdf",
            onPressed: (_isGeneratingPdf || _isSharing) ? null : _generarPdf,
            child: _isGeneratingPdf 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: _isGeneratingPdf ? 'Generando...' : 'Generar PDF',
          ),
          const SizedBox(width: 16),
          FloatingActionButton(
            backgroundColor: AppColors.buttonGreen1,
            foregroundColor: AppColors.textWhite,
            heroTag: "share_pdf",
            onPressed: (_isGeneratingPdf || _isSharing) ? null : _compartirBitacora,
            child: _isSharing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.textWhite,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.share),
            tooltip: _isSharing ? 'Compartiendo...' : 'Compartir PDF',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: Stack(
          children: [
            // Contenido principal con padding superior para el header flotante
            Padding(
              padding: const EdgeInsets.only(top: 100), // Espacio para el header flotante
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información de la bitácora con logo
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Logo de la app centrado
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.buttonGreen2,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/ic_logo_biodetect.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.menu_book,
                                    size: 40,
                                    color: AppColors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Título
                          Text(
                            titulo,
                            style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Autor
                          Text(
                            'Por: $_authorName',
                            style: const TextStyle(
                              color: AppColors.buttonGreen2,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Descripción
                          Text(
                            descripcion,
                            style: const TextStyle(
                              color: AppColors.textPaleGreen,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          
                          // Información adicional
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, 
                                   color: AppColors.buttonGreen2, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Creado: $fechaCreacion',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library, 
                                   color: AppColors.buttonGreen2, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${_registros.length} registros incluidos',
                                style: const TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Título de registros
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Registros de Identificación',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    
                    // Lista de registros
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: AppColors.buttonGreen2,
                          ),
                        ),
                      )
                    else if (_registros.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                size: 64,
                                color: AppColors.textPaleGreen,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No hay registros en esta bitácora',
                                style: TextStyle(
                                  color: AppColors.textPaleGreen,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _registros
                            .map((registro) => RegistroDetalleBitacoraCard(registro: registro))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            // Header flotante
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 16,
                  right: 16,
                  bottom: 16,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      color: AppColors.textWhite,
                      onPressed: (_isGeneratingPdf || _isSharing) ? null : () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Detalle de bitácora',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPublic ? AppColors.buttonGreen2 : AppColors.warning,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isPublic ? Icons.public : Icons.lock,
                            size: 14,
                            color: AppColors.textBlack,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isPublic ? 'Pública' : 'Privada',
                            style: const TextStyle(
                              color: AppColors.textBlack,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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

class RegistroDetalleBitacoraCard extends StatelessWidget {
  final Map<String, dynamic> registro;

  const RegistroDetalleBitacoraCard({
    super.key,
    required this.registro,
  });

  String _formatDate(dynamic date) {
    if (date == null) return 'Sin fecha';
    
    try {
      final dt = date is DateTime ? date : date.toDate();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return 'Sin fecha';
    }
  }

  String _formatCoords() {
    if (registro['coords'] == null) return 'Sin coordenadas';
    
    final lat = registro['coords']['x'];
    final lon = registro['coords']['y'];
    
    if (lat == null || lon == null || (lat == 0 && lon == 0)) {
      return 'Sin coordenadas';
    }
    
    return '${lat.toStringAsFixed(6)}°, ${lon.toStringAsFixed(6)}°';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.brownLight2, width: 1),
      ),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: registro['imageUrl'] ?? '',
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 220,
                  color: AppColors.paleGreen.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.buttonGreen2,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: AppColors.paleGreen.withValues(alpha: 0.3),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: AppColors.warning, size: 50),
                      SizedBox(height: 8),
                      Text(
                        'Error al cargar imagen',
                        style: TextStyle(color: AppColors.textPaleGreen),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Información del registro
            _buildInfoRow('Orden:', registro['taxonOrder'] ?? 'No especificado'),
            _buildInfoRow('Clase:', registro['class'] ?? 'No especificada'),
            _buildInfoRow('Hábitat:', registro['habitat'] ?? 'No especificado'),
            _buildInfoRow('Verificado:', _formatDate(registro['verificationDate'])),
            _buildInfoRow('Coordenadas:', _formatCoords()),
            
            if ((registro['details'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Detalles:',
                style: TextStyle(
                  color: AppColors.buttonGreen2,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                registro['details'] ?? '',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                ),
              ),
            ],
            
            if ((registro['notes'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Observaciones:',
                style: TextStyle(
                  color: AppColors.buttonGreen2,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                registro['notes'] ?? '',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(
                color: AppColors.buttonGreen2,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}