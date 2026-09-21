import 'package:flutter/material.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';

class CustomerTransactionHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> customer;

  const CustomerTransactionHistoryScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerTransactionHistoryScreen> createState() => _CustomerTransactionHistoryScreenState();
}

class _CustomerTransactionHistoryScreenState extends State<CustomerTransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final code = widget.customer['customer_code'] ?? widget.customer['code'] ?? '';
      if (code.toString().isNotEmpty) {
        context.read<SalesProvider>().fetchSalesHistory(customerCode: code.toString());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerName = widget.customer['customer_name']?.toString() ?? widget.customer['name']?.toString() ?? 'Unknown Customer';
    final customerCode = widget.customer['customer_code']?.toString() ?? widget.customer['code']?.toString() ?? 'CST-XXX';
    final sisaPiutang = double.tryParse(widget.customer['sisa_piutang']?.toString() ?? '0') ?? 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Softer background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Riwayat Transaksi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Premium Customer Header Info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          customerName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              customerCode,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sisa Piutang',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(sisaPiutang),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: sisaPiutang > 0 ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                      if (sisaPiutang > 0)
                        ElevatedButton(
                          onPressed: () {
                            // TODO: Add Pay Debt Logic
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red.shade700,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Bayar', style: TextStyle(fontWeight: FontWeight.bold)),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 6),
                              Text('Lunas', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Transaction List Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: [
                const Text(
                  'Semua Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(Icons.filter_list_rounded, size: 20, color: Colors.grey.shade500),
              ],
            ),
          ),

          // Transaction List
          Expanded(
            child: Consumer<SalesProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (provider.error.isNotEmpty) {
                  return Center(
                    child: Text(provider.error, style: const TextStyle(color: Colors.red)),
                  );
                }

                final transactions = provider.salesHistory;

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Belum ada transaksi', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final trx = transactions[index];
                    
                    DateTime date = DateTime.now();
                    if (trx['created_at'] != null) {
                      date = DateTime.tryParse(trx['created_at'].toString()) ?? DateTime.now();
                    } else if (trx['tanggal_penjualan'] != null) {
                      date = DateTime.tryParse(trx['tanggal_penjualan'].toString()) ?? DateTime.now();
                    } else if (trx['tanggal'] != null) {
                       date = DateTime.tryParse(trx['tanggal'].toString()) ?? DateTime.now();
                    }

                    final status = trx['status_bayar']?.toString() ?? trx['status']?.toString() ?? 'Unknown';
                    final isLunas = status.toLowerCase() == 'lunas';
                    final isRetur = status.toLowerCase() == 'retur';
                    
                    Color statusColor = Colors.orange.shade700;
                    Color statusBgColor = Colors.orange.shade50;
                    if (isLunas) {
                      statusColor = Colors.green.shade700;
                      statusBgColor = Colors.green.shade50;
                    } else if (isRetur) {
                      statusColor = Colors.red.shade700;
                      statusBgColor = Colors.red.shade50;
                    }

                    final total = double.tryParse(trx['total_harga']?.toString() ?? trx['total']?.toString() ?? trx['total_belanja']?.toString() ?? '0') ?? 0.0;
                    final invoice = trx['id']?.toString() ?? trx['faktur_code']?.toString() ?? trx['penjualan_code']?.toString() ?? '-';
                    final notes = trx['notes']?.toString() ?? trx['keterangan']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                             // Can navigate to detail if needed
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.receipt_long_rounded, size: 18, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              invoice,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              DateFormat('dd MMM yyyy, HH:mm').format(date),
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusBgColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: statusColor,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    notes,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total Transaksi', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                                    Text(
                                      CurrencyFormatter.format(total),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
