import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/features/auth/providers/auth_provider.dart';
import 'package:endog_racing/core/utils/currency_formatter.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/screens/profile/sales_absensi_screen.dart';
import 'package:endog_racing/features/sales/screens/transactions/hutang_barang_screen.dart';
import 'package:endog_racing/features/notifications/providers/notification_provider.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';

class SalesDashboardScreen extends StatefulWidget {
  final VoidCallback? onProfileTap;

  const SalesDashboardScreen({super.key, this.onProfileTap});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  DateTime? _selectedDate;
  int _currentHargaPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchSalesDashboard();
      context.read<SalesProvider>().fetchRekapHarian();
      context.read<SalesProvider>().fetchSaldoBelumDisetor();
      
      // Initialize Firebase Messaging and unread count
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.initFirebaseMessaging();
      notifProvider.fetchUnreadCount();
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
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Cool off-white matching Kandang
      appBar: _buildAppBar(userFoto, unreadCount),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!mounted) return;
            final dateStr = _selectedDate?.toIso8601String().split('T')[0];
            await context.read<SalesProvider>().fetchSalesDashboard(tanggal: dateStr);
            if (!mounted) return;
            await context.read<SalesProvider>().fetchRekapHarian(tanggal: dateStr);
            if (!mounted) return;
            await context.read<SalesProvider>().fetchSaldoBelumDisetor();
            if (!mounted) return;
            await context.read<NotificationProvider>().fetchUnreadCount();
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
                              color: Colors.grey.withValues(alpha: 0.05),
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
                                  context.read<SalesProvider>().fetchRekapHarian();
                                  context.read<SalesProvider>().fetchSaldoBelumDisetor();
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
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                            });
                            final dateStr = picked.toIso8601String().split('T')[0];
                            context.read<SalesProvider>().fetchSalesDashboard(tanggal: dateStr);
                            context.read<SalesProvider>().fetchRekapHarian(tanggal: dateStr);
                            context.read<SalesProvider>().fetchSaldoBelumDisetor();
                          }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
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
                
                // Harga Hari Ini
                _buildHargaSlider(sales.dashboardData),
                const SizedBox(height: 16),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildRingkasanPenjualan(progress, totalPenjualan, terbayar, summary['belum_bayar']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRingkasanStok(
                        double.tryParse(sales.dashboardData?['stok_sales']?.toString() ?? '0') ?? 0,
                        double.tryParse(sales.dashboardData?['stok_mobil_kas']?.toString() ?? '0') ?? 0, 
                        double.tryParse(sales.dashboardData?['total_kg_terjual']?.toString() ?? '0') ?? 0,
                        double.tryParse(sales.dashboardData?['total_kas_terjual']?.toString() ?? '0') ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Input Data Button (Absensi)
                _buildPresensiButton(context, sales.dashboardData?['absensi']),
                const SizedBox(height: 16),

                // Tombol Hutang Barang
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HutangBarangScreen()),
                      );
                    },
                    icon: const Icon(Icons.sync_problem_rounded, color: Colors.orange),
                    label: const Text(
                      'Penyelesaian Hutang Barang',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.orange),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange, width: 2),
                      backgroundColor: Colors.orange.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
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
                        subtitle: 'Kg (Tumpuk)',
                        icon: Icons.warehouse_outlined,
                        bgColor: Colors.white,
                        borderColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'STOK SALES',
                        value: sales.dashboardData?['stok_sales']?.toString() ?? '0',
                        subtitle: 'Kg Siap Jual',
                        icon: Icons.local_shipping_outlined,
                        bgColor: AppColors.primary,
                        borderColor: AppColors.primary,
                        iconColor: Colors.white,
                        textColor: Colors.white,
                        subtitleColor: Colors.white70,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'TOTAL DITERIMA',
                        value: CurrencyFormatter.format(double.tryParse(sales.dashboardData?['total_diterima']?.toString() ?? '0') ?? 0),
                        unit: '',
                        icon: Icons.account_balance_wallet_outlined,
                        bgColor: Colors.white,
                        valueFontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'TOTAL DISETOR',
                        value: CurrencyFormatter.format(double.tryParse(sales.dashboardData?['total_disetor']?.toString() ?? '0') ?? 0),
                        unit: '',
                        icon: Icons.outbox_rounded,
                        bgColor: Colors.white,
                        valueFontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetrikCard(
                        title: 'SALDO DI TANGAN',
                        value: CurrencyFormatter.format(double.tryParse(sales.dashboardData?['saldo_di_tangan']?.toString() ?? '0') ?? 0),
                        unit: '',
                        icon: Icons.payments_rounded,
                        bgColor: Colors.orange.shade50,
                        borderColor: Colors.orange,
                        iconColor: Colors.orange,
                        valueFontSize: 18,
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

  PreferredSizeWidget _buildAppBar(String? userFoto, int unreadCount) {
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
        child: Container(
          color: Colors.grey.shade200,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildRingkasanPenjualan(double progress, double total, double terbayar, double belumBayar) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'PENJUALAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.orange,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
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
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(total),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Expanded(child: Text('Lunas', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.format(terbayar), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Expanded(child: Text('Belum', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.format(belumBayar), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanStok(double stokSisa, double stokSisaKas, double stokTerjual, double stokTerjualKas) {
    final totalStok = stokSisa + stokTerjual;
    final totalKas = stokSisaKas + stokTerjualKas;
    final progress = totalKas > 0 ? (stokTerjualKas / totalKas) : 0.0;
    
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'STOK MOBIL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 90,
            width: 90,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor: Colors.teal,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
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
          const SizedBox(height: 16),
          Column(
            children: [
              Text(
                '${totalKas.toStringAsFixed(0)} Kas',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '(${totalStok.toStringAsFixed(1)} Kg)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF475569),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        const Expanded(child: Text('Terjual', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${stokTerjualKas.toStringAsFixed(0)} Kas', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue), overflow: TextOverflow.ellipsis),
                    Text('(${stokTerjual.toStringAsFixed(1)} Kg)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.blue), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Expanded(child: Text('Sisa', textAlign: TextAlign.right, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 4),
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${stokSisaKas.toStringAsFixed(0)} Kas', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal), overflow: TextOverflow.ellipsis),
                    Text('(${stokSisa.toStringAsFixed(1)} Kg)', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.teal), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresensiButton(BuildContext context, dynamic absensiData) {
    bool isMasuk = false;
    bool isPulang = false;

    if (absensiData is Map) {
      isMasuk = absensiData['sudah_masuk'] == true;
      isPulang = absensiData['sudah_pulang'] == true;
    } else if (absensiData is String) {
      isMasuk = absensiData.toLowerCase() == 'masuk';
      isPulang = absensiData.toLowerCase() == 'pulang';
    }

    String btnText = 'Absen Masuk Sales';
    if (isMasuk && !isPulang) btnText = 'Absen Pulang Sales';
    if (isPulang) btnText = 'Sudah Absen Hari Ini';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: isPulang ? null : () async {
           await Navigator.push(
             context,
             MaterialPageRoute(
               builder: (context) => SalesAbsensiScreen(type: (isMasuk && !isPulang) ? 'pulang' : 'masuk'),
             ),
           );
           if (context.mounted) {
             final dateStr = _selectedDate?.toIso8601String().split('T')[0];
             context.read<SalesProvider>().fetchSalesDashboard(tanggal: dateStr);
           }
        },
        icon: const Icon(Icons.fingerprint_rounded, size: 20),
        label: Text(
          btnText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPulang ? Colors.grey.shade400 : ((isMasuk && !isPulang) ? Colors.orange : AppColors.primary),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }


  Widget _buildHargaSlider(Map<String, dynamic>? dashboardData) {
    List<dynamic> list = [];
    
    if (dashboardData != null) {
      if (dashboardData['list_harga_hari_ini'] != null && (dashboardData['list_harga_hari_ini'] as List).isNotEmpty) {
        list = dashboardData['list_harga_hari_ini'];
      }
    }

    if (list.isEmpty) {
      list = [
        {"sku_name": "Telur Utuh (Menunggu Data)", "harga": 0},
      ];
    }

    return Container(
      height: 100, // Fixed height for PageView
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: list.length,
            onPageChanged: (index) {
              setState(() {
                _currentHargaPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = list[index];
              final nama = item['sku_name']?.toString() ?? 'Harga Hari Ini';
              final harga = double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama.toUpperCase(),
                          style: const TextStyle(
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
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.show_chart_rounded, color: Colors.white, size: 24),
                    ),
                  ],
                ),
              );
            },
          ),
          if (list.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  list.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentHargaPage == index ? 12 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentHargaPage == index ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetrikCard({
    required String title,
    required String value,
    String? unit,
    String? subtitle,
    required IconData icon,
    required Color bgColor,
    Color? borderColor,
    Color? iconColor,
    Color? textColor,
    Color? subtitleColor,
    double valueFontSize = 24,
  }) {
    final effectiveTextColor = textColor ?? const Color(0xFF1E293B);
    final effectiveSubtitleColor = subtitleColor ?? Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border.all(color: borderColor) : Border.all(color: Colors.grey.shade200),
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
                      color: effectiveTextColor,
                    ),
                  ),
                ),
              ),
              if (unit != null && unit.isNotEmpty) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: effectiveSubtitleColor,
                    ),
                  ),
                ),
              ]
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: effectiveSubtitleColor,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
