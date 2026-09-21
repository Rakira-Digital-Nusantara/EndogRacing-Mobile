import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:intl/intl.dart';

class SalesStokHistoryScreen extends StatefulWidget {
  const SalesStokHistoryScreen({super.key});

  @override
  State<SalesStokHistoryScreen> createState() => _SalesStokHistoryScreenState();
}

class _SalesStokHistoryScreenState extends State<SalesStokHistoryScreen> {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    String? startStr;
    String? endStr;
    if (_selectedDateRange != null) {
      final formatter = DateFormat('yyyy-MM-dd');
      startStr = formatter.format(_selectedDateRange!.start);
      endStr = formatter.format(_selectedDateRange!.end);
    }
    context.read<SalesProvider>().fetchRiwayatStokMobil(tanggalAwal: startStr, tanggalAkhir: endStr);
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    List<Map<String, dynamic>> filteredHistory = sales.riwayatStokMobil;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        actions: [
        ],
        title: const Text('Semua Riwayat Stok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      body: Column(
        children: [
          // Filter Widget
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
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
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Result List
          Expanded(
            child: sales.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filteredHistory.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('Tidak ada riwayat pada tanggal tersebut', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 20),
                  itemCount: filteredHistory.length,
                  itemBuilder: (context, index) {
                    final item = filteredHistory[index];
                    final isPositive = (item['arah']?.toString().toUpperCase() == 'IN');
                    final labelPerubahan = item['label_perubahan']?.toString() ?? '0';
                    
                    String amountStr = labelPerubahan;
                    String unitStr = '';
                    final parts = labelPerubahan.split(' ');
                    if (parts.length > 1) {
                      amountStr = parts[0];
                      unitStr = parts.sublist(1).join(' ');
                    }

                    String title = item['jenis_transaksi']?.toString() ?? 'Transaksi';
                    if (title.toLowerCase() == 'retur') {
                      title = isPositive ? 'Terima Retur' : 'Kirim Retur';
                    }

                    return _buildHistoryItem(
                      title: title,
                      subtitle: '${item['sku_name'] ?? ''}, ${item['waktu_format'] ?? item['tanggal']}',
                      amount: amountStr,
                      unit: unitStr,
                      isPositive: isPositive,
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required String amount,
    required String unit,
    required bool isPositive,
  }) {
    final color = isPositive ? AppColors.primary : Colors.red;
    final icon = isPositive ? Icons.download_rounded : Icons.upload_rounded;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(unit, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
