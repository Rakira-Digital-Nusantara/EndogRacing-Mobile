import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'core/network/dio_client.dart';
import 'core/utils/version_checker.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/update/providers/update_provider.dart';
import 'features/home/providers/dashboard_provider.dart';
import 'features/sales/providers/sales_provider.dart';
import 'features/customers/providers/customer_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'features/kandang/data/repositories/kandang_repository.dart';
import 'features/absensi/data/repositories/absensi_repository.dart';
import 'features/absensi/providers/absensi_provider.dart';

/// Handler background: dijalankan saat app tertutup dan ada notifikasi masuk.
/// Wajib top-level function (bukan method di dalam class).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("📬 Background message received: ${message.messageId}");

  String? title = message.notification?.title ?? message.data['title'] ?? 'Notifikasi Baru';
  String? body = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? 'Anda memiliki pesan baru';

  int notificationId = message.hashCode.abs();
  if (notificationId > 2147483647) notificationId = notificationId % 2147483647;

  final FlutterLocalNotificationsPlugin localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
  await localNotificationsPlugin.initialize(settings: initSettings);

  // Gunakan channel ID yang sama (kNotificationChannelId = 'high_importance_channel')
  const channel = AndroidNotificationChannel(
    kNotificationChannelId,   // konsisten dengan notification_provider.dart & AndroidManifest
    'High Importance Notifications',
    description: 'Notifikasi penting dari Endog Racing.',
    importance: Importance.max,
  );

  await localNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  localNotificationsPlugin.show(
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
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  await dotenv.load(fileName: '.env');

  await Firebase.initializeApp();

  // Daftarkan handler background terlebih dahulu
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final dioClient = DioClient();

  final authRepository = AuthRepository(dioClient);
  final kandangRepository = KandangRepository(dioClient);
  final absensiRepository = AbsensiRepository(dioClient);
  final versionChecker = VersionChecker(dioClient);

  final authProvider = AuthProvider(authRepository);
  final updateProvider = UpdateProvider(versionChecker);
  final absensiProvider = AbsensiProvider(absensiRepository);
  final dashboardProvider = DashboardProvider(dioClient);
  final salesProvider = SalesProvider(dioClient);
  final customerProvider = CustomerProvider(dioClient);
  final notificationProvider = NotificationProvider(dioClient);

  final router = createRouter(authProvider);

  // Set callback navigasi: saat notifikasi diklik, arahkan ke halaman /notifications
  notificationProvider.onNotificationTap = (route) {
    if (rootNavigatorKey.currentContext != null) {
      router.go(route);
    }
  };

  // Inisialisasi Firebase Messaging (foreground listener, permission, token)
  // Dipanggil di sini agar terpasang sejak app pertama kali buka.
  await notificationProvider.initFirebaseMessaging();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: updateProvider),
        ChangeNotifierProvider.value(value: absensiProvider),
        ChangeNotifierProvider.value(value: dashboardProvider),
        ChangeNotifierProvider.value(value: salesProvider),
        ChangeNotifierProvider.value(value: customerProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        Provider.value(value: kandangRepository),
      ],
      child: App(router: router),
    ),
  );
}