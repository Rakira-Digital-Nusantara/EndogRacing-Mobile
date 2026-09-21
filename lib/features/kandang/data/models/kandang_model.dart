class KandangModel {
  final String kdgCode;
  final String kdgNama;
  final double? kdgLatitude;
  final double? kdgLongitude;

  KandangModel({
    required this.kdgCode,
    required this.kdgNama,
    this.kdgLatitude,
    this.kdgLongitude,
  });

  factory KandangModel.fromJson(Map<String, dynamic> json) {
    return KandangModel(
      kdgCode: json['kdg_code'] as String,
      kdgNama: json['kdg_nama'] as String,
      kdgLatitude: json['kdg_latitude'] != null ? double.tryParse(json['kdg_latitude'].toString()) : null,
      kdgLongitude: json['kdg_longitude'] != null ? double.tryParse(json['kdg_longitude'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kdg_code': kdgCode,
      'kdg_nama': kdgNama,
      'kdg_latitude': kdgLatitude,
      'kdg_longitude': kdgLongitude,
    };
  }
}
