import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final String primaryButtonText;
  final String? secondaryButtonText;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.primaryButtonText = 'Kembali ke Beranda',
    this.secondaryButtonText = 'Input Data Lainnya',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFF6FAF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated Circular Check Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                ),
                child: Center(
                  child: Container(
                    width: 75,
                    height: 75,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.15),
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 30),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Waktu:', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                        Text(
                          time,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: 'JetBrainsMono',
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(height: 1, color: Colors.black12),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Berhasil', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Primary Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onPrimaryPressed,
                  icon: const Icon(Icons.home_outlined),
                  label: Text(primaryButtonText, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              
              // Secondary Button (Optional)
              if (onSecondaryPressed != null) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: onSecondaryPressed,
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryDark),
                  label: Text(
                    secondaryButtonText ?? '',
                    style: const TextStyle(fontSize: 15, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
