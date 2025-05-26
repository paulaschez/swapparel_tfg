import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';
import '../../../../auth/presentation/provider/auth_provider.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _notificationRepository;
  final AuthProviderC _authProvider;
  StreamSubscription? _notificationsSubscription;

  NotificationProvider({
    required NotificationRepository notificationRepository,
    required AuthProviderC authProvider,
  }) : _notificationRepository = notificationRepository,
       _authProvider = authProvider {
    _authProvider.addListener(_onAuthStateChanged);
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

  void _onAuthStateChanged() {
    if (_authProvider.isAuthenticated && _authProvider.currentUserId != null) {
      _loadNotificationsForCurrentUser();
    } else {
      _clearNotifications();
    }
  }

  void _loadNotificationsForCurrentUser() {
    if (_authProvider.currentUserId == null ||
        _authProvider.currentUserId!.isEmpty) {
      _clearNotifications();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _notificationsSubscription?.cancel();
    _notificationsSubscription = _notificationRepository
        .getUserNotifications(_authProvider.currentUserId!)
        .listen(
          (notifs) {
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
    if (_authProvider.currentUserId == null) return;
    try {
      await _notificationRepository.markNotificationAsRead(
        _authProvider.currentUserId!,
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
    if (_authProvider.currentUserId == null || _unreadCount == 0) return;
    try {
      await _notificationRepository.markAllNotificationsAsRead(
        _authProvider.currentUserId!,
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

  void _clearNotifications() {
    _notificationsSubscription?.cancel();
    _notifications = [];
    _unreadCount = 0;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    _authProvider.removeListener(_onAuthStateChanged); 
    super.dispose();
  }
}
