import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../app/config/constants/firestore_collections.dart';
import '../models/notification_model.dart';

abstract class NotificationRepository {
  Future<void> createNotification(NotificationModel notification);
  Stream<List<NotificationModel>> getUserNotifications(String userId, {int limit = 20});
  Future<void> markNotificationAsRead(String userId, String notificationId);
  Future<void> markAllNotificationsAsRead(String userId);
}

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepositoryImpl({required FirebaseFirestore firestore}) : _firestore = firestore;

  @override
  Future<void> createNotification(NotificationModel notification) async {
    try {
      // Las notificaciones se guardan en una subcolección del usuario receptor
      await _firestore
          .collection(usersCollection)
          .doc(notification.recipientId)
          .collection(notificationsCollection) 
          .add(notification.toJson()); 
      print("NotificationRepo: Notificación creada para ${notification.recipientId}");
    } catch (e) {
      print("NotificationRepo Error - createNotification: $e");
      throw Exception("Failed to create notification.");
    }
  }

  @override
  Stream<List<NotificationModel>> getUserNotifications(String userId, {int limit = 20}) {
    try {
      return _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(notificationsCollection)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots() // Escuchar cambios en tiempo real
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
              .toList());
    } catch (e) {
      print("NotificationRepo Error - getUserNotifications: $e");
      return Stream.value([]); // Devuelve stream vacío en caso de error
    }
  }

  @override
  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print("NotificationRepo Error - markNotificationAsRead: $e");
      throw Exception("Failed to mark notification as read.");
    }
  }

   @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      final WriteBatch batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(notificationsCollection)
          .where('isRead', isEqualTo: false) // Solo las no leídas
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print("NotificationRepo Error - markAllNotificationsAsRead: $e");
      throw Exception("Failed to mark all notifications as read.");
    }
  }

}