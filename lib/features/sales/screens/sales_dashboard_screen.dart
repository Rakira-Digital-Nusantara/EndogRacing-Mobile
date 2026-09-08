import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/sales_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import 'sales_absensi_screen.dart';
import '../utils/sales_notification_dialog.dart';

class SalesDashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const SalesDashboardScreen({super.key, this.onProfileTap});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSalesDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sales = context.watch<SalesProvider>();
    final summary = sales.getDashboardSummary();
    
    final totalPenjualan = summary['total_penjualan'] as double;
    final terbayar = summary['terbayar'] as double;
    final progress = totalPenjualan > 0 ? terbayar / totalPenjualan : 0.0;
    
    final salesName = auth.user?.usrLoginname ?? 'Sales Officer';
    final userFoto = auth.user?.foto;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Cool off-white matching Kandang
      appBar: _buildAppBar(userFoto),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final dateStr = _selectedDate?.toIso8601String().split('T')[0];
            await sales.fetchSalesDashboard(tanggal: dateStr);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Mirip Kandang)
                Text(
                  'Halo, $salesName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dashboard Penjualan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Filter Tanggal
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'Hari Ini'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (_selectedDate != null)
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedDate = null;
                                  });
                                  context.read<SalesProvider>().fetchSalesDashboard();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2101),
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
                        if (picked != null && context.mounted) {
                          setState(() {
                            _selectedDate = picked;
                          });
                          final dateStr = picked.toIso8601String().split('T')[0];
                          context.read<SalesProvider>().fetchSalesDashboard(tanggal: dateStr);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Harga Sentral Hari Ini
                _buildHargaSentralCard(sales.dashboardData?['harga_sentral']?.toString()),
                const SizedBox(height: 16),
                
                // Ringkasan Hari Ini
                _buildRingkasanPenjualan(progress, totalPenjualan, terbayar, summary['belum_bayar']),
                const SizedBox(height: 20),
                
                // Input Data Button (Absensi)
                _buildPresensiButton(sales.dashboardData?['absensi']?.toString()),
                const SizedBox(height: 32),
                
                // Metrik Section
                const Text(
                  'Metrik Stok & Kas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'STOK GUDANG',
                        value: sales.dashboardData?['stok_gudang']?.toString() ?? '0',
                        unit: 'kg',
                        icon: Icons.warehouse_outlined,
                        bgColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'STOK SALES',
                        value: sales.dashboardData?['stok_mobil']?.toString() ?? '0',
                        unit: 'kg',
                        icon: Icons.local_shipping_outlined,
                        bgColor: Colors.white,
                        borderColor: AppColors.primary,
                        iconColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'SUDAH SETOR',
                        value: CurrencyFormatter.format(double.tryParse(sales.dashboardData?['tagihan_lunas']?.toString() ?? '0') ?? 0),
                        unit: '',
                        icon: Icons.check_circle_outline,
                        bgColor: Colors.white,
                        valueFontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'BELUM SETOR',
                        value: CurrencyFormatter.format(double.tryParse(sales.dashboardData?['tagihan_belum_lunas']?.toString() ?? '0') ?? 0),
                        unit: '',
                        icon: Icons.warning_amber_rounded,
                        bgColor: Colors.white,
                        borderColor: Colors.orange,
                        iconColor: Colors.orange,
                        valueFontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String? userFoto) {
    return AppBar(
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
                'Pos Peternakan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'SALES OFFICER',
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
        child: Container(
          color: Colors.grey.shade200,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildRingkasanPenjualan(double progress, double total, double terbayar, double belumBayar) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL PENJUALAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Update 14:30',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(flex: (progress * 100).toInt(), child: Container(height: 6, color: AppColors.primary)),
                Expanded(flex: 100 - (progress * 100).toInt(), child: Container(height: 6, color: Colors.orange)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text(
                          'TERBAYAR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(CurrencyFormatter.format(terbayar), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text(
                          'BELUM BAYAR',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(CurrencyFormatter.format(belumBayar), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiButton(String? absensiStatus) {
    bool isMasuk = absensiStatus?.toLowerCase() == 'masuk';
    bool isPulang = absensiStatus?.toLowerCase() == 'pulang';
    String btnText = 'Absen Masuk Sales';
    if (isMasuk) btnText = 'Absen Pulang Sales';
    if (isPulang) btnText = 'Sudah Absen Hari Ini';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isPulang ? null : () {
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => SalesAbsensiScreen(type: isMasuk ? 'pulang' : 'masuk'),
             ),
           );
        },
        icon: const Icon(Icons.fingerprint_rounded, size: 20),
        label: Text(
          btnText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPulang ? Colors.grey.shade400 : (isMasuk ? Colors.orange : AppColors.primary),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }


  Widget _buildHargaSentralCard(String? hargaStr) {
    final harga = double.tryParse(hargaStr ?? '0') ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8,
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
              const Text(
                'HARGA SENTRAL HARI INI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                harga > 0 ? CurrencyFormatter.format(harga) : 'Belum Tersedia',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildMetrikCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color bgColor,
    Color? borderColor,
    Color? iconColor,
    double valueFontSize = 24,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border(left: BorderSide(color: borderColor, width: 4)) : null,
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
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
