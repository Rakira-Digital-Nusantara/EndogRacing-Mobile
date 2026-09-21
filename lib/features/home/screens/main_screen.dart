import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import 'home_screen.dart';
import '../../input/screens/input_home_screen.dart';
import '../../inventory/screens/inventory_screen.dart';

import '../../profile/screens/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void changeTab(int index) {
    if (index == 0 && _currentIndex != 0) {
      final authProvider = context.read<AuthProvider>();
      final kdgCode = authProvider.kandang?.kdgCode ?? '';
      context.read<DashboardProvider>().fetchDashboardData(kdgCode);
    }
    setState(() {
      _currentIndex = index;
    });
  }

  // Daftar halaman untuk setiap tab
  final List<Widget> _pages = [
    const HomeScreen(),
    const InputHomeScreen(), // Tab Pencatatan
    const InventoryScreen(), // Tab Inventory
    const ProfileScreen(), // Tab Akun/Profil Kandang
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              index: 0,
              icon: _currentIndex == 0 ? Icons.home : Icons.home_outlined,
              label: 'BERANDA',
            ),
            _buildNavItem(
              index: 1,
              icon: _currentIndex == 1 ? Icons.edit_document : Icons.edit_outlined, // Fallback ke edit_outlined jika edit_document tidak ada
              label: 'PENCATATAN',
            ),
            _buildNavItem(
              index: 2,
              icon: _currentIndex == 2 ? Icons.warehouse : Icons.warehouse_outlined,
              label: 'INVENTORY',
            ),
            _buildNavItem(
              index: 3,
              icon: _currentIndex == 3 ? Icons.person : Icons.person_outline,
              label: 'AKUN',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    final Color color = isSelected ? AppColors.primary : const Color(0xFF64748B); // Slate 500

    return Expanded(
      child: GestureDetector(
        onTap: () {
          changeTab(index);
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
