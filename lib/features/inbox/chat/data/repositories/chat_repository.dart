import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../../../../../app/config/constants/firestore_collections.dart';

abstract class ChatRepository {
  // Obtiene un stream de mensajes para un chat específico, ordenados por tiempo.
  Stream<List<MessageModel>> getChatMessages({
    required String chatId,
    int limit = 20, // Número de mensajes a cargar inicialmente o por página
  });

  // Envía un nuevo mensaje a un chat.
  Future<void> sendMessage({
    required String chatId, // ID del Match/Conversación
    required String senderId,
    required String text,
  });

  // Actualiza la actividad reciente y el último mensaje del chat/match.
  Future<void> updateChatLastActivity({
    required String chatId,
    required String lastMessageSnippet,
    required Timestamp lastActivityTimestamp,
    String? lastMessageSenderId,
  });

  Future<void> markMessagesAsRead(String chatId, String userId);
}

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  @override
  Stream<List<MessageModel>> getChatMessages({
    required String chatId,
    int limit = 20,

  }) {
    if (chatId.isEmpty) {
      return Stream.value([]); // Devuelve stream vacío si no hay chatId
    }
    try {
      Query query = _firestore
          .collection(matchesCollection)
          .doc(chatId)
          .collection(messagesCollection)
          .orderBy(
            'timestamp',
            descending: true,
          ) // Más recientes primero para la query inicial
          .limit(limit);

      return query.snapshots().map((snapshot) {
        final messages =
            snapshot.docs
                .map(
                  (doc) => MessageModel.fromFirestore(
                    doc as DocumentSnapshot<Map<String, dynamic>>,
                  ),
                )
                .toList();
        return messages.reversed.toList();
      });
    } catch (e) {
      print("ChatRepo Error - getChatMessages: $e");
      return Stream.error(Exception("Failed to get chat messages."));
    }
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,

    required String text,
  }) async {
    if (chatId.isEmpty || senderId.isEmpty || text.trim().isEmpty) {
      print(
        "ChatRepo Warning: sendMessage called with empty chatId, senderId, or text.",
      );
      return; // No enviar mensaje vacío o sin remitente/chat
    }
    try {
      final timestamp =
          Timestamp.now(); // Usar el mismo timestamp para el mensaje y lastActivity

      final messageData = MessageModel(
        id: '', // Firestore generará el ID para el documento del mensaje
        chatId: chatId,
        senderId: senderId,

        text: text.trim(),
        timestamp: timestamp,
      );

      // Añadir el nuevo mensaje a la subcolección 'messages'
      await _firestore
          .collection(matchesCollection)
          .doc(chatId)
          .collection('messages')
          .add(messageData.toJson());

      // Después de enviar el mensaje, actualizar la actividad del chat principal
      await updateChatLastActivity(
        chatId: chatId,
        lastMessageSnippet: text.trim(),
        lastActivityTimestamp: timestamp,
        lastMessageSenderId: senderId,
      );
      print("ChatRepo: Message sent to chat $chatId");
    } catch (e) {
      print("ChatRepo Error - sendMessage: $e");
      throw Exception("Failed to send message.");
    }
  }

  @override
  Future<void> updateChatLastActivity({
    required String chatId,
    required String lastMessageSnippet,
    required Timestamp lastActivityTimestamp,
    String? lastMessageSenderId,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'lastActivityAt': lastActivityTimestamp,
        'lastMessageSnippet':
            lastMessageSnippet.length >
                    50 // Truncar si es muy largo
                ? '${lastMessageSnippet.substring(0, 47)}...'
                : lastMessageSnippet,
      };

      if (lastMessageSenderId != null) {
        // Obtener ids de los participantes del match
        DocumentSnapshot matchDoc =
            await _firestore.collection(matchesCollection).doc(chatId).get();
        if (matchDoc.exists) {
          List<String> participantIds = List<String>.from(
            (matchDoc.data() as Map<String, dynamic>)['participantIds'] ?? [],
          );

          // Determinar el ID del receptor
          String? recipientId;
          if (participantIds.length == 2) {
            recipientId = participantIds.firstWhere(
              (id) => id != lastMessageSenderId,
              orElse: () => '',
            );
          }

          if (recipientId != null && recipientId.isNotEmpty) {
            // 3. Incrementar el contador para el receptor
            updateData['unreadCounts.$recipientId'] = FieldValue.increment(1);
            print(
              "ChatRepo: Incrementando unread count para $recipientId en chat $chatId",
            );
          }
        }
      }

      await _firestore
          .collection(matchesCollection)
          .doc(chatId)
          .update(updateData);
      print("ChatRepo: Chat $chatId last activity updated.");
    } catch (e) {
      print("ChatRepo Error - updateChatLastActivity: $e");
    }
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    try {
      await _firestore.collection(matchesCollection).doc(chatId).update({
        'unreadCounts.$currentUserId': 0,
      });
      print("ChatRepo: Chat $chatId marked as read for user $currentUserId");
    } catch (e) {
      print("ChatRepo Error - markChatAsRead: $e");
    }
  }
}
