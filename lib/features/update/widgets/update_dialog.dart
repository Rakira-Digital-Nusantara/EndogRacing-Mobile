import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/update_provider.dart';

/// Dialog yang muncul saat ada update aplikasi tersedia.
///
/// Tampil otomatis saat app dibuka dan server Laravel
/// menginformasikan ada versi baru.
///
/// Jika [forceUpdate] = true, dialog tidak bisa ditutup
/// (user wajib update sebelum bisa menggunakan app).
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  /// Menampilkan dialog update.
  ///
  /// Contoh pemanggilan:
  /// ```dart
  /// UpdateDialog.show(context);
  /// ```
  static Future<void> show(BuildContext context) {
    final updateProvider = context.read<UpdateProvider>();
    return showDialog(
      context: context,
      // Jika force update, dialog tidak bisa ditutup dengan tap di luar
      barrierDismissible: !updateProvider.isForceUpdate,
      builder: (_) => ChangeNotifierProvider.value(
        value: updateProvider,
        child: const UpdateDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UpdateProvider>(
      builder: (context, update, _) {
        return PopScope(
          // Jika force update, tombol back juga dinonaktifkan
          canPop: !update.isForceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.system_update, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                const Text('Update Tersedia'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Versi baru
                Text(
                  'Versi ${update.updateInfo?.latestVersion ?? '-'} sudah tersedia!',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Changelog
                if (update.updateInfo?.changelog.isNotEmpty == true) ...[
                  const Text(
                    'Yang baru:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    update.updateInfo!.changelog,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                ],

                // Progress bar saat download
                if (update.isDownloading) ...[
                  LinearProgressIndicator(
                    value: update.downloadProgress,
                    backgroundColor: AppColors.divider,
                    color: AppColors.primary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mendownload... ${(update.downloadProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],

                // Error message
                if (update.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    update.errorMessage!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ],
              ],
            ),
            actions: [
              // Tombol "Nanti" (hanya muncul jika bukan force update)
              if (!update.isForceUpdate && !update.isDownloading)
                TextButton(
                  onPressed: () {
                    update.dismissUpdate();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Nanti Saja'),
                ),

              // Tombol "Update Sekarang"
              if (!update.isDownloading)
                AppButton(
                  text: 'Update Sekarang',
                  onPressed: () => update.downloadUpdate(),
                  isLoading: false,
                ),
            ],
          ),
        );
      },
    );
  }
}
