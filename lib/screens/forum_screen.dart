import 'dart:io';

import 'package:biodetect/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// Modelo simple para el mensaje
class Message {
  final String id;
  final String userId;
  final String userName;
  final String content;
  final bool includeImage;
  final String? imageUrl; // Será nulo si includeImage es false
  final Timestamp createdAt;
  final bool esPropio; // Para determinar si el mensaje es del usuario actual

  Message({
    required this.id,
    required this.userId,
    required this.userName,
    required this.content,
    required this.includeImage,
    this.imageUrl,
    required this.createdAt,
    required this.esPropio,
  });

  factory Message.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['user_name'] ?? 'Usuario Desconocido',
      content: data['content'] ?? '',
      includeImage: data['includeImage'] ?? false,
      imageUrl: data['imageUrl'],
      createdAt: data['createdAt'] ?? Timestamp.now(), // Provee un valor por defecto si es nulo
      esPropio: data['userId'] == currentUserId,
    );
  }

  // Método para formatear la hora
  String get formattedTime {
    final dateTime = createdAt.toDate();
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  File? _image;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _currentUserId; // <--- Para obtener el ID del usuario actual
  String? _currentUserName; // <--- Para obtener el nombre del usuario actual

  //final String _currentUserId = "39zXVcVAUaVeG6qEqYu8qoXaoFE2";

  // --- Lógica para enviar mensajes ---
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _currentUserName = user.displayName ?? "Usuario Desconocido";
      });
    } else {
      print("Usuario no autenticado. El foro podría no funcionar completamente.");
      // Aqui probablemente redirija al login
    }
  }

  void _sendMessage() async {
    // Si no hay texto y no hay imagen, no envía nada
    if (_messageController.text.trim().isEmpty && _image == null) {
      return;
    }

    if (_currentUserId == null || _currentUserName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede enviar el mensaje. Usuario no identificado.')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      String? imageUrl; // Puede ser nulo si no hay imagen
      bool hasImage = false;
      if (_image != null) {
        final photoId = FirebaseFirestore.instance.collection('group_chat').doc().id;
        final ref = FirebaseStorage.instance.ref().child('group_chat/$_currentUserId/$photoId.jpg');
        await ref.putFile(_image!);
        imageUrl = await ref.getDownloadURL();
        hasImage = true;
      }

      await _firestore.collection('group_chat').add({
        'userId': _currentUserId,
        'user_name': _currentUserName,
        'content': _messageController.text.trim(),
        'includeImage': hasImage,
        'imageUrl': imageUrl, // Será null si hasImage es false
        'createdAt': Timestamp.now(),
      });
      _messageController.clear();
      setState(() {
        _image = null; // Limpia la imagen después de enviarla
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar mensaje: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }
  // --- Fin de lógica para enviar mensajes ---

  Future<void> _seleccionarGaleria() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  void _quitarImagenSeleccionada() {
    setState(() {
      _image = null;
    });
  }


  @override
  Widget build(BuildContext context) {
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
              child: StreamBuilder<QuerySnapshot>(
                // Escucha los cambios en la colección 'group_chat', ordenados por fecha
                stream: _firestore
                    .collection('group_chat')
                    .orderBy('createdAt', descending: true) // Los más nuevos primero
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error al cargar mensajes: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.textWhite),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.textWhite),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay mensajes aún. ¡Sé el primero!',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  // Mapea los documentos de Firestore a objetos Message
                  final List<Message> messages = snapshot.data!.docs
                      .map((doc) => Message.fromFirestore(doc, _currentUserId!))
                      .toList();

                  return ListView.builder(
                    reverse: true, // Para que el chat se muestre desde abajo y se desplace hacia arriba
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return ForoMensajeCard(
                        esPropio: message.esPropio,
                        usuario: message.userName,
                        hora: message.formattedTime, // Usa el getter formateado
                        texto: message.content,
                        imagen: message.includeImage ? message.imageUrl : null,
                      );
                    },
                  );
                },
              ),
            ),

            if (_image != null) // Muestra esta sección solo si hay una imagen seleccionada
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                color: AppColors.slateGreen.withOpacity(0.5), // Un color de fondo sutil
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.file(
                        _image!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Imagen seleccionada', // O el nombre del archivo si lo tienes
                        style: TextStyle(color: AppColors.textWhite.withOpacity(0.8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textWhite),
                      onPressed: _quitarImagenSeleccionada,
                      tooltip: 'Quitar imagen',
                    ),
                  ],
                ),
              ),

            // Campo de entrada
            Container(
              color: AppColors.slateGreen,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    color: AppColors.white,
                    tooltip: 'Adjuntar imagen',
                    onPressed: _isSending ? null : _seleccionarGaleria,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
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
                      onSubmitted: (_) => (_isSending || (_messageController.text.trim().isEmpty && _image == null)) ? null : _sendMessage(),
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                        : const Icon(Icons.send),
                    color: AppColors.white,
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
                  const CircleAvatar(
                    backgroundColor: AppColors.seaGreen,
                    radius: 16,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
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
                    child: Image.network( // Cambiado de Image.asset a Image.network
                      imagen!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // Mostrar un indicador de carga mientras la imagen se descarga
                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) return child; // Imagen cargada
                        return Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[300], // Un color de fondo mientras carga
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppColors.textWhite, // O el color que prefieras
                            ),
                          ),
                        );
                      },
                      // Mostrar un widget de error si la imagen no se puede cargar
                      errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                        return Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        );
                      },
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