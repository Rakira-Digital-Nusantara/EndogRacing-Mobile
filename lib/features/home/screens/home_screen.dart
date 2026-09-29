import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../absensi/providers/absensi_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'main_screen.dart';
import '../providers/dashboard_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

import '../../update/providers/update_provider.dart';
import '../../update/widgets/update_dialog.dart';

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    // Cek status absen hari ini saat beranda dimuat
    Future.microtask(() {
      if (!mounted) return;
      context.read<AbsensiProvider>().setRole(false);
      context.read<AbsensiProvider>().checkHistoryHariIni();
      final kandangCode = context.read<AuthProvider>().kandang?.kdgCode ?? '';
      context.read<DashboardProvider>().fetchDashboardData(kandangCode);
      
      // Initialize Firebase Messaging and unread count
      final notifProvider = context.read<NotificationProvider>();
      notifProvider.initFirebaseMessaging();
      notifProvider.fetchUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final kandangName = authProvider.kandang?.kdgNama ?? 'Petugas';
    final kandangCode = authProvider.kandang?.kdgCode ?? 'KANDANG';
    final userFoto = authProvider.user?.foto;
    final unreadCount = context.watch<NotificationProvider>().unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Cool off-white
      appBar: _buildAppBar(kandangName, userFoto, unreadCount),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            if (!mounted) return;
            await context.read<DashboardProvider>().fetchDashboardData(kandangCode);
            if (!mounted) return;
            await context.read<NotificationProvider>().fetchUnreadCount();
            if (!mounted) return;
            await context.read<AbsensiProvider>().fetchHistory();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mengganti _buildHeader() dengan ucapan selamat datang
                Text(
                  'Halo, $kandangName',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ringkasan Harian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                _buildCeklistRutin(context),
                const SizedBox(height: 20),
                _buildInputDataButton(context),
                const SizedBox(height: 32),
                _buildMetrikSection(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String kandangName, String? userFoto, int unreadCount) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      title: Row(
        children: [
          Image.asset(
            'assets/images/Logo Endog Racing Hijau.png',
            width: 32, // Sedikit diperbesar karena containernya hilang
            height: 32,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Beranda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                kandangName.toUpperCase(),
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
          onTap: () {
            final mainScreen = context.findAncestorStateOfType<MainScreenState>();
            if (mainScreen != null) {
              mainScreen.changeTab(3);
            }
          },
          child: Container(
            margin: const EdgeInsets.only(right: 20, left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: (userFoto != null && userFoto.isNotEmpty) 
                ? NetworkImage(userFoto) 
                : null,
              child: (userFoto == null || userFoto.isEmpty)
                  ? const Icon(Icons.warehouse_rounded, size: 20, color: AppColors.primary)
                  : null,
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

  Widget _buildCeklistRutin(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final progressText = dashboardProvider.checklistProgress;
    final progressValue = dashboardProvider.checklistPercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB), // Cool light blue-gray
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              const Text(
                'Ceklist Rutin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0), // Cool gray-blue
                  borderRadius: BorderRadius.circular(20),
                ),
                child: dashboardProvider.isLoading
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
                      progressText,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: Color(0xFF475569),
                      ),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8E4),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            progressValue == 1.0 && progressText != '0/0 SELESAI'
                ? 'Semua tugas hari ini selesai. Kerja bagus!'
                : 'Ada tugas yang belum diselesaikan.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputDataButton(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();
    final bool isMasuk = dashboardProvider.isAbsenMasukDone;
    final bool isPulang = dashboardProvider.isAbsenPulangDone;
    
    String buttonText = 'Absen Masuk Kandang';
    if (isMasuk && !isPulang) {
      buttonText = 'Absen Pulang Kandang';
    } else if (isMasuk && isPulang) {
      buttonText = 'Absensi Hari Ini Selesai';
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (isMasuk && isPulang) ? null : () {
          // Buka layar absensi dengan meneruskan tipe yang sesuai
          context.push('/absensi', extra: {'type': (isMasuk && !isPulang) ? 'pulang' : 'masuk'});
        },
        icon: Icon(isMasuk && isPulang ? Icons.check_circle : Icons.add_a_photo, size: 20),
        label: Text(
          buttonText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: (isMasuk && isPulang) ? Colors.grey.shade400 : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildMetrikSection(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Metrik Kandang',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
                        _selectedDateRange == null
                            ? 'Hari Ini'
                            : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (_selectedDateRange != null)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDateRange = null;
                          });
                          final kdgCode = context.read<AuthProvider>().kandang?.kdgCode ?? '';
                          context.read<DashboardProvider>().setFilter(kdgCode, 'harian');
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
                final kdgCode = context.read<AuthProvider>().kandang?.kdgCode ?? '';
                final initialDateRange = _selectedDateRange ?? DateTimeRange(
                  start: DateTime.now().subtract(const Duration(days: 7)),
                  end: DateTime.now(),
                );
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2101),
                  initialDateRange: initialDateRange,
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
                    _selectedDateRange = picked;
                  });
                  final startStr = picked.start.toIso8601String().split('T')[0];
                  final endStr = picked.end.toIso8601String().split('T')[0];
                  context.read<DashboardProvider>().setFilter(kdgCode, 'custom_date');
                  context.read<DashboardProvider>().fetchDashboardData(kdgCode, startDate: startStr, endDate: endStr);
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
        Row(
          children: [
            Expanded(
              child: _buildMetrikCard(
                title: 'PAKAN TERPAKAI',
                value: dashboardProvider.isLoading ? '...' : dashboardProvider.pakanTerpakai,
                unit: 'kg',
                icon: Icons.monitor_weight_outlined,
                bgColor: const Color(0xFFEFF6FF), // Blue
                borderColor: const Color(0xFF3B82F6),
                iconColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetrikCard(
                title: 'SISA STOK PAKAN',
                value: dashboardProvider.isLoading ? '...' : dashboardProvider.sisaStokPakan,
                unit: 'kg',
                icon: Icons.inventory_2_outlined,
                bgColor: const Color(0xFFEFF6FF), // Blue
                borderColor: const Color(0xFF3B82F6),
                iconColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetrikCard(
                title: dashboardProvider.filter == 'harian' ? 'TELUR HARI INI' : 'PRODUKSI TELUR',
                value: dashboardProvider.isLoading ? '...' : dashboardProvider.telurProduksiKas,
                unit: 'Kas',
                subtitle: dashboardProvider.isLoading ? null : dashboardProvider.telurProduksiKg,
                icon: Icons.egg_outlined,
                bgColor: const Color(0xFFFFF7ED), // Orange
                borderColor: const Color(0xFFF97316),
                iconColor: const Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetrikCard(
                title: 'TELUR RUSAK',
                value: dashboardProvider.isLoading ? '...' : dashboardProvider.telurRusakKas,
                unit: 'Kas',
                subtitle: dashboardProvider.isLoading ? null : dashboardProvider.telurRusakKg,
                icon: Icons.egg_alt_outlined, 
                bgColor: const Color(0xFFFFF7ED), // Orange
                borderColor: const Color(0xFFF97316),
                iconColor: const Color(0xFFC2410C), 
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetrikCard(
                title: 'TOTAL POPULASI',
                value: dashboardProvider.isLoading ? '...' : dashboardProvider.totalPopulasi,
                unit: 'ekor',
                icon: Icons.pets_outlined, 
                bgColor: const Color(0xFFFEF2F2), // Red
                borderColor: const Color(0xFFEF4444),
                iconColor: const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetrikCard(
                title: 'KEMATIAN',
                value: dashboardProvider.isLoading ? '...' : dashboardProvider.kematian,
                unit: 'ekor',
                icon: Icons.warning_amber_rounded,
                bgColor: const Color(0xFFFEF2F2), // Red
                borderColor: const Color(0xFFEF4444),
                iconColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
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
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: borderColor != null ? Border(left: BorderSide(color: borderColor, width: 4)) : null,
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
                  maxLines: 2,
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
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
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
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

