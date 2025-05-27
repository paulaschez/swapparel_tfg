import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;          // ID del documento del mensaje en Firestore
  final String chatId;      // ID del chat/match al que pertenece este mensaje
  final String senderId;    // UID del usuario que envió el mensaje
  final String text;        // Contenido del mensaje
  final Timestamp timestamp;   // Cuándo se envió el mensaje
  final bool isRead;
 /*  final String senderUsername; // Nombre de usuario del remitente (desnormalizado para UI)
  final String? senderPhotoUrl; // Foto del remitente (desnormalizado) */

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    /* required this.senderUsername,
    this.senderPhotoUrl, */
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for MessageModel id: ${doc.id}');
    }
    return MessageModel(
      id: doc.id,
      chatId: data['chatId'] ?? '', 
      senderId: data['senderId'] ?? '',
      /* senderUsername: data['senderUsername'] ?? 'Desconocido',
      senderPhotoUrl: data['senderPhotoUrl'], */
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'text': text,
      /*  'senderUsername': senderUsername,
      'senderPhotoUrl': senderPhotoUrl, */
      'timestamp': timestamp, 
      'isRead': isRead,
    };
  }
}