import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PdfService {
  static Future<Uint8List> generateBitacoraPdf({
    required Map<String, dynamic> bitacoraData,
    required List<Map<String, dynamic>> registros,
    required String authorName,
  }) async {
    final pdf = pw.Document();

    // Cargar logo desde assets
    final Uint8List logoBytes = await rootBundle.load('assets/ic_logo_biodetect.png').then((data) => data.buffer.asUint8List());
    final pw.ImageProvider logoImage = pw.MemoryImage(logoBytes);

    // Cargar fuente para textos
    final fontData = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final titulo = bitacoraData['title'] ?? 'Sin título';
    final descripcion = bitacoraData['description'] ?? 'Sin descripción';
    final fechaCreacion = _formatDate(bitacoraData['createdAt']);

    // Página de portada
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              // Logo centrado
              pw.Container(
                width: 120,
                height: 120,
                child: pw.Image(logoImage),
              ),
              pw.SizedBox(height: 40),
              
              // Título de la bitácora
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 28,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 20),
              
              // Información del autor
              pw.Text(
                'Por: $authorName',
                style: pw.TextStyle(
                  font: fontData,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 12),
              
              // Fecha de creación
              pw.Text(
                'Creado: $fechaCreacion',
                style: pw.TextStyle(
                  font: fontData,
                  fontSize: 14,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              
              // Número de registros
              pw.Text(
                '${registros.length} registros incluidos',
                style: pw.TextStyle(
                  font: fontData,
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 40),
              
              // Descripción
              if (descripcion.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Descripción:',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        descripcion,
                        style: pw.TextStyle(
                          font: fontData,
                          fontSize: 14,
                          color: PdfColors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );

    // Páginas de registros
    for (int i = 0; i < registros.length; i++) {
      final registro = registros[i];
      
      // Cargar imagen del registro
      pw.ImageProvider? registroImage;
      try {
        final imageUrl = registro['imageUrl'] ?? '';
        if (imageUrl.isNotEmpty) {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            registroImage = pw.MemoryImage(response.bodyBytes);
          }
        }
      } catch (e) {
        print('Error cargando imagen: $e');
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header con título del registro
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Registro ${i + 1} de ${registros.length}',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 18,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        _formatDate(registro['verificationDate']),
                        style: pw.TextStyle(
                          font: fontData,
                          fontSize: 12,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
                
                // Imagen del registro
                if (registroImage != null) ...[
                  pw.Container(
                    width: double.infinity,
                    height: 250,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(
                        registroImage,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ] else ...[
                  pw.Container(
                    width: double.infinity,
                    height: 250,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Imagen no disponible',
                        style: pw.TextStyle(
                          font: fontData,
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
                
                // Información taxonómica
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Información Taxonómica',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 16,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      _buildInfoRow('Orden:', registro['taxonOrder'] ?? 'No especificado', fontData, fontBold),
                      _buildInfoRow('Clase:', registro['class'] ?? 'No especificada', fontData, fontBold),
                      _buildInfoRow('Hábitat:', registro['habitat'] ?? 'No especificado', fontData, fontBold),
                      _buildInfoRow('Coordenadas:', _formatCoords(registro), fontData, fontBold),
                    ],
                  ),
                ),
                
                // Detalles y observaciones
                if ((registro['details'] ?? '').toString().isNotEmpty || 
                    (registro['notes'] ?? '').toString().isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if ((registro['details'] ?? '').toString().isNotEmpty) ...[
                          pw.Text(
                            'Detalles:',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            registro['details'] ?? '',
                            style: pw.TextStyle(
                              font: fontData,
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                          if ((registro['notes'] ?? '').toString().isNotEmpty) 
                            pw.SizedBox(height: 12),
                        ],
                        if ((registro['notes'] ?? '').toString().isNotEmpty) ...[
                          pw.Text(
                            'Observaciones:',
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 14,
                              color: PdfColors.black,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            registro['notes'] ?? '',
                            style: pw.TextStyle(
                              font: fontData,
                              fontSize: 12,
                              color: PdfColors.black,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                
                // Footer con número de página
                pw.Spacer(),
                pw.Divider(color: PdfColors.grey400),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      titulo,
                      style: pw.TextStyle(
                        font: fontData,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Página ${i + 2}', // +2 porque la portada es página 1
                      style: pw.TextStyle(
                        font: fontData,
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font fontData, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 100,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: fontData,
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return 'Sin fecha';
    
    try {
      final dt = date is DateTime ? date : date.toDate();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return 'Sin fecha';
    }
  }

  static String _formatCoords(Map<String, dynamic> registro) {
    if (registro['coords'] == null) return 'Sin coordenadas';
    
    final lat = registro['coords']['x'];
    final lon = registro['coords']['y'];
    
    if (lat == null || lon == null || (lat == 0 && lon == 0)) {
      return 'Sin coordenadas';
    }
    
    return '${lat.toStringAsFixed(6)}°, ${lon.toStringAsFixed(6)}°';
  }

  static Future<void> previewPdf(Uint8List pdfBytes, String fileName) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: fileName,
    );
  }

  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Bitácora de campo generada con BioDetect',
        subject: fileName,
      );
    } catch (e) {
      throw Exception('Error al compartir PDF: $e');
    }
  }

  static Future<File> savePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File('${output.path}/$fileName.pdf');
      await file.writeAsBytes(pdfBytes);
      return file;
    } catch (e) {
      throw Exception('Error al guardar PDF: $e');
    }
  }
}