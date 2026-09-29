import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/network/dio_client.dart';
import '../../../app/router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../../update/providers/update_provider.dart';
import '../../update/widgets/update_dialog.dart';

/// Channel ID tunggal yang digunakan di seluruh aplikasi.
/// Harus sama dengan nilai di AndroidManifest.xml dan main.dart.
const String kNotificationChannelId = 'high_importance_channel_v5';

class NotificationProvider extends ChangeNotifier {
  final DioClient _dioClient;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Callback opsional untuk navigasi saat notifikasi diklik.
  /// Di-set dari luar (misal: di main.dart setelah router dibuat).
  void Function(String route)? onNotificationTap;

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
        final data = response.data;
        if (data is Map) {
          final countVal = data['unread_count'] ?? (data['data'] != null && data['data'] is Map ? data['data']['unread_count'] : null);
          _unreadCount = int.tryParse(countVal.toString()) ?? 0;
        } else {
          _unreadCount = 0;
        }
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

  /// [DEPRECATED] Sudah dipindahkan ke AuthProvider._submitFcmToken().
  /// Tetap ada untuk backward compatibility jika dipanggil dari tempat lain.
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

  /// Fungsi Global untuk Navigasi (Routing) berdasarkan "type" notifikasi
  void _handleRouting(Map<String, dynamic> data) {
    String type = data['type']?.toString() ?? '';
    // String id = data['id']?.toString() ?? ''; // Uncomment if needed for routing
    
    // Ganti dengan logic Navigasi/Router Anda
    switch (type) {
      case 'PO_CREATED':
        // Contoh: Navigasi ke detail PO
        // onNotificationTap?.call('/po-detail/$id');
        onNotificationTap?.call('/notifications');
        break;
      case 'PAYMENT_RECEIVED':
        // Contoh: Navigasi ke detail pembayaran
        onNotificationTap?.call('/notifications');
        break;
              case 'APP_UPDATE':
          final currentContext = rootNavigatorKey.currentContext;
          if (currentContext != null) {
            // Trigger checkForUpdate() agar UpdateProvider update state-nya
            final updateProvider = Provider.of<UpdateProvider>(currentContext, listen: false);
            updateProvider.checkForUpdate().then((_) {
              if (updateProvider.hasUpdate && currentContext.mounted) {
                UpdateDialog.show(currentContext);
              }
            });
          }
          break;
      default:
        // Navigasi ke halaman beranda/notifikasi list
        onNotificationTap?.call('/notifications');
        break;
    }
  }

  /// Inisialisasi Firebase Messaging lengkap:
  /// - Minta izin notifikasi (Android 13+ / iOS)
  /// - Daftarkan channel Android dengan Importance.max (heads-up)
  /// - Pasang listener foreground (onMessage)
  /// - Pasang listener klik notifikasi (onMessageOpenedApp)
  /// - Tangani notifikasi yang membuka app dari terminated state
  Future<void> initFirebaseMessaging() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Minta izin notifikasi ke user
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // Inisialisasi flutter_local_notifications
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings();
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotificationsPlugin.initialize(
        settings: initSettings,
        // Navigasi saat user klik notifikasi lokal (foreground pop-up)
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Local notification tapped: ${response.payload}');
          if (response.payload != null) {
            try {
              final data = jsonDecode(response.payload!);
              if (data is Map<String, dynamic>) {
                _handleRouting(data);
              } else {
                _handleRouting({});
              }
            } catch (e) {
              _handleRouting({});
            }
          } else {
            _handleRouting({});
          }
        },
      );

      final androidImplementation = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      // Buat channel Android dengan Importance.max agar muncul sebagai heads-up
      const channel = AndroidNotificationChannel(
        kNotificationChannelId,          // ID konsisten di seluruh app
        'High Importance Notifications',
        description: 'Notifikasi penting dari Endog Racing.',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // === FOREGROUND HANDLER ===
      // Tampilkan pop-up saat aplikasi sedang aktif dibuka
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📬 Foreground message received: ${message.messageId}');

        String? title = message.notification?.title ?? message.data['title'] ?? 'Notifikasi Baru';
        String? body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? 'Anda memiliki pesan baru';

        int notificationId = message.hashCode.abs();
        if (notificationId > 2147483647) {
          notificationId = notificationId % 2147483647;
        }

        _localNotificationsPlugin.show(
          id: notificationId,
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              enableVibration: true,
              playSound: true,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: jsonEncode(message.data),
        );

        // Perbarui badge count dan list notifikasi
        fetchUnreadCount();
        fetchNotifications();
      });

      // === KLIK DARI BACKGROUND ===
      // Saat user klik notifikasi dari status bar dan app sudah terbuka di background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('🔔 Notification tapped from background: ${message.messageId}');
        _handleRouting(message.data);
      });

      // === KLIK DARI TERMINATED ===
      // Saat app dibuka pertama kali karena user klik notifikasi
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App opened from terminated via notification: ${initialMessage.messageId}');
        // Delay sedikit agar router sudah siap sebelum navigate
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleRouting(initialMessage.data);
        });
      }

      // Get dan kirim token FCM (sebagai backup, login sudah handle ini)
      final token = await messaging.getToken();
      if (token != null) {
        await submitFcmToken(token);
      }

      // Perbarui token jika Firebase refresh
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token diperbarui: $newToken');
        submitFcmToken(newToken);
      });

    } catch (e) {
      debugPrint('❌ Error initializing Firebase Messaging: $e');
    }
  }
}

