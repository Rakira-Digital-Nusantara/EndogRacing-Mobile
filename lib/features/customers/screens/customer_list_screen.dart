import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/features/customers/screens/customer_transaction_history_screen.dart';
import 'package:endog_racing/features/customers/screens/customer_input_screen.dart';

import 'package:endog_racing/features/customers/providers/customer_provider.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';

class CustomerListScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;
  const CustomerListScreen({super.key, this.onProfileTap});
  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final customerProv = context.watch<CustomerProvider>();
    // Filter customers
    final customers = customerProv.customers.where((c) {
      final name = (c['customer_name'] ?? '').toString().toLowerCase();
      final code = (c['customer_code'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || code.contains(query);
    }).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo Endog Racing Hijau.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.egg_alt_rounded, color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Data Pelanggan', // Changed title
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'PETUGAS SALES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          const NotificationBell(),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              margin: const EdgeInsets.only(right: 20, left: 4),
              child: Container(
                width: 32.0,
                height: 32.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFE2E8F0),
                      Color(0xFFCBD5E1),
                    ],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.delivery_dining_rounded, 
                    color: const Color(0xFF64748B), 
                    size: 19.2,
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade200, height: 1.0),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CustomerInputScreen()),
          ).then((_) {
            if (context.mounted) context.read<CustomerProvider>().fetchCustomers();
          });
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: customerProv.isLoading && customerProv.customers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => customerProv.fetchCustomers(),
              child: Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Cari nama pelanggan...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                
                // List of Customers with ExpansionTile
                Expanded(
                  child: customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text('Belum ada data pelanggan', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90),
                        itemCount: customers.length,
                        itemBuilder: (context, index) {
                          final c = customers[index];
                          final code = c['customer_code']?.toString() ?? '-';
                          final name = c['customer_name']?.toString() ?? '-';
                          final address = c['address']?.toString() ?? '-';
                          final phone = c['phone']?.toString() ?? '-';
                          final piutang = double.tryParse(c['sisa_piutang']?.toString() ?? '0') ?? 0.0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: Colors.grey.shade100),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : '?', 
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                  ),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                subtitle: Text(code, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
                                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Divider(color: Colors.grey.shade100, height: 1),
                                  const SizedBox(height: 12),
                                  
                                  // Alamat & Telepon (Dummy)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade100),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                              child: const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                address,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                                              child: const Icon(Icons.phone_rounded, size: 14, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                phone,
                                                style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Detail Cards
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Sisa Piutang', style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(CurrencyFormatter.format(piutang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.orange)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CustomerInputScreen(customer: c),
                                              ),
                                            ).then((_) {
                                              if (context.mounted) context.read<CustomerProvider>().fetchCustomers();
                                            });
                                          },
                                          icon: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                                          label: const Text('Edit Data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: AppColors.primary),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => CustomerTransactionHistoryScreen(customer: c),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.history_rounded, size: 16, color: Colors.white),
                                          label: const Text('Riwayat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            elevation: 0,
                                          ),
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
              ],
            ),
          ),
    );
  }
}
