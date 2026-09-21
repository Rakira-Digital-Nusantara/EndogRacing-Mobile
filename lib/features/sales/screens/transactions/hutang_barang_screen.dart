import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:endog_racing/core/constants/app_colors.dart';
import 'package:endog_racing/features/sales/providers/sales_provider.dart';
import 'package:endog_racing/shared/widgets/success_screen.dart';

class HutangBarangScreen extends StatefulWidget {
  const HutangBarangScreen({super.key});

  @override
  State<HutangBarangScreen> createState() => _HutangBarangScreenState();
}

class _HutangBarangScreenState extends State<HutangBarangScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesProvider>().fetchHutangBarangPending().then((_) {
        _animController.forward();
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    _animController.reset();
    await context.read<SalesProvider>().fetchHutangBarangPending();
    _animController.forward();
  }

  void _showSelesaiDialog(Map<String, dynamic> data) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack)),
          child: FadeTransition(
            opacity: animation,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(28.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header with Gradient
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          )
                        ],
                      ),
                      child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Selesaikan Hutang?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.6),
                        children: [
                          const TextSpan(text: 'Anda akan mengganti telur untuk pelanggan\n'),
                          TextSpan(
                            text: '${data['customer_name'] ?? 'Ini'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const TextSpan(text: '. Stok telur utuh di mobil Anda akan otomatis terpotong.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: Text(
                              'Batal',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context); // close dialog
                              final returCode = data['retur_code']?.toString();
                              if (returCode == null) return;
                              
                              final sales = context.read<SalesProvider>();
                              final success = await sales.submitPenyelesaianHutang(returCode, skuPengganti: "1500123");
                              
                              if (success && mounted) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => SuccessDialog(
                                    title: 'Hutang Selesai',
                                    subtitle: 'Stok telur di mobil berhasil dipotong.',
                                    time: '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')} WIB',
                                    primaryButtonText: 'Kembali',
                                    onPrimaryPressed: () {
                                      Navigator.pop(context);
                                    },
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(sales.error),
                                    backgroundColor: Colors.red.shade800,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: AppColors.primary.withOpacity(0.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Ya, Selesai', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final sales = context.watch<SalesProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Sleek grayish background
      appBar: AppBar(
        title: const Text('Hutang Barang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: sales.isLoading && sales.hutangBarangPending.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: sales.hutangBarangPending.isEmpty
                  ? _buildPremiumEmptyState()
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      itemCount: sales.hutangBarangPending.length,
                      itemBuilder: (context, index) {
                        final item = sales.hutangBarangPending[index];
                        final customerName = item['customer_name'] ?? 'Pelanggan';
                        final date = item['tanggal'] ?? '-';
                        final qty = item['total_hutang_kg'] ?? 0.0;
                        final code = item['retur_code'] ?? '';

                        // Staggered animation
                        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _animController,
                            curve: Interval((index / sales.hutangBarangPending.length).clamp(0.0, 1.0), 1.0, curve: Curves.easeOutCubic),
                          ),
                        );

                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, 50 * (1 - animation.value)),
                              child: Opacity(
                                opacity: animation.value,
                                child: child,
                              ),
                            );
                          },
                          child: _buildPremiumCard(customerName, code, date, qty, item),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildPremiumCard(String name, String code, String date, double qty, Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background element
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.access_time_filled_rounded, size: 14, color: Colors.grey.shade400),
                                const SizedBox(width: 6),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [const Color(0xFFF59E0B).withOpacity(0.15), const Color(0xFFF59E0B).withOpacity(0.05)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                        ),
                        child: Text(
                          code,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFD97706), fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Info Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                              child: const Icon(Icons.egg_alt_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Telur Pengganti',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                        Text(
                          '$qty Kg',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _showSelesaiDialog(item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Selesaikan Hutang', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glossy Illustration
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.verified_rounded, size: 70, color: Color(0xFF10B981)),
                  // Sparkles
                  Positioned(
                    top: 25,
                    right: 25,
                    child: Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade400),
                  ),
                  Positioned(
                    bottom: 30,
                    left: 25,
                    child: Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade300),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Semua Hutang Lunas!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hebat! Tidak ada pelanggan yang memiliki status retur gantung atau hutang barang saat ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
