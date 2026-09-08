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

import 'features/kandang/data/repositories/kandang_repository.dart';
import 'features/absensi/data/repositories/absensi_repository.dart';
import 'features/absensi/providers/absensi_provider.dart';

/// Entry point (titik awal) aplikasi.
///
/// File ini bertanggung jawab untuk:
/// 1. Memuat file .env (konfigurasi environment).
/// 2. Membuat instance DioClient (HTTP client).
/// 3. Mendaftarkan semua Provider (State Management).
/// 4. Menjalankan aplikasi.
///
/// Perhatikan bahwa file ini TIDAK berisi logika UI apapun.
/// Semua UI ada di folder features/ dan app/.
void main() async {
  // Pastikan binding Flutter sudah siap sebelum menjalankan kode async
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale bahasa Indonesia untuk format tanggal (intl)
  await initializeDateFormatting('id_ID', null);

  // Muat file .env (berisi API_URL, dll)
  await dotenv.load(fileName: '.env');

  // Buat instance DioClient (HTTP client utama)
  final dioClient = DioClient();

  // Buat instance repository dan utility
  final authRepository = AuthRepository(dioClient);
  final kandangRepository = KandangRepository(dioClient);
  final absensiRepository = AbsensiRepository(dioClient);
  final versionChecker = VersionChecker(dioClient);

  // Buat instance provider
  final authProvider = AuthProvider(authRepository);
  final updateProvider = UpdateProvider(versionChecker);
  final absensiProvider = AbsensiProvider(absensiRepository);
  final dashboardProvider = DashboardProvider(dioClient);
  final salesProvider = SalesProvider(dioClient);

  // --- DIMATIKAN SEMENTARA UNTUK TEST UI ---
  // Cek status login saat app dibuka (apakah masih punya token valid?)
  // await authProvider.checkLoginStatus();

  // Cek apakah ada update dari server
  // await updateProvider.checkForUpdate();

  // Buat router (membutuhkan authProvider untuk redirect logic)
  final router = createRouter(authProvider);

  // Jalankan aplikasi!
  runApp(
    /// MultiProvider mendaftarkan semua Provider agar bisa
    /// diakses dari widget manapun di bawahnya.
    ///
    /// Analoginya seperti "gudang data global" yang bisa
    /// diakses oleh semua halaman.
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: updateProvider),
        ChangeNotifierProvider.value(value: absensiProvider),
        ChangeNotifierProvider.value(value: dashboardProvider),
        ChangeNotifierProvider.value(value: salesProvider),
        Provider.value(value: kandangRepository),
      ],
      child: App(router: router),
    ),
  );
}
