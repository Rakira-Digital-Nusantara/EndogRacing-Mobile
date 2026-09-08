import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class InputHomeScreen extends StatelessWidget {
  const InputHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final kandangName = context.watch<AuthProvider>().kandang?.kdgNama ?? 'Kandang 1';
    final userFoto = context.watch<AuthProvider>().user?.foto;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Seragam dengan Beranda
      appBar: _buildAppBar(kandangName, userFoto),
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
            const SizedBox(height: 24),

            // Card 1: Pakan Harian
            _buildMenuCard(
              icon: Icons.agriculture,
              iconBgColor: const Color(0xFF3B82F6), // Blue
              iconColor: Colors.white,
              title: 'Pakan Harian',
              subtitle: 'Catat konsumsi pakan pagi dan sore, serta sisa pakan di tempat pakan.',
              actionText: 'INPUT DATA',
              actionColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF), // Light blue
              onTap: () => context.push('/input-pakan'),
            ),
            const SizedBox(height: 16),

            // Card 2: Checklist Kebersihan
            _buildMenuCard(
              icon: Icons.cleaning_services,
              iconBgColor: const Color(0xFF3B82F6), // Blue
              iconColor: Colors.white,
              title: 'Checklist Kebersihan',
              subtitle: 'Validasi SOP harian: pembersihan lorong, tirai, dan tempat minum.',
              actionText: 'MULAI CHECKLIST',
              actionColor: const Color(0xFF2563EB),
              bgColor: const Color(0xFFEFF6FF), // Light blue
              onTap: () => context.push('/checklist-kebersihan'),
            ),
            const SizedBox(height: 16),

            // Card 3: Produksi Telur
            _buildMenuCard(
              icon: Icons.egg,
              iconBgColor: const Color(0xFFF59E0B), // Orange
              iconColor: Colors.white,
              title: 'Produksi Telur',
              subtitle: 'Rekapitulasi jumlah telur utuh, retak, dan afkir harian.',
              actionText: 'INPUT DATA',
              actionColor: const Color(0xFFD97706),
              bgColor: const Color(0xFFFFF7ED), // Light orange
              onTap: () => context.push('/input-produksi'),
            ),
            const SizedBox(height: 16),

            // Card 4: Kematian & Afkir (Populasi)
            _buildMenuCard(
              icon: Icons.show_chart,
              iconBgColor: const Color(0xFFEF4444), // Red
              iconColor: Colors.white,
              title: 'Populasi',
              subtitle: 'Laporkan jumlah ayam mati (deplesi) dan ayam afkir.',
              actionText: 'INPUT DATA',
              actionColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2), // Light red
              onTap: () => context.push('/input-kematian'),
            ),
            const SizedBox(height: 16),

            // Card 5: Vaksin & Obat
            _buildMenuCard(
              icon: Icons.medical_services,
              iconBgColor: const Color(0xFFEF4444), // Red
              iconColor: Colors.white,
              title: 'Vaksin & Obat',
              subtitle: 'Pencatatan pemakaian vaksin, obat, atau vitamin harian.',
              actionText: 'INPUT PEMAKAIAN',
              actionColor: const Color(0xFFDC2626),
              bgColor: const Color(0xFFFEF2F2), // Light red
              onTap: () => context.push('/input-ovk'),
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String kandangName, String? userFoto) {
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
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Color(0xFF475569)),
          onPressed: () {},
        ),
        Container(
          margin: const EdgeInsets.only(right: 20, left: 4),
          child: CircleAvatar(
            radius: 16,
            backgroundImage: (userFoto != null && userFoto.isNotEmpty) 
              ? NetworkImage(userFoto) 
              : const NetworkImage('https://i.pravatar.cc/150?img=33'),
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
