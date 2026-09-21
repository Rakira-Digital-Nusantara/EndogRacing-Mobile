import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:intl/intl.dart';

class RekapPenjualanScreen extends StatefulWidget {
  const RekapPenjualanScreen({super.key});

  @override
  State<RekapPenjualanScreen> createState() => _RekapPenjualanScreenState();
}

class _RekapPenjualanScreenState extends State<RekapPenjualanScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<SalesProvider>().fetchRekapHarian(tanggal: formattedDate);
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
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
        _selectedDate = picked;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final isLoading = provider.isLoading;
    final rekapData = provider.rekapHarianData ?? {};
    
    // Parse Summary
    final summary = rekapData['summary'] ?? {};
    final totalOmzet = double.tryParse(summary['total_omzet']?.toString() ?? '0') ?? 0.0;
    final totalLunas = double.tryParse(summary['total_lunas']?.toString() ?? '0') ?? 0.0;
    final totalPiutang = double.tryParse(summary['total_piutang']?.toString() ?? '0') ?? 0.0;
    final totalKg = double.tryParse(summary['total_kg_terjual']?.toString() ?? '0') ?? 0.0;

    // Parse Transactions
    final transactions = (rekapData['transactions'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Rekap Penjualan Harian', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selector
                  InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Tanggal Rekap', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  Text(
                                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  if (isLoading)
                    const Center(child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else ...[
                    // Summary Cards
                    const Text('RINGKASAN HARI INI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Omzet Penjualan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(CurrencyFormatter.format(totalOmzet), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Lunas', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    Text(CurrencyFormatter.format(totalLunas), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 30, color: Colors.white24),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Piutang', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                      Text(CurrencyFormatter.format(totalPiutang), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.egg_alt_rounded, color: Colors.orange),
                              ),
                              const SizedBox(width: 12),
                              const Text('Total Telur Terjual', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          Text('$totalKg Kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Transaction List Header
                    const Text('RINCIAN TRANSAKSI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    if (transactions.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Belum ada transaksi di tanggal ini.', style: TextStyle(color: Colors.grey.shade500)),
                        ),
                      ),
                  ]
                ],
              ),
            ),
          ),
          
          if (!isLoading && transactions.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final trx = transactions[index];
                    final status = trx['status']?.toString().toUpperCase() ?? 'PIUTANG';
                    final isLunas = status == 'LUNAS';
                    
                    final customerName = trx['customer_name']?.toString() ?? 'Unknown Customer';
                    final invoiceNumber = trx['invoice_number']?.toString() ?? '-';
                    final qty = double.tryParse(trx['total_kg']?.toString() ?? '0') ?? 0.0;
                    final total = double.tryParse(trx['total_harga']?.toString() ?? '0') ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                          )
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isLunas ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isLunas ? Icons.check_circle_rounded : Icons.schedule_rounded, 
                              color: isLunas ? Colors.green : Colors.orange, 
                              size: 20
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                const SizedBox(height: 4),
                                Text('$invoiceNumber • $qty Kg', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(CurrencyFormatter.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Text(
                                status, 
                                style: TextStyle(
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold, 
                                  color: isLunas ? Colors.green : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: transactions.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
