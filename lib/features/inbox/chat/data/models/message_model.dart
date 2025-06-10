import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;          // ID del documento del mensaje en Firestore
  final String senderId;    // UID del usuario que envió el mensaje
  final String text;        // Contenido del mensaje
  final Timestamp timestamp;   // Cuándo se envió el mensaje

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for MessageModel id: ${doc.id}');
    }
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'text': text,
      'timestamp': timestamp, 
    };
  }
}