import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class SalesNotificationDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.1),
      builder: (context) {
        final dummyNotifications = [
          {
            'title': 'Stok Telur Baru',
            'body': 'Ada tambahan stok telur Ayam Negeri sebanyak 50 kg.',
            'time': '10 menit yang lalu',
            'icon': Icons.egg_rounded,
            'color': Colors.orange,
            'isRead': false,
          },
          {
            'title': 'Target Tercapai!',
            'body': 'Selamat! Anda telah mencapai target penjualan harian hari ini.',
            'time': '1 jam yang lalu',
            'icon': Icons.emoji_events_rounded,
            'color': Colors.amber,
            'isRead': true,
          },
          {
            'title': 'Pengingat Setoran',
            'body': 'Jangan lupa untuk melakukan setoran kas besar sebelum jam 17:00.',
            'time': '2 jam yang lalu',
            'icon': Icons.account_balance_wallet_rounded,
            'color': AppColors.primary,
            'isRead': true,
          },
        ];

        return Stack(
          children: [
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 320,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Tandai Dibaca', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // List
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: dummyNotifications.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = dummyNotifications[index];
                            final isRead = item['isRead'] as bool;
                            
                            return Container(
                              color: isRead ? Colors.transparent : AppColors.primary.withValues(alpha: 0.05),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: (item['color'] as Color).withValues(alpha: 0.15),
                                  child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 20),
                                ),
                                title: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      item['body'] as String,
                                      style: TextStyle(fontSize: 11, color: isRead ? AppColors.textSecondary : AppColors.textPrimary.withValues(alpha: 0.8)),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item['time'] as String,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).pop(); // Close dialog on tap
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
