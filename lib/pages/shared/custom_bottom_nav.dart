import 'package:flutter/material.dart';
import 'package:rahiq_driver/utils/colors.dart';

class CustomBottomNavItem {
  final IconData icon;
  final String label;

  CustomBottomNavItem({required this.icon, required this.label});
}

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<CustomBottomNavItem> items;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 36),
      child: Container(
        height: 85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isSelected = currentIndex == index;
            final item = items[index];

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              begin: AlignmentDirectional.topStart,
                              end: AlignmentDirectional.bottomEnd,
                              colors: [
                                Color(0xFF1A6A8F),
                                Color(0xFF1D6F94),
                                Color(0xFF217498),
                                Color(0xFF24799D),
                                Color(0xFF277EA2),
                                Color(0xFF2A83A6),
                                Color(0xFF2E89AB),
                                Color(0xFF318EB0),
                                Color(0xFF3493B5),
                                Color(0xFF3798BA),
                                Color(0xFF3B9EBE),
                                Color(0xFF3EA3C3),
                                Color(0xFF41A8C8),
                                Color(0xFF45AECD),
                                Color(0xFF48B3D2),
                              ],
                              stops: [
                                0.0,
                                0.0714,
                                0.1429,
                                0.2143,
                                0.2857,
                                0.3571,
                                0.4286,
                                0.5,
                                0.5714,
                                0.6429,
                                0.7143,
                                0.7857,
                                0.8571,
                                0.9286,
                                1.0,
                              ],
                            )
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.buttonBlueDark.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 3,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.buttonBlueDark
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
