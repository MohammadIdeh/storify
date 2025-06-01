import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF304050),
      ),
      child: Row(
        children: [
          _buildNavItem(
            index: 0,
            icon: Icons.map_outlined,
            activeIcon: Icons.map,
            label: 'Map',
          ),
          _buildNavItem(
            index: 1,
            icon: Icons.delivery_dining_outlined,
            activeIcon: Icons.delivery_dining,
            label: 'Orders',
          ),
          _buildNavItem(
            index: 2,
            icon: Icons.history_outlined,
            activeIcon: Icons.history,
            label: 'History',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: const Color(0xFF6941C6).withOpacity(0.2),
          highlightColor: const Color(0xFF6941C6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: Icon(
                    isSelected ? activeIcon : icon,
                    color:
                        isSelected ? const Color(0xFF6941C6) : Colors.grey[400],
                    size: isSelected ? 26 : 24,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: isSelected ? 12 : 11,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color:
                        isSelected ? const Color(0xFF6941C6) : Colors.grey[400],
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
