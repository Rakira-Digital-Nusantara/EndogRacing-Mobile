import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SalesStokHistoryScreen extends StatefulWidget {
  const SalesStokHistoryScreen({super.key});

  @override
  State<SalesStokHistoryScreen> createState() => _SalesStokHistoryScreenState();
}

class _SalesStokHistoryScreenState extends State<SalesStokHistoryScreen> {
  DateTimeRange? _selectedDateRange;

  // Dummy Data for History (Now with actual DateTime for filtering)
  final List<Map<String, dynamic>> _allHistoryData = [
    {
      'title': 'Ambil Gudang', 
      'subtitle': 'Pusat', 
      'amount': '+50', 
      'unit': 'Kg', 
      'isPositive': true,
      'date': DateTime.now()
    },
    {
      'title': 'Retur Telur', 
      'subtitle': 'Pecah', 
      'amount': '-2', 
      'unit': 'Kg', 
      'isPositive': false,
      'date': DateTime.now().subtract(const Duration(hours: 3))
    },
    {
      'title': 'Ambil Gudang', 
      'subtitle': 'Pusat', 
      'amount': '+45', 
      'unit': 'Kg', 
      'isPositive': true,
      'date': DateTime.now().subtract(const Duration(days: 1))
    },
    {
      'title': 'Retur Telur', 
      'subtitle': 'Sisa Stok', 
      'amount': '-5', 
      'unit': 'Kg', 
      'isPositive': false,
      'date': DateTime.now().subtract(const Duration(days: 1, hours: 2))
    },
    {
      'title': 'Ambil Gudang', 
      'subtitle': 'Pusat', 
      'amount': '+60', 
      'unit': 'Kg', 
      'isPositive': true,
      'date': DateTime.now().subtract(const Duration(days: 2))
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filter logic
    List<Map<String, dynamic>> filteredHistory = _allHistoryData;
    if (_selectedDateRange != null) {
      filteredHistory = _allHistoryData.where((h) {
        final date = h['date'] as DateTime;
        return date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) && 
               date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
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
          
          // Result List
          Expanded(
            child: filteredHistory.isEmpty 
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
                    // Format output time
                    final dt = item['date'] as DateTime;
                    final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    final isToday = dt.day == DateTime.now().day && dt.month == DateTime.now().month;
                    final subtitleFormatted = '${item['subtitle']}, ${isToday ? 'Hari ini' : '${dt.day}/${dt.month}/${dt.year}'} $timeStr';

                    return _buildHistoryItem(
                      title: item['title'],
                      subtitle: subtitleFormatted,
                      amount: item['amount'],
                      unit: item['unit'],
                      isPositive: item['isPositive'],
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
