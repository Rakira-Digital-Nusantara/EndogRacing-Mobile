class KandangModel {
  final String kdgCode;
  final String kdgNama;

  KandangModel({
    required this.kdgCode,
    required this.kdgNama,
  });

  factory KandangModel.fromJson(Map<String, dynamic> json) {
    return KandangModel(
      kdgCode: json['kdg_code'] as String,
      kdgNama: json['kdg_nama'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kdg_code': kdgCode,
      'kdg_nama': kdgNama,
    };
  }
}
