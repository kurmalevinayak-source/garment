import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/worker_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/worker_card.dart';
import '../../widgets/loading_widget.dart';
import 'add_edit_worker_screen.dart';

/// Displays a real-time list of all workers from Firestore.
///
/// Features:
/// - Live-updating list via Firestore streams
/// - Tap to edit a worker
/// - Swipe to delete with confirmation
/// - FAB to add new worker
class WorkersListScreen extends StatelessWidget {
  const WorkersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workers'),
      ),
      body: StreamBuilder<List<WorkerModel>>(
        stream: firestoreService.getWorkers(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading workers...');
          }

          // Error state
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load workers',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final workers = snapshot.data ?? [];

          // Empty state
          if (workers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 64,
                    color: AppColors.textSecondary.withAlpha(102),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No workers yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first worker',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // ── Worker list ──────────────────────────────────
          return Column(
            children: [
              // Header with count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${workers.length} worker${workers.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    // Total salary badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total: ₹${workers.fold<double>(0, (sum, w) => sum + w.salary).toStringAsFixed(0)}',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Worker cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return WorkerCard(
                      worker: worker,
                      onTap: () {
                        // Navigate to edit screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                AddEditWorkerScreen(worker: worker),
                          ),
                        );
                      },
                      onDelete: () {
                        firestoreService.deleteWorker(worker.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${worker.name} deleted'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      // Add worker FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditWorkerScreen(),
            ),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Worker'),
      ),
    );
  }
}
