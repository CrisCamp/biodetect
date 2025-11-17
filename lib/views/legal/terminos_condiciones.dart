import 'package:flutter/material.dart';
import 'package:biodetect/themes.dart';

class TerminosCondiciones extends StatelessWidget {
  const TerminosCondiciones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Términos y Condiciones',
          style: TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.slateGreen,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.backgroundPrimary,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              const Text(
                'BioDetect',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textWhite,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Términos y Condiciones de Uso',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textWhite.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Última actualización: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textWhite.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Contenido de términos
              _buildSection(
                '1. ACEPTACIÓN DE TÉRMINOS',
                'Al registrarte y usar la aplicación BioDetect, aceptas cumplir con estos términos y condiciones. Si no estás de acuerdo, no uses la aplicación.',
              ),

              _buildSection(
                '2. DESCRIPCIÓN DEL SERVICIO',
                'BioDetect es una aplicación móvil dedicada a la identificación y catalogación de biodiversidad mediante tecnología de inteligencia artificial. La app permite:\n\n• Identificar órdenes taxonómicas usando fotografías y algoritmos de IA\n• Crear bitácoras de campo con geolocalización\n• Participar en un foro para compartir conocimientos\n• Contribuir a la investigación científica y conservación',
              ),

              _buildSection(
                '3. USO RESPONSABLE',
                '• Proporciona información veraz y precisa en tus registros\n• Respeta a otros usuarios en el foro\n• No subas contenido ofensivo, ilegal o inapropiado\n• Usa la app únicamente para fines educativos, científicos y de conservación\n• No intentes dañar o comprometer la seguridad de la aplicación\n• Respeta las especies y sus hábitats al tomar fotografías\n• Verifica las identificaciones de IA con fuentes científicas confiables\n• No uses la app para actividades comerciales sin autorización',
              ),

              _buildSection(
                '4. PRIVACIDAD Y DATOS',
                'TIPOS DE DATOS QUE RECOPILAMOS:\n• Fotografías e imágenes que tomes o subas\n• Datos de ubicación GPS donde se registran especies\n• Información de cuenta (nombre, email, foto de perfil)\n• Datos de interacción y uso de la aplicación\n• Metadatos de imágenes (fecha y hora)\n\nUSO DE TUS DATOS:\n• Identificación automática mediante inteligencia artificial\n• Creación de mapas de biodiversidad\n• Mejora de algoritmos de reconocimiento\n\nTUS DERECHOS:\n• Acceder, rectificar o eliminar tus datos personales\n• Controlar la visibilidad de tus bitácoras (públicas/privadas)\n• Exportar tus datos en formato portable\n• Revocar permisos de ubicación en cualquier momento',
              ),

              _buildSection(
                '5. CONTENIDO DE USUARIO E IA',
                'DERECHOS DE CONTENIDO:\n• Mantienes los derechos de autor sobre las fotografías que subas\n• Al publicar contenido, nos otorgas licencia para procesarlo y mostrarlo\n• Podemos usar tus imágenes para entrenar y mejorar nuestros modelos de IA\n• Puedes configurar la privacidad de tus bitácoras (públicas o privadas)\n\nPROCESAMIENTO CON INTELIGENCIA ARTIFICIAL:\n• Usamos algoritmos de visión computacional para identificar órdenes taxonómicas\n• Los modelos analizan características morfológicas y patrones\n• Las predicciones incluyen nivel de confianza y especies alternativas\n\nLIMITACIONES DE LA IA:\n• Las identificaciones son sugerencias educativas, no diagnósticos definitivos\n• Recomendamos verificar resultados con expertos o literatura científica\n• La precisión puede variar según la calidad de imagen y especie\n• Siempre consulta fuentes científicas para decisiones importantes',
              ),

              _buildSection(
                '6. PERMISOS DE LA APLICACIÓN',
                'La app requiere los siguientes permisos para funcionar correctamente:\n\n• CÁMARA: Para tomar fotografías de especies\n• GALERÍA: Para seleccionar imágenes existentes\n• UBICACIÓN: Para georreferenciar tus registros y crear mapas\n• ALMACENAMIENTO: Para guardar imágenes y datos localmente\n• INTERNET: Para identificación con IA y sincronización de datos\n\nPuedes modificar estos permisos en la configuración de tu dispositivo, aunque esto puede limitar algunas funcionalidades de la aplicación.',
              ),

              _buildSection(
                '7. DISPONIBILIDAD DEL SERVICIO',
                'La aplicación se proporciona "tal como está". Podemos realizar mantenimientos, actualizaciones o interrupciones temporales del servicio para mejoras y correcciones.',
              ),

              _buildSection(
                '8. LIMITACIÓN DE RESPONSABILIDAD',
                'BioDetect es una herramienta educativa y de investigación:\n\n• Las identificaciones de IA son sugerencias, no garantías científicas\n• No nos responsabilizamos por decisiones basadas únicamente en nuestras identificaciones\n• El usuario debe verificar resultados con fuentes científicas confiables\n• No garantizamos disponibilidad continua del servicio\n• No somos responsables por pérdida de datos debido a fallas técnicas\n• La app no reemplaza el conocimiento de expertos en taxonomía',
              ),

              _buildSection(
                '9. INVESTIGACIÓN Y DATOS CIENTÍFICOS',
                '• Tus contribuciones pueden ser utilizadas para investigación científica\n• Contribuyes al conocimiento sobre biodiversidad y conservación\n• Puedes optar por no participar en investigación manteniendo tus datos privados\n• Los resultados de investigación pueden ser publicados en revistas científicas',
              ),

              _buildSection(
                '10. MODIFICACIONES',
                'Podemos actualizar estos términos ocasionalmente para reflejar cambios en la funcionalidad o regulaciones. Te notificaremos sobre cambios importantes a través de la aplicación.',
              ),

              _buildSection(
                '11. CONTACTO',
                'Si tienes preguntas sobre estos términos o la política de privacidad comunícate con nosotros al correo biodetect@hotmail.com. Tiempo de respuesta: 5-7 días hábiles',
              ),

              const SizedBox(height: 32),

              // Botón de aceptar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonGreen2,
                    foregroundColor: AppColors.textBlack,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true); // Retorna true indicando aceptación
                  },
                  child: const Text('Acepto los Términos y Condiciones'),
                ),
              ),

              const SizedBox(height: 16),

              // Botón de rechazar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textWhite,
                    side: const BorderSide(color: AppColors.textWhite),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, false); // Retorna false indicando rechazo
                  },
                  child: const Text('Cancelar'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.buttonGreen2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textWhite,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}