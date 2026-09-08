import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class KandangHeaderCard extends StatelessWidget {
  final String kandangName;
  final String? subtitleText;
  final Widget? customSubtitle;
  final IconData icon;
  final Widget? trailingWidget;

  const KandangHeaderCard({
    Key? key,
    required this.kandangName,
    this.subtitleText,
    this.customSubtitle,
    this.icon = Icons.cottage_outlined,
    this.trailingWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2EF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kandangName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (customSubtitle != null)
                  customSubtitle!
                else if (subtitleText != null)
                  Text(
                    subtitleText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailingWidget != null) ...[
            const SizedBox(width: 16),
            trailingWidget!,
          ]
        ],
      ),
    );
  }
}
