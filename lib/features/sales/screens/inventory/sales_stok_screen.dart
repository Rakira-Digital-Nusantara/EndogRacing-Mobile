import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';

class SalesStokScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const SalesStokScreen({super.key, this.onProfileTap});

  @override
  State<SalesStokScreen> createState() => _SalesStokScreenState();
}

class _SalesStokScreenState extends State<SalesStokScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSalesDashboard();
      context.read<SalesProvider>().fetchRiwayatStokMobil();
    });
  }



  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Cool off-white matching Kandang
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
                  'Stok & Deposit',
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
      body: RefreshIndicator(
        onRefresh: () async {
           await sales.fetchSalesDashboard();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sales.dashboardData != null ? (sales.dashboardData!['rincian_stok_mobil'] is List) : true)
                ...(((sales.dashboardData?['rincian_stok_mobil'] is List && (sales.dashboardData!['rincian_stok_mobil'] as List).isNotEmpty) 
                      ? sales.dashboardData!['rincian_stok_mobil'] as List 
                      : [
                          {
                            "sku_product": "TLR-001",
                            "sku_name": "Telur Utuh (Dummy)",
                            "harga_sentral": 27000,
                            "qty_kg": 135,
                            "qty_kas": 9
                          }
                        ]).where((item) {
                          final name = item['sku_name']?.toString().toLowerCase() ?? '';
                          return !name.contains('rusak');
                        }).map((mobilItem) {
                  final sku = mobilItem['sku_product']?.toString() ?? '';
                  final nama = mobilItem['sku_name']?.toString() ?? '';
                  final hargaSentral = double.tryParse(mobilItem['harga_sentral']?.toString() ?? '0') ?? 0;
                  
                  // Cari rincian_pusat dengan sku yang sama
                  Map<String, dynamic>? pusatItem;
                  final pusatSource = (sales.dashboardData?['rincian_stok_pusat'] is List && (sales.dashboardData!['rincian_stok_pusat'] as List).isNotEmpty)
                      ? sales.dashboardData!['rincian_stok_pusat'] as List
                      : [
                          {
                            "sku_product": "TLR-001",
                            "qty_kg": 1400,
                            "qty_kas": 93
                          }
                        ];
                  
                  for (var p in pusatSource) {
                    if (p['sku_product']?.toString() == sku) {
                      pusatItem = p as Map<String, dynamic>;
                      break;
                    }
                  }

                  final mobilKg = mobilItem['qty_kg']?.toString() ?? '0';
                  final mobilKas = mobilItem['qty_kas']?.toString() ?? '0';
                  final pusatKg = pusatItem?['qty_kg']?.toString() ?? '0';
                  final pusatKas = pusatItem?['qty_kas']?.toString() ?? '0';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.egg_alt_rounded, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                nama,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStokCard(
                              title: 'STOK GUDANG',
                              value: pusatKas,
                              desc: 'Kas / Tumpuk\n($pusatKg Kg)',
                              color: Colors.white,
                              textColor: const Color(0xFF1E293B),
                              icon: Icons.warehouse_outlined,
                              borderColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStokCard(
                              title: 'STOK SALES',
                              value: mobilKas,
                              desc: 'Kas Siap Jual\n($mobilKg Kg)',
                              color: AppColors.primary,
                              textColor: Colors.white,
                              icon: Icons.local_shipping_outlined,
                              borderColor: AppColors.primary,
                              iconColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                }).toList())
              else 
                const Center(child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Data stok belum tersedia', style: TextStyle(color: Colors.grey)),
                )),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      title: 'Ambil\nTelur',
                      icon: Icons.download_rounded,
                      textColor: const Color(0xFF1E293B),
                      iconColor: AppColors.primary,
                      onTap: () async {
                         await context.push('/sales/penarikan');
                         if (context.mounted) {
                           context.read<SalesProvider>().fetchSalesDashboard();
                           context.read<SalesProvider>().fetchRiwayatStokMobil();
                         }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      title: 'Refund /\nRetur',
                      icon: Icons.upload_rounded,
                      textColor: const Color(0xFF1E293B),
                      iconColor: Colors.red,
                      onTap: () async {
                         await context.push('/sales/retur');
                         if (context.mounted) {
                           context.read<SalesProvider>().fetchSalesDashboard();
                           context.read<SalesProvider>().fetchRiwayatStokMobil();
                         }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildActionButton(
                      title: 'Lapor\nPecah',
                      icon: Icons.egg_rounded,
                      textColor: const Color(0xFF1E293B),
                      iconColor: Colors.orange,
                      onTap: () async {
                         await context.push('/sales/lapor-pecah');
                         if (context.mounted) {
                           context.read<SalesProvider>().fetchSalesDashboard();
                           context.read<SalesProvider>().fetchRiwayatStokMobil();
                         }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Riwayat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () {
                      context.push('/sales/stok-history');
                    },
                    child: const Text('LIHAT SEMUA', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              if (sales.isLoading && sales.riwayatStokMobil.isEmpty)
                const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
              else if (sales.error.isNotEmpty && sales.riwayatStokMobil.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(child: Text(sales.error, style: const TextStyle(color: Colors.red))),
                )
              else if (sales.riwayatStokMobil.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Belum ada riwayat stok', style: TextStyle(color: Colors.grey))),
                )
              else
                ...sales.riwayatStokMobil.take(3).map((item) {
                  final isPositive = (item['arah']?.toString().toUpperCase() == 'IN');
                  final labelPerubahan = item['label_perubahan']?.toString() ?? '0';
                  
                  // Extract amount and unit from label_perubahan like "+150.0 Kg"
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
                }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStokCard({
    required String title,
    required String value,
    required String desc,
    required Color color,
    required Color textColor,
    required IconData icon,
    Color? borderColor,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: (borderColor ?? Colors.black).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor ?? const Color(0xFF475569)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: iconColor ?? Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color textColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title.replaceAll('\n', ' '), 
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, 
                  color: textColor, 
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
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
            color: Colors.black.withValues(alpha: 0.02),
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
              color: color.withValues(alpha: 0.1),
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
