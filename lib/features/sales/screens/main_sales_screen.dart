import 'package:flutter/material.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import 'sales_dashboard_screen.dart';
import 'transactions/sales_history_screen.dart';
import 'inventory/sales_stok_screen.dart';
import '../../customers/screens/customer_list_screen.dart';
import 'profile/sales_profile_screen.dart';

class MainSalesScreen extends StatefulWidget {
  const MainSalesScreen({super.key});

  @override
  State<MainSalesScreen> createState() => _MainSalesScreenState();
}

class _MainSalesScreenState extends State<MainSalesScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    SalesDashboardScreen(
      onProfileTap: () {
        setState(() {
          _currentIndex = 4;
        });
      },
    ),
    SalesHistoryScreen(
      onProfileTap: () {
        setState(() {
          _currentIndex = 4;
        });
      },
    ),
    CustomerListScreen(
      onProfileTap: () {
        setState(() {
          _currentIndex = 4;
        });
      },
    ),
    SalesStokScreen(
      onProfileTap: () {
        setState(() {
          _currentIndex = 4;
        });
      },
    ),
    const SalesProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
       context.read<SalesProvider>().fetchPenjualanForm();
       context.read<SalesProvider>().fetchSalesHistory();
       context.read<SalesProvider>().fetchSalesProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
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
            color: Colors.black.withValues(alpha: 0.05),
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
              icon: _currentIndex == 1 ? Icons.receipt_long : Icons.receipt_long_outlined,
              label: 'PENJUALAN',
            ),
            _buildNavItem(
              index: 2,
              icon: _currentIndex == 2 ? Icons.people : Icons.people_outline,
              label: 'CUSTOMER',
            ),
            _buildNavItem(
              index: 3,
              icon: _currentIndex == 3 ? Icons.warehouse : Icons.warehouse_outlined,
              label: 'STOK',
            ),
            _buildNavItem(
              index: 4,
              icon: _currentIndex == 4 ? Icons.person : Icons.person_outline,
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
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2), // Slightly smaller margin to fit 5 items
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
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
                  fontSize: 9, // Slightly smaller to fit 5 tabs
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
