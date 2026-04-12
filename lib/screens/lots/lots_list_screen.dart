import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/lot_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/lot_card.dart';
import '../../widgets/loading_widget.dart';
import 'add_edit_lot_screen.dart';

/// Displays a real-time list of all lots from Firestore.
///
/// Features:
/// - Live-updating list via Firestore streams
/// - Shows total stock balance in header
/// - Tap to edit a lot
/// - Swipe to delete with confirmation
/// - FAB to add new lot
class LotsListScreen extends StatelessWidget {
  const LotsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lot Management'),
      ),
      body: StreamBuilder<List<LotModel>>(
        stream: firestoreService.getLots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading lots...');
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
                    'Failed to load lots',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          final lots = snapshot.data ?? [];

          // Empty state
          if (lots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withAlpha(102),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No lots yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first lot entry',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          // Calculate total stock balance
          final totalBalance =
              lots.fold<int>(0, (sum, lot) => sum + lot.remaining);

          return Column(
            children: [
              // Header with total balance
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient4,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Stock Balance',
                          style: TextStyle(
                            color: Colors.white.withAlpha(217),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalBalance pieces',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.inventory_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // Lots count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${lots.length} lot${lots.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Lot cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: lots.length,
                  itemBuilder: (context, index) {
                    final lot = lots[index];
                    return LotCard(
                      lot: lot,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddEditLotScreen(lot: lot),
                          ),
                        );
                      },
                      onDelete: () {
                        firestoreService.deleteLot(lot.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${lot.lotName} deleted'),
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

      // Add lot FAB
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddEditLotScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Lot'),
      ),
    );
  }
}
