import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;
  StreamSubscription? _notificationsSubscription;
  final String? effectiveUserId;

  NotificationProvider({
    required NotificationRepository notificationRepository,
    required AuthProviderC authProvider,
  }) : _notificationRepository = notificationRepository,
       effectiveUserId = authProvider.currentUserId {
    print(
      "NotificationProvider: INSTANCE CREATED/UPDATED for user: $effectiveUserId",
    );
    _loadNotificationsForCurrentUser();
  }

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadCount;

  void _loadNotificationsForCurrentUser() {
    final userId = effectiveUserId;
    print(
      "NotificationProvider: _loadNotificationsForCurrentUser CALLED for effective userId: $userId",
    );
    _notificationsSubscription?.cancel(); // Siempre cancela la anterior
    _notifications = []; // Limpiar siempre al cargar/recargar para un usuario
    _unreadCount = 0;

    if (userId == null || userId.isEmpty) {
      print(
        "NotificationProvider: effectiveUserId is null or empty, clearing notifications and not subscribing.",
      );
      _isLoading = false; // Asegúrate de que isLoading se ponga a false
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print(
      "NotificationProvider: Subscribing to notifications for user $userId",
    );

    _notificationsSubscription = _notificationRepository
        .getUserNotifications(effectiveUserId!)
        .listen(
          (notifs) {
            print(
              "NotificationProvider: Notifications RECEIVED for user $userId. Count: ${notifs.length}",
            );
            _notifications = notifs;
            _unreadCount = notifs.where((n) => !n.isRead).length;
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = error.toString();
            _isLoading = false;
            _notifications = [];
            _unreadCount = 0;
            notifyListeners();
            print("NotificationProvider Error - _loadNotifications: $error");
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    if (effectiveUserId == null) return;
    try {
      await _notificationRepository.markNotificationAsRead(
        effectiveUserId!,
        notificationId,
      );
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index].isRead = true;
        _unreadCount = _notifications.where((n) => !n.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      print("NotificationProvider Error - _markAsRead: $e");
    }
  }

  Future<void> markAllAsRead() async {
    if (effectiveUserId == null || _unreadCount == 0) return;
    try {
      await _notificationRepository.markAllNotificationsAsRead(
        effectiveUserId!,
      );
      for (var notification in _notifications) {
        notification.isRead = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      print("NotificationProvider Error - _markAllAsRead: $e");
    }
  }


  @override
  void dispose() {
    print(
      "NotificationProvider: DISPOSE CALLED for user: $effectiveUserId. Cancelling subscription.",
    );
    _notificationsSubscription?.cancel();
    super.dispose();
    print("NotificationProvider: DISPOSE COMPLETED.");
  }
}
