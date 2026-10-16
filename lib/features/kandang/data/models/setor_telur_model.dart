import 'produksi_telur_model.dart';

class GudangTujuanItem {
  final String gudangCode;
  final String gudangNama;
  final String gudangTipe;

  GudangTujuanItem({
    required this.gudangCode,
    required this.gudangNama,
    required this.gudangTipe,
  });

  factory GudangTujuanItem.fromJson(Map<String, dynamic> json) {
    return GudangTujuanItem(
      gudangCode: json['gudang_code']?.toString() ?? '',
      gudangNama: json['gudang_nama']?.toString() ?? '',
      gudangTipe: json['gudang_tipe']?.toString() ?? 'Gudang',
    );
  }
}

class SetorTelurFormResponse {
  final String kdgCode;
  final String kdgNama;
  final String defaultGudangCode;
  final String defaultGudangNama;
  final List<SaldoTelurKandangItem> saldoKandang;
  final List<GudangTujuanItem> daftarGudang;

  SetorTelurFormResponse({
    required this.kdgCode,
    required this.kdgNama,
    this.defaultGudangCode = 'GDG0001',
    this.defaultGudangNama = 'Gudang Pusat',
    required this.saldoKandang,
    required this.daftarGudang,
  });

  factory SetorTelurFormResponse.fromJson(Map<String, dynamic> json) {
    final kandangMap = json['kandang'] is Map ? json['kandang'] : {};
    
    final saldoList = <SaldoTelurKandangItem>[];
    if (json['saldo_kandang'] is List) {
      for (var item in (json['saldo_kandang'] as List)) {
        if (item is Map) {
          saldoList.add(SaldoTelurKandangItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final gudangList = <GudangTujuanItem>[];
    if (json['daftar_gudang'] is List) {
      for (var item in (json['daftar_gudang'] as List)) {
        if (item is Map) {
          gudangList.add(GudangTujuanItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return SetorTelurFormResponse(
      kdgCode: kandangMap['kdg_code']?.toString() ?? json['kdg_code']?.toString() ?? '',
      kdgNama: kandangMap['kdg_nama']?.toString() ?? json['kdg_nama']?.toString() ?? 'Kandang',
      defaultGudangCode: json['default_gudang_code']?.toString() ?? 'GDG0001',
      defaultGudangNama: json['default_gudang_nama']?.toString() ?? 'Gudang Pusat',
      saldoKandang: saldoList,
      daftarGudang: gudangList,
    );
  }
}

class SetorDetailItem {
  final String skuProduct;
  final String skuName;
  final String kategori;
  final int qtyKas;
  final double qtyKgEkuivalen;
  final double sisaKgDiKandang;
  final String? catatan;

  SetorDetailItem({
    required this.skuProduct,
    required this.skuName,
    required this.kategori,
    required this.qtyKas,
    required this.qtyKgEkuivalen,
    required this.sisaKgDiKandang,
    this.catatan,
  });

  factory SetorDetailItem.fromJson(Map<String, dynamic> json) {
    final dynamic kasRaw = json['qty_kas'] ?? json['total_kas'] ?? json['kas'];
    final dynamic kgRaw = json['qty_kg_ekuivalen'] ?? json['total_kg_ekuivalen'] ?? json['qty_kg'] ?? json['total_kg'];
    final dynamic sisaRaw = json['sisa_kg_di_kandang'] ?? json['sisa_kg'] ?? json['sisa_saldo_kg'];

    return SetorDetailItem(
      skuProduct: json['sku_product']?.toString() ?? '',
      skuName: json['sku_name']?.toString() ?? json['nama_produk']?.toString() ?? json['product_name']?.toString() ?? 'Telur Ayam Negeri',
      kategori: json['kategori']?.toString() ?? 'Utuh',
      qtyKas: (kasRaw is num) ? kasRaw.toInt() : int.tryParse(kasRaw?.toString() ?? '0') ?? 0,
      qtyKgEkuivalen: (kgRaw is num) ? kgRaw.toDouble() : double.tryParse(kgRaw?.toString() ?? '0') ?? 0.0,
      sisaKgDiKandang: (sisaRaw is num) ? sisaRaw.toDouble() : double.tryParse(sisaRaw?.toString() ?? '0') ?? 0.0,
      catatan: json['catatan']?.toString(),
    );
  }
}

class SetorTelurResult {
  final String setorCode;
  final String kdgCode;
  final String kdgNama;
  final String gudangCode;
  final String gudangNama;
  final String tanggalSetor;
  final String? catatan;
  final int totalKas;
  final double totalKgEkuivalen;
  final String? petugasNama;
  final List<SetorDetailItem> details;

  SetorTelurResult({
    required this.setorCode,
    required this.kdgCode,
    this.kdgNama = '',
    required this.gudangCode,
    this.gudangNama = '',
    required this.tanggalSetor,
    this.catatan,
    required this.totalKas,
    required this.totalKgEkuivalen,
    this.petugasNama,
    required this.details,
  });

  factory SetorTelurResult.fromJson(Map<String, dynamic> json) {
    final detailList = <SetorDetailItem>[];
    if (json['details'] is List) {
      for (var d in (json['details'] as List)) {
        if (d is Map) {
          detailList.add(SetorDetailItem.fromJson(Map<String, dynamic>.from(d)));
        }
      }
    }

    return SetorTelurResult(
      setorCode: json['setor_code']?.toString() ?? '',
      kdgCode: json['kdg_code']?.toString() ?? '',
      kdgNama: json['kdg_nama']?.toString() ?? '',
      gudangCode: json['gudang_code']?.toString() ?? '',
      gudangNama: json['gudang_nama']?.toString() ?? '',
      tanggalSetor: json['tanggal_setor']?.toString() ?? json['tanggal']?.toString() ?? '',
      catatan: json['catatan']?.toString(),
      totalKas: (json['total_kas'] is num) ? (json['total_kas'] as num).toInt() : int.tryParse(json['total_kas']?.toString() ?? '0') ?? 0,
      totalKgEkuivalen: (json['total_kg_ekuivalen'] is num) ? (json['total_kg_ekuivalen'] as num).toDouble() : double.tryParse(json['total_kg_ekuivalen']?.toString() ?? '0') ?? 0.0,
      petugasNama: json['petugas_nama']?.toString() ?? json['usr_name']?.toString(),
      details: detailList,
    );
  }
}

class RiwayatSetorItem {
  final String setorCode;
  final String tanggal;
  final String kdgCode;
  final String kdgNama;
  final String gudangNama;
  final int totalKas;
  final double totalKg;
  final String? petugasNama;
  final String? status;

  RiwayatSetorItem({
    required this.setorCode,
    required this.tanggal,
    required this.kdgCode,
    required this.kdgNama,
    required this.gudangNama,
    required this.totalKas,
    required this.totalKg,
    this.petugasNama,
    this.status,
  });

  factory RiwayatSetorItem.fromJson(Map<String, dynamic> json) {
    return RiwayatSetorItem(
      setorCode: json['setor_code']?.toString() ?? '',
      tanggal: json['tanggal_setor']?.toString() ?? json['tanggal']?.toString() ?? '',
      kdgCode: json['kdg_code']?.toString() ?? '',
      kdgNama: json['kandang']?['kdg_nama']?.toString() ?? json['kdg_nama']?.toString() ?? '',
      gudangNama: json['gudang']?['gudang_nama']?.toString() ?? json['gudang_nama']?.toString() ?? 'Gudang',
      totalKas: (json['total_kas'] is num) ? (json['total_kas'] as num).toInt() : int.tryParse(json['total_kas']?.toString() ?? '0') ?? 0,
      totalKg: (json['total_kg_ekuivalen'] is num)
          ? (json['total_kg_ekuivalen'] as num).toDouble()
          : (json['total_kg'] is num)
              ? (json['total_kg'] as num).toDouble()
              : double.tryParse(json['total_kg_ekuivalen']?.toString() ?? json['total_kg']?.toString() ?? '0') ?? 0.0,
      petugasNama: json['petugas_nama']?.toString() ?? json['creator']?['usr_name']?.toString(),
      status: json['status']?.toString() ?? 'Disetor',
    );
  }
}
