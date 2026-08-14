import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';

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
    // Halaman default saat app pertama kali dibuka
    initialLocation: '/login',

    // Listener: setiap kali status login berubah, GoRouter
    // akan mengecek ulang apakah perlu redirect.
    refreshListenable: authProvider,

    // Redirect logic: dijalankan setiap kali ada navigasi.
    redirect: (context, state) {
      final isLoggedIn = authProvider.isLoggedIn;
      final isOnLoginPage = state.matchedLocation == '/login';

      // Jika belum login dan bukan di halaman login → arahkan ke login
      if (!isLoggedIn && !isOnLoginPage) {
        return '/login';
      }

      // Jika sudah login tapi masih di halaman login → arahkan ke home
      if (isLoggedIn && isOnLoginPage) {
        return '/home';
      }

      // Tidak perlu redirect
      return null;
    },

    // Daftar semua halaman (route) di aplikasi
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
}
