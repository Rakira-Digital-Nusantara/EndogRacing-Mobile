import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Memeriksa dan meminta izin lokasi dari pengguna.
  /// Melemparkan exception jika izin ditolak secara permanen atau layanan mati.
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS menyala
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan GPS (Location Service) dinonaktifkan. Harap nyalakan GPS.');
    }

    // 2. Cek status izin saat ini
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // 3. Minta izin jika ditolak sebelumnya (tapi bukan permanen)
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak oleh pengguna.');
      }
    }

    // 4. Jika izin ditolak secara permanen
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak secara permanen. Harap izinkan melalui pengaturan HP.');
    }

    return true; // Izin diberikan
  }

  /// Mendapatkan lokasi saat ini secara sekali tembak (one-shot).
  Future<Position> getCurrentLocation() async {
    await handleLocationPermission();
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Menghitung jarak antara dua titik koordinat (dalam meter).
  /// [startLatitude], [startLongitude] - Titik pengguna (HP)
  /// [endLatitude], [endLongitude] - Titik tujuan (Kandang)
  double calculateDistanceInMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Menyediakan stream (aliran data) lokasi real-time.
  /// Sesuai PRD: Update lokasi secara konstan (Live Tracking).
  Stream<Position> getLiveLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2, // Update jika pengguna bergerak minimal 2 meter
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
