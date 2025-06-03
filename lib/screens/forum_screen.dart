import 'package:flutter/material.dart';
import '../themes.dart';

class ForumScreen extends StatelessWidget {
  const ForumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Cuando conectes tu base de datos, reemplaza esta lista por la real.
    final List<Map<String, dynamic>> mensajes = []; // Lista vacía por defecto

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Foro de la Comunidad',
          style: TextStyle(color: AppColors.textWhite),
        ),
        backgroundColor: AppColors.backgroundNavBarsLigth,
        iconTheme: const IconThemeData(color: AppColors.textWhite),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundLightGradient,
        ),
        child: Column(
          children: [
            // Lista de mensajes
            Expanded(
              child: mensajes.isEmpty
                  ? const Center(
                child: Text(
                  'No hay mensajes aún.',
                  style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 16,
                  ),
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: mensajes.length,
                itemBuilder: (context, index) {
                  final mensaje = mensajes[index];
                  return ForoMensajeCard(
                    esPropio: mensaje['esPropio'] ?? false,
                    usuario: mensaje['user'] ?? '',
                    hora: mensaje['hora'] ?? '',
                    texto: mensaje['texto'] ?? '',
                    imagen: mensaje['imagen'],
                  );
                },
              ),
            ),
            // Campo de entrada
            Container(
              color: AppColors.slateGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    color: AppColors.white,
                    onPressed: () {
                      // Acción para adjuntar imagen
                    },
                  ),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        hintStyle: const TextStyle(color: AppColors.white),
                        filled: true,
                        fillColor: Colors.transparent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: AppColors.white,
                    onPressed: () {
                      // Acción para enviar mensaje
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ForoMensajeCard extends StatelessWidget {
  final bool esPropio;
  final String usuario;
  final String hora;
  final String texto;
  final String? imagen;

  const ForoMensajeCard({
    super.key,
    required this.esPropio,
    required this.usuario,
    required this.hora,
    required this.texto,
    this.imagen,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: esPropio ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: esPropio ? AppColors.mintGreen : AppColors.slateGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Usuario y hora
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.seaGreen,
                    radius: 16,
                    child: const Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      esPropio ? 'Tú' : usuario,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Text(
                    hora,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (texto.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    texto,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              if (imagen != null && imagen!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagen!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
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