import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/network/dio_client.dart';

class NotificationProvider extends ChangeNotifier {
  final DioClient _dioClient;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationProvider(this._dioClient);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  List<dynamic> _notifications = [];
  List<dynamic> get notifications => _notifications;

  String? _error;
  String? get error => _error;

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _dioClient.dio.get('/notifications/unread-count');
      if (response.statusCode == 200) {
        _unreadCount = response.data['unread_count'] ?? 0;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch unread count: $e');
    }
  }

  Future<void> fetchNotifications({int page = 1}) async {
    if (page == 1) {
      _isLoading = true;
      notifyListeners();
    }
    try {
      final response = await _dioClient.dio.get(
        '/notifications',
        queryParameters: {'page': page},
      );
      if (response.statusCode == 200) {
        final responseData = response.data;
        List<dynamic> newNotifications = [];

        if (responseData is List) {
          newNotifications = responseData;
        } else if (responseData is Map && responseData.containsKey('data')) {
          newNotifications = responseData['data'] ?? [];
        }

        if (page == 1) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }
        _error = null;
      }
    } catch (e) {
      if (e is DioException && e.response != null) {
        _error = 'Error ${e.response?.statusCode}: ${e.response?.data}';
      } else {
        _error = e.toString();
      }
      debugPrint('Failed to fetch notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> markAsRead(String id) async {
    try {
      final response = await _dioClient.dio.post('/notifications/$id/read');
      if (response.statusCode == 200) {
        // Update local state
        final index = _notifications.indexWhere((n) => n['id'] == id);
        if (index != -1) {
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
          _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final response = await _dioClient.dio.post('/notifications/read-all');
      if (response.statusCode == 200) {
        for (var n in _notifications) {
          if (n['read_at'] == null) {
            n['read_at'] = DateTime.now().toIso8601String();
          }
        }
        _unreadCount = 0;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Failed to mark all as read: $e');
      return false;
    }
  }

  Future<void> submitFcmToken(String token) async {
    try {
      final response = await _dioClient.dio.post(
        '/fcm-token',
        data: {'fcm_token': token},
      );
      if (response.statusCode == 200) {
        debugPrint('FCM Token successfully submitted');
      }
    } catch (e) {
      debugPrint('Failed to submit FCM token: $e');
    }
  }

  Future<void> initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Initialize Local Notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotificationsPlugin.initialize(settings: initSettings);

      // Create High Importance Channel for Android Heads-Up Notifications
      const channel = AndroidNotificationChannel(
        'high_importance_channel_v2',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification}',
          );

          int notificationId = message.hashCode.abs();
          if (notificationId > 2147483647) {
            notificationId = notificationId % 2147483647;
          }

          _localNotificationsPlugin.show(
            id: notificationId,
            title: message.notification!.title,
            body: message.notification!.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );

          // Refresh unread count and notifications if user is currently looking at it
          fetchUnreadCount();
          fetchNotifications();
        }
      });

      // Handle message open (background/terminated)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // Here you can navigate to the notification screen
        debugPrint('Notification clicked!');
      });

      // Get token
      final token = await messaging.getToken();
      if (token != null) {
        await submitFcmToken(token);
      }

      // Listen for token refresh
      messaging.onTokenRefresh.listen((newToken) {
        submitFcmToken(newToken);
      });
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }
}
