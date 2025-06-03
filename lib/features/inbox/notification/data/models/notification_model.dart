import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  like,
  match,
  newOffer,
  general,
  offerAccepted,
  offerDeclined,
  newRating,
}

class NotificationModel {
  final String id; // ID del documento de notificación
  final String
  recipientId; // A quién va dirigida la notificación (el dueño de la subcolección)
  final NotificationType type;
  final String?
  relatedUserId; // ID del usuario que originó la notificación (ej: quien dio like, o el otro en un match)
  final String? relatedUserName; // Nombre del usuario que originó
  final String? relatedUserPhotoUrl; // Foto del usuario que originó
  final String?
  relatedGarmentId; // ID de la prenda relacionada (ej: la prenda que recibió like, o una de las prendas del match)
  final String? relatedGarmentName; // Nombre de la prenda
  final String? relatedGarmentImageUrl; // Imagen de la prenda
  final String? entityId; // ID de la entidad principal (ej: matchId, garmentId)
  final Timestamp createdAt;
  final String? message; // Para un mensaje más personalizado
  bool isRead;

  String get displayTitle {
    switch (type) {
      case NotificationType.like:
        return "¡Nuevo Me Gusta!";
      case NotificationType.match:
        return "¡Es un Match!";
      case NotificationType.newOffer:
        return "Nueva Oferta de Intercambio";
      case NotificationType.offerAccepted:
        return "¡Hay Swap!";
      case NotificationType.offerDeclined:
        return "No ha podido ser...";
      case NotificationType.newRating:
        return "¡Nueva Valoración!";
      default:
        return "Nueva notificación";
    }
  }

  String get displayMessage {
    switch (type) {
      case NotificationType.like:
        return "A ${relatedUserName ?? 'alguien'} le gusta tu prenda '${relatedGarmentName ?? 'una de tus prendas'}'.";
      case NotificationType.match:
        return "¡Has hecho match con ${relatedUserName ?? 'alguien'}! Ahora podéis chatear.";
      case NotificationType.newOffer:
        return "${relatedUserName ?? 'Alguien'} te ha enviado una oferta.";
      case NotificationType.offerAccepted:
        return "¡${relatedUserName ?? 'Alguien'} ha aceptado tu oferta!";
      case NotificationType.offerDeclined:
        return "${relatedUserName ?? 'Alguien'} ha rechazado tu oferta.";
      case NotificationType.newRating:
        return message!;
      default:
        return "";
    }
  }

  NotificationModel({
    required this.id,
    required this.recipientId,
    required this.type,
    this.relatedUserId,
    this.relatedUserName,
    this.relatedUserPhotoUrl,
    this.relatedGarmentId,
    this.relatedGarmentName,
    this.relatedGarmentImageUrl,
    this.entityId,
    required this.createdAt,
    this.isRead = false,
    this.message,
  });

  factory NotificationModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.general,
      ),
      relatedUserId: data['relatedUserId'],
      relatedUserName: data['relatedUserName'],
      relatedUserPhotoUrl: data['relatedUserPhotoUrl'],
      relatedGarmentId: data['relatedGarmentId'],
      relatedGarmentName: data['relatedGarmentName'],
      relatedGarmentImageUrl: data['relatedGarmentImageUrl'],
      entityId: data['entityId'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
      message: data['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'type': type.toString(),
      'relatedUserId': relatedUserId,
      'relatedUserName': relatedUserName,
      'relatedUserPhotoUrl': relatedUserPhotoUrl,
      'relatedGarmentId': relatedGarmentId,
      'relatedGarmentName': relatedGarmentName,
      'relatedGarmentImageUrl': relatedGarmentImageUrl,
      'entityId': entityId,
      'createdAt': createdAt,
      'isRead': isRead,
      'message': message,
    };
  }
}
