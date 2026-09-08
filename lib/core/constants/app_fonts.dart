/// Konstanta nama font yang digunakan di aplikasi.
///
/// Gunakan class ini agar nama font tidak perlu ditulis manual
/// (menghindari typo dan menjaga konsistensi).
///
/// Contoh penggunaan:
/// ```dart
/// // Text biasa (otomatis dari ThemeData)
/// Text('Halo Dunia')
///
/// // Angka / timer / statistik
/// Text('01:23.456', style: TextStyle(fontFamily: AppFonts.number))
/// ```
class AppFonts {
  AppFonts._();

  /// Font utama untuk semua text umum (heading, body, label, dll).
  /// Sudah diset sebagai default di ThemeData (app.dart).
  static const String primary = 'HankenGrotesk';

  /// Font monospace untuk angka, timer, kecepatan, statistik.
  /// Gunakan secara manual di widget yang menampilkan angka.
  static const String number = 'JetBrainsMono';
}
