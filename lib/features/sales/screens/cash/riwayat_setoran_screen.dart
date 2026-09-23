import 'package:flutter/material.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';

class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final startStr = _selectedDateRange?.start.toIso8601String().split('T')[0];
    final endStr = _selectedDateRange?.end.toIso8601String().split('T')[0];
    context.read<SalesProvider>().fetchRiwayatSetoran(
      tanggalAwal: startStr,
      tanggalAkhir: endStr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();

    final riwayatMap = sales.riwayatSetoranData ?? {};
    List<dynamic> riwayatData = riwayatMap['history'] as List<dynamic>? ?? [];

    List<Map<String, dynamic>> filteredData = riwayatData
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    // Hitung total dari data yang difilter
    double totalSetoran = 0;
    for (var item in filteredData) {
      totalSetoran +=
          double.tryParse(
             item['nominal_setoran']?.toString() ?? '0',
          ) ??
          0;
    }

    // Alternatively, use API totals if not filtering locally and not using dummy data
    if (filteredData.isEmpty && riwayatData.isEmpty) {
      totalSetoran =
          double.tryParse(
            riwayatMap['total_setoran_semua']?.toString() ?? '0',
          ) ??
          0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        actions: [],
        title: const Text(
          'Riwayat Setoran Uang',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filter Tanggal
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Text(
                            _selectedDateRange != null
                                ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                                : 'Filter berdasarkan tanggal',
                            style: TextStyle(
                              color: _selectedDateRange != null
                                  ? AppColors.textPrimary
                                  : Colors.grey.shade400,
                              fontWeight: _selectedDateRange != null
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _selectedDateRange != null
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : Colors.white,
                          border: Border.all(
                            color: _selectedDateRange != null
                                ? AppColors.primary
                                : Colors.grey.shade200,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.calendar_month_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              initialDateRange: _selectedDateRange,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                _selectedDateRange = picked;
                              });
                              _fetchData();
                            }
                          },
                        ),
                      ),
                      if (_selectedDateRange != null) ...[
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDateRange = null;
                            });
                            _fetchData();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
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
                              _selectedDateRange == null
                                  ? 'Total Setoran (Semua)'
                                  : 'Total Setoran (Difilter)',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filteredData.length} Transaksi',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyFormatter.format(totalSetoran),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 0,
                    bottom: 12,
                  ),
                  child: Text(
                    'DAFTAR SETORAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Transaction List
          filteredData.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada riwayat pada tanggal tersebut',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 40,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredData[index];


                      DateTime dt;
                      try {
                        dt = DateTime.parse(
                          item['tanggal']?.toString() ??
                              item['created_at']?.toString() ??
                              DateTime.now().toIso8601String(),
                        );
                      } catch (e) {
                        dt = DateTime.now();
                      }
                      final isToday =
                          dt.day == DateTime.now().day &&
                          dt.month == DateTime.now().month;

                      // Parse time directly from ISO 8601 'tanggal' string (e.g. 2026-09-12T15:30:00Z)
                      String timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      final dateFormatted =
                          '${isToday ? 'Hari ini' : '${dt.day}/${dt.month}/${dt.year}'}, $timeStr';

                      final nominal =
                          double.tryParse(
                             item['nominal_setoran']?.toString() ?? '0',
                          ) ??
                          0;
                      final tujuan = item['tujuan']?.toString() ?? 'Kas Besar';
                      final keterangan =
                          item['catatan']?.toString() ??
                          item['keterangan']?.toString() ??
                          '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(height: 1),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        CurrencyFormatter.format(nominal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.account_balance_rounded,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              tujuan,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (keterangan != '-') ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.notes_rounded,
                                              size: 14,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                keterangan,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (item['foto_bukti'] != null &&
                                item['foto_bukti'].toString().isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Image.network(
                                            item['foto_bukti'],
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => const Padding(
                                                  padding: EdgeInsets.all(32),
                                                  child: Icon(
                                                    Icons.broken_image_rounded,
                                                    size: 48,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.image_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                  label: const Text(
                                    'Lihat Bukti Setoran',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    side: BorderSide(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }, childCount: filteredData.length),
                  ),
                ),
        ],
      ),
    );
  }
}
