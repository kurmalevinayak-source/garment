import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/lot_model.dart';
import '../theme/app_colors.dart';

/// Card widget for displaying a lot entry in the lots list.
///
/// Shows lot name, date, pieces in/out, and remaining balance
/// with color-coded status indicators.
class LotCard extends StatelessWidget {
  final LotModel lot;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const LotCard({
    super.key,
    required this.lot,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Color-code remaining: green if positive, red if negative, grey if zero
    final remainingColor = lot.remaining > 0
        ? AppColors.success
        : lot.remaining < 0
            ? AppColors.error
            : AppColors.textSecondary;

    return Dismissible(
      key: Key(lot.id),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Lot Name + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        lot.lotName,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(lot.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Stats row: Pieces In | Pieces Out | Remaining
                Row(
                  children: [
                    _buildStatChip(
                      icon: Icons.arrow_downward_rounded,
                      label: 'In',
                      value: lot.piecesIn.toString(),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      icon: Icons.arrow_upward_rounded,
                      label: 'Out',
                      value: lot.piecesOut.toString(),
                      color: AppColors.error,
                    ),
                    const Spacer(),
                    // Remaining badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: remainingColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_rounded,
                            size: 16,
                            color: remainingColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${lot.remaining}',
                            style: TextStyle(
                              color: remainingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notes (if present)
                if (lot.notes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    lot.notes,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Small stat chip showing icon + label + value
  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline_rounded,
          color: Colors.white, size: 28),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lot'),
        content: Text('Are you sure you want to delete "${lot.lotName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
