class SaldoTelurKandangItem {
  final String skuProduct;
  final String skuName;
  final String kategori;
  final double saldoKg;
  final int kasTersedia;
  final double sisaKg;
  final double conversionRate;

  SaldoTelurKandangItem({
    required this.skuProduct,
    required this.skuName,
    required this.kategori,
    required this.saldoKg,
    required this.kasTersedia,
    required this.sisaKg,
    this.conversionRate = 15.0,
  });

  factory SaldoTelurKandangItem.fromJson(Map<String, dynamic> json) {
    final double saldo = _parseDouble(json['saldo_kg'] ?? json['saldo_sekarang_di_kandang_kg']);
    final double rate = _parseDouble(json['conversion_rate'], defaultValue: 15.0);
    final int kas = json['kas_tersedia'] != null
        ? _parseInt(json['kas_tersedia'])
        : (rate > 0 ? (saldo / rate).floor() : 0);
    final double sisa = json['sisa_kg'] != null
        ? _parseDouble(json['sisa_kg'])
        : (rate > 0 ? saldo % rate : 0.0);

    return SaldoTelurKandangItem(
      skuProduct: json['sku_product']?.toString() ?? '',
      skuName: json['sku_name']?.toString() ?? (json['kategori']?.toString() ?? 'Telur'),
      kategori: json['kategori']?.toString() ?? 'Utuh',
      saldoKg: saldo,
      kasTersedia: kas,
      sisaKg: sisa,
      conversionRate: rate,
    );
  }

  static double _parseDouble(dynamic val, {double defaultValue = 0.0}) {
    if (val == null) return defaultValue;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? defaultValue;
  }

  static int _parseInt(dynamic val, {int defaultValue = 0}) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is double) return val.floor();
    return int.tryParse(val.toString()) ?? defaultValue;
  }
}

class ProduksiFormResponse {
  final String prdCode;
  final String kdgCode;
  final int populasiAyam;
  final List<SaldoTelurKandangItem> saldoTelurKandang;
  final List<dynamic> items;

  ProduksiFormResponse({
    required this.prdCode,
    required this.kdgCode,
    required this.populasiAyam,
    required this.saldoTelurKandang,
    required this.items,
  });

  factory ProduksiFormResponse.fromJson(Map<String, dynamic> json) {
    final saldoList = <SaldoTelurKandangItem>[];
    if (json['saldo_telur_kandang'] is List) {
      for (var item in (json['saldo_telur_kandang'] as List)) {
        if (item is Map<String, dynamic>) {
          saldoList.add(SaldoTelurKandangItem.fromJson(item));
        } else if (item is Map) {
          saldoList.add(SaldoTelurKandangItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ProduksiFormResponse(
      prdCode: json['prd_code']?.toString() ?? '',
      kdgCode: json['kdg_code']?.toString() ?? '',
      populasiAyam: json['populasi_ayam_saat_ini'] is int
          ? json['populasi_ayam_saat_ini'] as int
          : int.tryParse(json['populasi_ayam_saat_ini']?.toString() ?? '0') ?? 0,
      saldoTelurKandang: saldoList,
      items: json['items'] is List ? (json['items'] as List) : [],
    );
  }
}

class StokKandangInfo {
  final String skuProduct;
  final String kategori;
  final double panenKg;
  final double qtyButir;
  final double saldoSekarangDiKandangKg;
  final int potensiSetorKas;
  final double sisaKgDiKandang;
  final String label;

  StokKandangInfo({
    required this.skuProduct,
    required this.kategori,
    required this.panenKg,
    required this.qtyButir,
    required this.saldoSekarangDiKandangKg,
    required this.potensiSetorKas,
    required this.sisaKgDiKandang,
    required this.label,
  });

  factory StokKandangInfo.fromJson(Map<String, dynamic> json) {
    return StokKandangInfo(
      skuProduct: json['sku_product']?.toString() ?? '',
      kategori: json['kategori']?.toString() ?? '',
      panenKg: (json['panen_kg'] is num) ? (json['panen_kg'] as num).toDouble() : double.tryParse(json['panen_kg']?.toString() ?? '0') ?? 0.0,
      qtyButir: (json['qty_butir'] is num) ? (json['qty_butir'] as num).toDouble() : double.tryParse(json['qty_butir']?.toString() ?? '0') ?? 0.0,
      saldoSekarangDiKandangKg: (json['saldo_sekarang_di_kandang_kg'] is num) ? (json['saldo_sekarang_di_kandang_kg'] as num).toDouble() : double.tryParse(json['saldo_sekarang_di_kandang_kg']?.toString() ?? '0') ?? 0.0,
      potensiSetorKas: (json['potensi_setor_kas'] is num) ? (json['potensi_setor_kas'] as num).toInt() : int.tryParse(json['potensi_setor_kas']?.toString() ?? '0') ?? 0,
      sisaKgDiKandang: (json['sisa_kg_di_kandang'] is num) ? (json['sisa_kg_di_kandang'] as num).toDouble() : double.tryParse(json['sisa_kg_di_kandang']?.toString() ?? '0') ?? 0.0,
      label: json['label']?.toString() ?? '',
    );
  }
}
