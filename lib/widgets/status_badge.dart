import 'package:material_ui/material_ui.dart';

import '../utils/expiry_logic.dart';

/// Coloured status badge: Valid (green), Expiring Soon (amber),
/// Expired (red).
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final ExpiryStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      ExpiryStatus.valid => Colors.green.shade700,
      ExpiryStatus.expiringSoon => Colors.amber.shade800,
      ExpiryStatus.expired => Colors.red.shade700,
    };
    final Color background = switch (status) {
      ExpiryStatus.valid => Colors.green.shade50,
      ExpiryStatus.expiringSoon => Colors.amber.shade50,
      ExpiryStatus.expired => Colors.red.shade50,
    };
    final IconData icon = switch (status) {
      ExpiryStatus.valid => Icons.check_circle_outline,
      ExpiryStatus.expiringSoon => Icons.warning_amber_outlined,
      ExpiryStatus.expired => Icons.error_outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            statusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
