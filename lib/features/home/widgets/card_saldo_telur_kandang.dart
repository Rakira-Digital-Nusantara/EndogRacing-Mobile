import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../kandang/data/models/produksi_telur_model.dart';
import '../../kandang/providers/kandang_telur_provider.dart';

class CardSaldoTelurKandang extends StatefulWidget {
  const CardSaldoTelurKandang({super.key});

  @override
  State<CardSaldoTelurKandang> createState() => _CardSaldoTelurKandangState();
}

class _CardSaldoTelurKandangState extends State<CardSaldoTelurKandang> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kdgCode = context.read<AuthProvider>().kandang?.kdgCode ?? '';
      if (kdgCode.isNotEmpty) {
        context.read<KandangTelurProvider>().fetchSaldoKandang(kdgCode);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KandangTelurProvider>();
    final isLoading = provider.isLoadingSaldo;

    SaldoTelurKandangItem? saldoUtuh;
    for (var e in provider.saldoTelurList) {
      if (e.kategori.toLowerCase().contains('utuh')) {
        saldoUtuh = e;
        break;
      }
    }
    if (saldoUtuh == null && provider.saldoTelurList.isNotEmpty) {
      saldoUtuh = provider.saldoTelurList.first;
    }

    final double saldoKg = saldoUtuh != null ? saldoUtuh.saldoKg : provider.totalSaldoKg;
    final int kasSiapSetor = saldoUtuh != null ? saldoUtuh.kasTersedia : provider.totalKasSiapSetor;
    final double sisaMengendapKg = saldoUtuh != null ? saldoUtuh.sisaKg : provider.totalSisaKg;
    final double kgEkuivalenKas = kasSiapSetor * 15.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle pattern
          Positioned(
            right: -15,
            bottom: -20,
            child: Icon(
              Icons.egg_outlined,
              size: 130,
              color: const Color(0xFFF1F5F9),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: Color(0xFFEA580C), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Persediaan Telur Kandang',
                              style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Stok mengendap siap setor',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.history_rounded, color: Color(0xFF64748B), size: 22),
                      tooltip: 'Riwayat Setoran',
                      onPressed: () => context.push('/riwayat-setor-telur'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main Metric: Saldo Saat Ini
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      isLoading ? '...' : saldoKg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Kg',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kasSiapSetor > 0
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: kasSiapSetor > 0
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        kasSiapSetor > 0 ? '$kasSiapSetor KAS SIAP SETOR' : 'BELUM ADA KAS UTUH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: kasSiapSetor > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Sub Metrics Grid Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Kas Siap Setor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kas Siap Setor (@ 15 Kg)',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLoading ? '...' : '$kasSiapSetor Kas (${kgEkuivalenKas.toStringAsFixed(1)} Kg)',
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 28,
                        width: 1,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      // Sisa Mengendap
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sisa Pecahan Mengendap',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isLoading ? '...' : '${sisaMengendapKg.toStringAsFixed(1)} Kg',
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
