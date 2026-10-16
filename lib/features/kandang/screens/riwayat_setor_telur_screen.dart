import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/models/setor_telur_model.dart';
import '../providers/kandang_telur_provider.dart';

class RiwayatSetorTelurScreen extends StatefulWidget {
  const RiwayatSetorTelurScreen({super.key});

  @override
  State<RiwayatSetorTelurScreen> createState() => _RiwayatSetorTelurScreenState();
}

class _RiwayatSetorTelurScreenState extends State<RiwayatSetorTelurScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRiwayat();
    });
  }

  void _loadRiwayat() {
    final kdgCode = context.read<AuthProvider>().kandang?.kdgCode ?? '';
    String? startStr;
    String? endStr;

    if (_selectedDateRange != null) {
      startStr = _selectedDateRange!.start.toIso8601String().split('T')[0];
      endStr = _selectedDateRange!.end.toIso8601String().split('T')[0];
    }

    context.read<KandangTelurProvider>().fetchRiwayatSetor(
      kdgCode,
      startDate: startStr,
      endDate: endStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<KandangTelurProvider>();
    final isLoading = provider.isLoadingRiwayat;
    final list = provider.riwayatSetorList;
    final error = provider.errorRiwayat;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Riwayat Setor Kas Telur',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tanggal
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        initialDateRange: _selectedDateRange ??
                            DateTimeRange(
                              start: DateTime.now().subtract(const Duration(days: 30)),
                              end: DateTime.now(),
                            ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDateRange = picked);
                        _loadRiwayat();
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedDateRange == null
                                  ? 'Semua Waktu (30 Hari Terakhir)'
                                  : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                            ),
                          ),
                          if (_selectedDateRange != null)
                            GestureDetector(
                              onTap: () {
                                setState(() => _selectedDateRange = null);
                                _loadRiwayat();
                              },
                              child: const Icon(Icons.close, size: 16, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // List Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : error.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 40),
                              const SizedBox(height: 12),
                              Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _loadRiwayat, child: const Text('Coba Lagi')),
                            ],
                          ),
                        ),
                      )
                    : list.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                const Text(
                                  'Belum ada riwayat setoran kas telur',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Setoran kas yang telah dikirim ke gudang akan muncul di sini.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () async => _loadRiwayat(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(20),
                              itemCount: list.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                return InkWell(
                                  onTap: () {
                                    context.push('/setor-telur-detail', extra: item.setorCode);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              item.setorCode,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: Color(0xFF1E293B),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0FDF4),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFBBF7D0)),
                                              ),
                                              child: Text(
                                                item.status ?? 'Disetor',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF16A34A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_today, size: 13, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Text(item.tanggal, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                            const SizedBox(width: 14),
                                            const Icon(Icons.warehouse_outlined, size: 14, color: Color(0xFF64748B)),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                item.gudangNama,
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(color: Color(0xFFF1F5F9), height: 1),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Kas Disetor:',
                                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                style: const TextStyle(color: Color(0xFF1E293B)),
                                                children: [
                                                  TextSpan(
                                                    text: '${item.totalKas} Kas ',
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                                  ),
                                                  TextSpan(
                                                    text: '(${item.totalKg.toStringAsFixed(1)} Kg)',
                                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
