class AbsensiModel {
  final int? id;
  final String? absCode;
  final String? kdgCode;
  final String? empCode;
  final String tipeAbsen; // "Masuk" atau "Pulang"
  final String tanggalAbsen; // "YYYY-MM-DD"
  final String? waktuAbsen; // "HH:mm:ss" atau tergabung di created_at
  final String? fotoSelfie;
  final double? latitude;
  final double? longitude;
  final String? status; // "Terlambat", dsb

  AbsensiModel({
    this.id,
    this.absCode,
    this.kdgCode,
    this.empCode,
    required this.tipeAbsen,
    required this.tanggalAbsen,
    this.waktuAbsen,
    this.fotoSelfie,
    this.latitude,
    this.longitude,
    this.status,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      id: json['id'],
      absCode: json['abs_code'],
      kdgCode: json['kdg_code'],
      empCode: json['emp_code'],
      tipeAbsen: json['abs_tipe_absen'] ?? json['tipe_absen'] ?? 'Masuk',
      tanggalAbsen: json['abs_tanggal_absen'] ?? json['tanggal_absen'] ?? json['tanggal'] ?? json['created_at'] ?? '',
      waktuAbsen: json['abs_waktu_absen'] ?? json['waktu_absen'] ?? json['created_at'],
      fotoSelfie: json['abs_foto_selfie'] ?? json['foto_absensi'],
      latitude: json['abs_latitude'] != null ? double.tryParse(json['abs_latitude'].toString()) : (json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null),
      longitude: json['abs_longitude'] != null ? double.tryParse(json['abs_longitude'].toString()) : (json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null),
      status: json['status'],
    );
  }
}
