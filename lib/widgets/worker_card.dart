import 'package:flutter/material.dart';
import '../models/worker_model.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

/// Card widget for displaying a worker in the workers list.
///
/// Shows name, role badge, salary, daily pieces, and total pieces.
/// Supports tap (edit), long-press, and swipe-to-delete gestures.
class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const WorkerCard({
    super.key,
    required this.worker,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isHelper = worker.role == AppConstants.roleHelper;

    return Dismissible(
      key: Key(worker.id),
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
            child: Row(
              children: [
                // Avatar with initials
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      isHelper ? AppColors.helperBadge : AppColors.workerBadge,
                  child: Text(
                    worker.name.isNotEmpty
                        ? worker.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Worker details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + role badge row
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              worker.name,
                              style: Theme.of(context).textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRoleBadge(isHelper),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Stats row
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          _buildStat(
                            Icons.today_rounded,
                            '${worker.piecesToday} pcs today',
                            context,
                          ),
                          _buildStat(
                            Icons.inventory_2_outlined,
                            '${worker.totalPieces} total',
                            context,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Salary column
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${AppConstants.currencySymbol}${worker.salary.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'salary',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Role badge chip (blue for Worker, orange for Helper)
  Widget _buildRoleBadge(bool isHelper) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (isHelper ? AppColors.helperBadge : AppColors.workerBadge)
            .withAlpha(38),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        worker.role,
        style: TextStyle(
          color: isHelper ? AppColors.helperBadge : AppColors.workerBadge,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Small stat chip with icon and label
  Widget _buildStat(IconData icon, String label, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Red delete background for swipe gesture
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

  /// Confirmation dialog before deleting
  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Worker'),
        content: Text('Are you sure you want to delete "${worker.name}"?'),
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
