import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:endog_racing/shared/widgets/notification_bell.dart';
import '../../absensi/providers/absensi_provider.dart';
import '../../home/screens/main_screen.dart';

class InputHomeScreen extends StatelessWidget {
  const InputHomeScreen({super.key});

  void _handleMenuTap(BuildContext context, String route, bool isLocked, bool isAbsenPulang) {
    if (isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAbsenPulang 
              ? 'Anda sudah Absen Pulang hari ini. Tidak dapat menginput data.'
              : 'Silakan Absen Masuk terlebih dahulu untuk menginput data.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: isAbsenPulang ? null : SnackBarAction(
            label: 'ABSEN',
            textColor: Colors.white,
            onPressed: () => context.push('/absensi'),
          ),
        ),
      );
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';
    final userFoto = context.watch<AuthProvider>().user?.foto;
    
    // Check absensi status
    final isAbsenMasuk = context.watch<AbsensiProvider>().isSudahAbsenMasukHariIni;
    final isAbsenPulang = context.watch<AbsensiProvider>().isSudahAbsenPulangHariIni;
    final isLocked = !isAbsenMasuk || isAbsenPulang;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Seragam dengan Beranda
      appBar: _buildAppBar(context, kandangName, userFoto),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Jenis Input',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pilih kategori data harian yang ingin Anda masukkan untuk $kandangName.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            if (isLocked)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isAbsenPulang 
                            ? 'Menu input data terkunci karena Anda sudah Absen Pulang hari ini.'
                            : 'Menu input data terkunci karena Anda belum Absen Masuk hari ini.',
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Card 1: Pakan Harian
            _buildMenuCard(
              icon: Icons.agriculture,
              iconBgColor: isLocked ? Colors.grey.shade400 : const Color(0xFF3B82F6), // Blue
              iconColor: Colors.white,
              title: 'Pakan Harian',
              subtitle: 'Pencatatan laporan konsumsi pakan pagi dan sore.',
              actionText: isLocked ? 'TERKUNCI' : 'INPUT DATA',
              actionColor: isLocked ? Colors.grey.shade500 : const Color(0xFF2563EB),
              bgColor: isLocked ? Colors.grey.shade200 : const Color(0xFFEFF6FF), // Light blue
              onTap: () => _handleMenuTap(context, '/input-pakan', isLocked, isAbsenPulang),
            ),
            const SizedBox(height: 16),

            // Card 2: Checklist Kebersihan
            _buildMenuCard(
              icon: Icons.cleaning_services,
              iconBgColor: isLocked ? Colors.grey.shade400 : const Color(0xFF3B82F6), // Blue
              iconColor: Colors.white,
              title: 'Checklist Kebersihan',
              subtitle: 'Pencatatan kebesihan baik harian atau mingguan.',
              actionText: isLocked ? 'TERKUNCI' : 'MULAI CHECKLIST',
              actionColor: isLocked ? Colors.grey.shade500 : const Color(0xFF2563EB),
              bgColor: isLocked ? Colors.grey.shade200 : const Color(0xFFEFF6FF), // Light blue
              onTap: () => _handleMenuTap(context, '/checklist-kebersihan', isLocked, isAbsenPulang),
            ),
            const SizedBox(height: 16),

            // Card 3: Produksi Telur
            _buildMenuCard(
              icon: Icons.egg,
              iconBgColor: isLocked ? Colors.grey.shade400 : const Color(0xFFF59E0B), // Orange
              iconColor: Colors.white,
              title: 'Produksi Telur',
              subtitle: 'Pencatatan telur utuh dan telur rusak.',
              actionText: isLocked ? 'TERKUNCI' : 'INPUT DATA',
              actionColor: isLocked ? Colors.grey.shade500 : const Color(0xFFD97706),
              bgColor: isLocked ? Colors.grey.shade200 : const Color(0xFFFFF7ED), // Light orange
              onTap: () => _handleMenuTap(context, '/input-produksi', isLocked, isAbsenPulang),
            ),
            const SizedBox(height: 16),

            // Card 4: Kematian & Afkir (Populasi)
            _buildMenuCard(
              icon: Icons.show_chart,
              iconBgColor: isLocked ? Colors.grey.shade400 : const Color(0xFFEF4444), // Red
              iconColor: Colors.white,
              title: 'Populasi',
              subtitle: 'Pencatatan jumlah ayam mati dan ayam afkir.',
              actionText: isLocked ? 'TERKUNCI' : 'INPUT DATA',
              actionColor: isLocked ? Colors.grey.shade500 : const Color(0xFFDC2626),
              bgColor: isLocked ? Colors.grey.shade200 : const Color(0xFFFEF2F2), // Light red
              onTap: () => _handleMenuTap(context, '/input-kematian', isLocked, isAbsenPulang),
            ),
            const SizedBox(height: 16),

            // Card 5: Vaksin & Obat
            _buildMenuCard(
              icon: Icons.medical_services,
              iconBgColor: isLocked ? Colors.grey.shade400 : const Color(0xFF10B981),
              iconColor: Colors.white,
              title: 'Vaksin & Obat (OVK)',
              subtitle: 'Pencatatan pemberian vaksin, vitamin, dan disinfektan.',
              actionText: isLocked ? 'TERKUNCI' : 'INPUT DATA',
              actionColor: isLocked ? Colors.grey.shade500 : const Color(0xFF059669),
              bgColor: isLocked ? Colors.grey.shade200 : const Color(0xFFECFDF5),
              onTap: () => _handleMenuTap(context, '/input-ovk', isLocked, isAbsenPulang),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String kandangName, String? userFoto) {
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
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Input Harian',
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
                  color: AppColors.primary.withOpacity(0.8),
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
            child: Container(
                width: 32.0,
                height: 32.0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: (userFoto != null && userFoto.isNotEmpty) 
                    ? NetworkImage(userFoto) 
                    : null,
                  child: (userFoto == null || userFoto.isEmpty)
                      ? const Icon(Icons.warehouse_rounded, size: 20, color: AppColors.primary)
                      : null,
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

  Widget _buildMenuCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String actionText,
    required Color actionColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  actionText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: actionColor,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 14, color: actionColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
