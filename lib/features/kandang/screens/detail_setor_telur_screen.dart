import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../data/models/setor_telur_model.dart';
import '../data/repositories/kandang_telur_repository.dart';

class DetailSetorTelurScreen extends StatefulWidget {
  final dynamic data; // Bisa SetorTelurResult atau String (setorCode)

  const DetailSetorTelurScreen({super.key, required this.data});

  @override
  State<DetailSetorTelurScreen> createState() => _DetailSetorTelurScreenState();
}

class _DetailSetorTelurScreenState extends State<DetailSetorTelurScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  SetorTelurResult? _detail;

  @override
  void initState() {
    super.initState();
    if (widget.data is SetorTelurResult) {
      _detail = widget.data as SetorTelurResult;
    } else if (widget.data is String) {
      _fetchDetail(widget.data as String);
    } else if (widget.data is Map) {
      _detail = SetorTelurResult.fromJson(Map<String, dynamic>.from(widget.data as Map));
    }
  }

  Future<void> _fetchDetail(String setorCode) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final repo = context.read<KandangTelurRepository>();
      final result = await repo.getDetailSetorTelur(setorCode);
      setState(() => _detail = result);
    } catch (e) {
      setState(() => _errorMessage = 'Gagal memuat detail setoran: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Surat Jalan Setor Telur',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/home'),
                          child: const Text('Kembali ke Beranda'),
                        ),
                      ],
                    ),
                  ),
                )
              : _detail == null
                  ? const Center(child: Text('Data tidak ditemukan'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // SURAT JALAN CARD
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Header Status Banner
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF0FDF4),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'SETORAN KAS BERHASIL',
                                              style: TextStyle(
                                                color: Color(0xFF15803D),
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Surat Jalan Digital / Bukti Serah Terima',
                                              style: TextStyle(
                                                color: Color(0xFF166534),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nomor Setor & Salin
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Nomor Setor',
                                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                _detail!.setorCode,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF1E293B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF64748B)),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: _detail!.setorCode));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Nomor setor disalin ke clipboard')),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tanggal: ${_detail!.tanggalSetor}',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                      ),

                                      const SizedBox(height: 16),
                                      const Divider(color: Color(0xFFE2E8F0)),
                                      const SizedBox(height: 16),

                                      // Route Card: Dari Kandang -> Ke Gudang
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.cottage_outlined, color: Color(0xFF0284C7), size: 22),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Dari Kandang', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                                  Text(
                                                    _detail!.kdgNama.isNotEmpty ? _detail!.kdgNama : _detail!.kdgCode,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 18),
                                            const SizedBox(width: 10),
                                            const Icon(Icons.warehouse_outlined, color: Color(0xFF16A34A), size: 22),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text('Ke Gudang', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                                  Text(
                                                    _detail!.gudangNama.isNotEmpty ? _detail!.gudangNama : _detail!.gudangCode,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 20),

                                      // Rincian Item Disetor
                                      const Text(
                                        'Rincian Produk Disetor',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 10),

                                      ...(_detail!.details.map((item) {
                                        return Container(
                                          margin: const EdgeInsets.only(bottom: 10),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFAFAFA),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade200),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFF7ED),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(Icons.egg, color: Color(0xFFEA580C), size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.skuName,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Sisa di Kandang: ${item.sisaKgDiKandang.toStringAsFixed(1)} Kg',
                                                      style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${item.qtyKas} Kas',
                                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF15803D)),
                                                  ),
                                                  Text(
                                                    '${item.qtyKgEkuivalen.toStringAsFixed(1)} Kg',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      })),

                                      const SizedBox(height: 12),

                                      // Total Disetor Highlight Card
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF0FDF4),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: const Color(0xFFBBF7D0)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Disetor ke Gudang',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${_detail!.totalKas} Kas',
                                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFF15803D)),
                                                ),
                                                Text(
                                                  '(${_detail!.totalKgEkuivalen.toStringAsFixed(1)} Kg)',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (_detail!.catatan != null && _detail!.catatan!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        const Text('Catatan:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(
                                          _detail!.catatan!,
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Tombol Aksi
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/home'),
                              icon: const Icon(Icons.home_outlined, size: 20),
                              label: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/riwayat-setor-telur'),
                              icon: const Icon(Icons.receipt_long_outlined, size: 20),
                              label: const Text('Lihat Riwayat Setoran', style: TextStyle(fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }
}
