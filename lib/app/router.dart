import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_kandang_screen.dart';
import '../../features/auth/screens/login_sales_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/absensi/absensi_screen.dart' as absensi_screen;
import '../../features/input/screens/input_pakan_screen.dart';
import '../../features/input/screens/input_produksi_screen.dart';
import '../../features/input/screens/input_kematian_screen.dart';
import '../../features/input/screens/input_ovk_screen.dart';
import '../../features/input/screens/checklist_kebersihan_screen.dart';
import '../../features/sales/screens/main_sales_screen.dart';
import '../../features/sales/screens/input_penjualan_screen.dart';
import '../../features/sales/screens/penarikan_barang_screen.dart';
import '../../features/sales/screens/retur_barang_screen.dart';
import '../../features/sales/screens/sales_stok_history_screen.dart';
import '../../features/sales/screens/rekap_penjualan_screen.dart';
import '../../features/sales/screens/riwayat_setoran_screen.dart';
import '../../features/sales/screens/faq_bantuan_screen.dart';

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
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
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
        path: '/sales/faq-bantuan',
        name: 'sales-faq-bantuan',
        builder: (context, state) => const FaqBantuanScreen(),
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
          // Import dilakukan di atas secara otomatis atau manual
          return const absensi_screen.AbsensiScreen();
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
