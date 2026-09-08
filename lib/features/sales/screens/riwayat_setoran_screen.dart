import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class RiwayatSetoranScreen extends StatefulWidget {
  const RiwayatSetoranScreen({super.key});

  @override
  State<RiwayatSetoranScreen> createState() => _RiwayatSetoranScreenState();
}

class _RiwayatSetoranScreenState extends State<RiwayatSetoranScreen> {
  DateTimeRange? _selectedDateRange;

  // Dummy Data
  final List<Map<String, dynamic>> _allSetoranData = [
    {
      'id': 'SET-20260908-01',
      'date': DateTime.now(),
      'nominal': 15000000,
      'tujuan': 'Kas Besar (BCA Utama)',
      'keterangan': 'Setoran hasil jualan rute utara',
      'status': 'BERHASIL'
    },
    {
      'id': 'SET-20260907-02',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'nominal': 21000000,
      'tujuan': 'Kas Besar (Mandiri)',
      'keterangan': 'Sisa tunai kemarin',
      'status': 'BERHASIL'
    },
    {
      'id': 'SET-20260906-01',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'nominal': 8500000,
      'tujuan': 'Kas Besar (BCA Utama)',
      'keterangan': '-',
      'status': 'PENDING'
    },
    {
      'id': 'SET-20260905-01',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'nominal': 32000000,
      'tujuan': 'Kas Besar (BCA Utama)',
      'keterangan': 'Setoran lunas agen besar',
      'status': 'BERHASIL'
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    List<Map<String, dynamic>> filteredData = _allSetoranData;
    if (_selectedDateRange != null) {
      filteredData = _allSetoranData.where((h) {
        final date = h['date'] as DateTime;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
               date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Hitung total dari data yang difilter
    double totalSetoran = 0;
    for (var item in filteredData) {
      if (item['status'] == 'BERHASIL') {
        totalSetoran += item['nominal'];
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Riwayat Setoran Uang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            _selectedDateRange != null 
                              ? '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}'
                              : 'Filter berdasarkan tanggal',
                            style: TextStyle(
                              color: _selectedDateRange != null ? AppColors.textPrimary : Colors.grey.shade400,
                              fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: _selectedDateRange != null ? AppColors.primary.withOpacity(0.1) : Colors.white,
                          border: Border.all(color: _selectedDateRange != null ? AppColors.primary : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Summary Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDateRange == null ? 'Total Setoran (Semua)' : 'Total Setoran (Difilter)', 
                              style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                              child: Text('${filteredData.length} Transaksi', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(CurrencyFormatter.format(totalSetoran), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 12),
                  child: Text('DAFTAR SETORAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
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
                    Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Tidak ada riwayat pada tanggal tersebut', style: TextStyle(color: Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          : SliverPadding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredData[index];
                  final isSuccess = item['status'] == 'BERHASIL';
                  
                  final dt = item['date'] as DateTime;
                  final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                  final isToday = dt.day == DateTime.now().day && dt.month == DateTime.now().month;
                  final dateFormatted = '${isToday ? 'Hari ini' : '${dt.day}/${dt.month}/${dt.year}'}, $timeStr';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dateFormatted, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item['status'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSuccess ? Colors.green : Colors.orange,
                                ),
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
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(CurrencyFormatter.format(item['nominal']), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.account_balance_rounded, size: 14, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(child: Text(item['tujuan'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
                                    ],
                                  ),
                                  if (item['keterangan'] != '-') ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(child: Text(item['keterangan'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic))),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
                childCount: filteredData.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
