import 'package:flutter/material.dart';
import '../app/app_constants.dart';
import 'skeleton.dart';

/// Skeleton loader that matches the OTP card design
class OTPCardSkeleton extends StatelessWidget {
  const OTPCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppConstants.elevationMedium,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.getResponsiveRadius(context)),
      ),
      child: Container(
        constraints: BoxConstraints(
          minHeight: AppConstants.getResponsiveOTPCardMinHeight(context),
        ),
        padding: EdgeInsets.all(AppConstants.getResponsiveOTPCardPadding(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row (issuer and menu)
            Row(
              children: [
                // Icon skeleton
                Skeleton(
                  height: 40,
                  width: 40,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                // Issuer text skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton(
                        height: 18,
                        width: 120,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 6),
                      Skeleton(
                        height: 14,
                        width: 80,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                // Menu icon skeleton
                Skeleton(
                  height: 24,
                  width: 24,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // OTP code skeleton
            Row(
              children: [
                Expanded(
                  child: Skeleton(
                    height: 48,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                // Copy button skeleton
                Skeleton(
                  height: 48,
                  width: 48,
                  borderRadius: BorderRadius.circular(12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar skeleton
            Skeleton(
              height: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      ),
    );
  }
}
