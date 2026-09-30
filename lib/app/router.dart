import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_kandang_screen.dart';
import '../../features/auth/screens/login_sales_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/absensi/absensi_screen.dart' as absensi_screen;
import '../../features/input/screens/input_pakan_screen.dart';
import '../../features/input/screens/input_produksi_screen.dart';
import '../../features/input/screens/input_kematian_screen.dart';
import '../../features/input/screens/input_ovk_screen.dart';
import '../../features/input/screens/checklist_kebersihan_screen.dart';
import '../../features/sales/screens/main_sales_screen.dart';
import '../../features/sales/screens/transactions/input_penjualan_screen.dart';
import '../../features/sales/screens/inventory/penarikan_barang_screen.dart';
import '../../features/sales/screens/inventory/retur_barang_screen.dart';
import '../../features/sales/screens/inventory/lapor_pecah_mobil_screen.dart';
import '../../features/sales/screens/inventory/sales_stok_history_screen.dart';
import '../../features/sales/screens/transactions/rekap_penjualan_screen.dart';
import '../../features/sales/screens/cash/riwayat_setoran_screen.dart';
import '../../features/kandang/screens/kandang_activity_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
/// Konfigurasi routing (navigasi) aplikasi menggunakan GoRouter.
///
/// GoRouter adalah cara modern untuk mengatur perpindahan halaman
/// di Flutter. Berbeda dengan Navigator.push() yang bersifat imperatif,
/// GoRouter bersifat deklaratif — artinya kita cukup mendefinisikan
/// "kondisi" kapan halaman mana yang harus ditampilkan.
///
/// Contoh: Jika user belum login → tampilkan LoginScreen.
///         Jika user sudah login → tampilkan HomeScreen.
/// Membuat instance GoRouter.
///
/// [authProvider] digunakan untuk menentukan apakah user
/// perlu diarahkan ke halaman login atau langsung ke home.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // Halaman default saat app pertama kali dibuka (Mulai dari Splash)
    initialLocation: '/',
    // Listener: setiap kali status login berubah, GoRouter
    // akan mengecek ulang apakah perlu redirect.
    refreshListenable: authProvider,
    // Redirect logic dihidupkan kembali
    redirect: (context, state) {
      final bool isLoggedIn = authProvider.isLoggedIn;
      final String loc = state.matchedLocation;
      
      // Halaman yang berkaitan dengan login
      final bool isAuthPage = loc == '/role-selection' || loc == '/login-kandang' || loc == '/login-sales';
      // Biarkan splash screen berjalan tanpa diinterupsi
      if (loc == '/') return null;
      // Jika belum login dan mencoba masuk ke halaman selain login -> tendang ke role selection
      if (!isLoggedIn && !isAuthPage) {
        return '/role-selection';
      }
      // Jika sudah login dan mencoba masuk ke halaman login -> arahkan ke home yang sesuai
      if (isLoggedIn && isAuthPage) {
        if (authProvider.user != null) {
          // Jika login sebagai sales
          return '/sales/dashboard';
        } else {
          // Jika login sebagai kandang
          return '/home';
        }
      }
      
      return null; // Tidak ada pengalihan, lanjutkan rute normal
    },
    // Daftar semua halaman (route) di aplikasi
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/checklist-kebersihan',
        name: 'checklist-kebersihan',
        builder: (context, state) => const ChecklistKebersihanScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login-kandang',
        name: 'login-kandang',
        builder: (context, state) => const LoginKandangScreen(),
      ),
      GoRoute(
        path: '/login-sales',
        name: 'login-sales',
        builder: (context, state) => const LoginSalesScreen(),
      ),
      GoRoute(
        path: '/sales/dashboard',
        name: 'sales-dashboard',
        builder: (context, state) => const MainSalesScreen(),
      ),
      GoRoute(
        path: '/sales/penjualan/add',
        name: 'sales-penjualan-add',
        builder: (context, state) => const InputPenjualanScreen(),
      ),
      GoRoute(
        path: '/sales/penarikan',
        name: 'sales-penarikan',
        builder: (context, state) => const PenarikanBarangScreen(),
      ),
      GoRoute(
        path: '/sales/retur',
        name: 'sales-retur',
        builder: (context, state) => const ReturBarangScreen(),
      ),
      GoRoute(
        path: '/sales/lapor-pecah',
        name: 'sales-lapor-pecah',
        builder: (context, state) => const LaporPecahMobilScreen(),
      ),
      GoRoute(
        path: '/sales/stok-history',
        name: 'sales-stok-history',
        builder: (context, state) => const SalesStokHistoryScreen(),
      ),
      GoRoute(
        path: '/sales/rekap-penjualan',
        name: 'sales-rekap-penjualan',
        builder: (context, state) => const RekapPenjualanScreen(),
      ),
      GoRoute(
        path: '/sales/riwayat-setoran',
        name: 'sales-riwayat-setoran',
        builder: (context, state) => const RiwayatSetoranScreen(),
      ),

      GoRoute(
        path: '/kandang/activity',
        name: 'kandang-activity',
        builder: (context, state) => const KandangActivityScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/absensi',
        name: 'absensi',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final type = extra?['type'] as String? ?? 'masuk';
          // Import dilakukan di atas secara otomatis atau manual
          return absensi_screen.AbsensiScreen(type: type);
        },
      ),
      GoRoute(
        path: '/input-pakan',
        name: 'input-pakan',
        builder: (context, state) {
          return const InputPakanScreen(); 
        },
      ),
      GoRoute(
        path: '/input-produksi',
        name: 'input-produksi',
        builder: (context, state) {
          return const InputProduksiScreen(); 
        },
      ),
      GoRoute(
        path: '/input-kematian',
        name: 'input-kematian',
        builder: (context, state) {
          return const InputKematianScreen(); 
        },
      ),
      GoRoute(
        path: '/input-ovk',
        name: 'input-ovk',
        builder: (context, state) {
          return const InputOvkScreen(); 
        },
      ),
    ],
  );
}
