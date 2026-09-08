import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/sales_provider.dart';
import '../utils/sales_notification_dialog.dart';

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
      context.read<SalesProvider>().fetchStokGudang();
    });
  }

  void _showAmbilTelurSheet() {
    final qtyCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Ambil Telur dari Gudang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 16),
              const Text('Masukkan jumlah kilogram telur yang akan ditarik dari Gudang Pusat ke mobil operasional Sales.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah (Kg)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text) ?? 0;
                  if (qty <= 0) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah harus lebih dari 0')));
                     return;
                  }
                  
                  final auth = context.read<AuthProvider>();
                  final empCode = auth.user?.empCode ?? 'EMP-001';
                  
                  // Gunakan produk dari API jika ada, atau PRD-005
                  final provider = context.read<SalesProvider>();
                  final sku = provider.products.isNotEmpty 
                      ? provider.products.first['sku'] ?? 'PRD-005'
                      : 'PRD-005';
                  
                  final payload = {
                    'emp_code': empCode,
                    'gudang_asal': 'GDG-001',
                    'gudang_tujuan': 'GDG-002', 
                    'tanggal': DateTime.now().toIso8601String().split('T')[0],
                    'details': [
                      {
                        'sku_product': sku, 
                        'qty': qty,
                      }
                    ]
                  };
                  
                  final success = await provider.submitPenarikanBarang(payload);
                  if (success && ctx.mounted) {
                     Navigator.pop(ctx);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil mengambil telur dari gudang!'), backgroundColor: Colors.green));
                     context.read<SalesProvider>().fetchStokGudang();
                  } else if (ctx.mounted) {
                     final err = context.read<SalesProvider>().error;
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Konfirmasi Ambil Telur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();
    final auth = context.watch<AuthProvider>();
    final userFoto = auth.user?.foto;

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
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF475569)),
            onPressed: () {
              SalesNotificationDialog.show(context);
            },
          ),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              margin: const EdgeInsets.only(right: 20, left: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: (userFoto != null && userFoto.isNotEmpty) 
                  ? NetworkImage(userFoto) 
                  : const NetworkImage('https://i.pravatar.cc/150?img=33'),
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
           await sales.fetchStokGudang();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStokCard(
                      title: 'STOK GUDANG',
                      value: sales.stokGudang.toStringAsFixed(0),
                      desc: 'Kg (Tumpuk)',
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
                      value: '120', // Dummy
                      desc: 'Kg Siap Jual',
                      color: AppColors.primary,
                      textColor: Colors.white,
                      icon: Icons.local_shipping_outlined,
                      borderColor: AppColors.primary,
                      iconColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      title: 'Ambil\nTelur',
                      icon: Icons.download_rounded,
                      textColor: const Color(0xFF1E293B),
                      iconColor: AppColors.primary,
                      onTap: () {
                         context.push('/sales/penarikan');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      title: 'Refund /\nRetur',
                      icon: Icons.upload_rounded,
                      textColor: const Color(0xFF1E293B),
                      iconColor: Colors.red,
                      onTap: () {
                         context.push('/sales/retur');
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
              
              // Dummy History
              _buildHistoryItem(
                title: 'Ambil Gudang',
                subtitle: 'Pusat, 06:30 AM',
                amount: '+50',
                unit: 'Kg',
                isPositive: true,
              ),
              _buildHistoryItem(
                title: 'Retur Telur',
                subtitle: 'Pecah, 17:45 PM',
                amount: '-2',
                unit: 'Kg',
                isPositive: false,
              ),
              _buildHistoryItem(
                title: 'Ambil Gudang',
                subtitle: 'Pusat, 06:15 AM',
                amount: '+45',
                unit: 'Kg',
                isPositive: true,
              ),
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
            color: (borderColor ?? Colors.black).withOpacity(0.05),
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
              color: textColor.withOpacity(0.7),
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
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title, 
                  style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
