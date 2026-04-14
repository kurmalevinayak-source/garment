import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/summary_card.dart';
import '../widgets/loading_widget.dart';
import 'login_screen.dart';
import 'workers/workers_list_screen.dart';
import 'lots/lots_list_screen.dart';
import 'reports/reports_screen.dart';
import 'production/add_production_screen.dart';
import 'profile/profile_screen.dart'; // ✅ ADD THIS

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _firestoreService.getDashboardStats(); // ✅ FIXED
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Provider.of<AuthService>(context, listen: false).signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWorkers = _stats?['totalWorkers'] ?? 0;
    final totalHelpers = _stats?['totalHelpers'] ?? 0;
    final todayProduction = _stats?['todayProduction'] ?? 0;
    final stockBalance = _stats?['stockBalance'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading dashboard...')
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Overview of your garment business',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: SummaryCard(
                            title: 'Total Workers',
                            value: '${totalWorkers + totalHelpers}',
                            subtitle:
                                '$totalWorkers workers + $totalHelpers helpers',
                            icon: Icons.people_alt_rounded,
                            gradient: AppColors.cardGradient1,
                            animationDelay: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SummaryCard(
                            title: "Today's Production",
                            value: '$todayProduction',
                            subtitle: 'pieces made today',
                            icon: Icons.precision_manufacturing_rounded,
                            gradient: AppColors.cardGradient2,
                            animationDelay: 150,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    SummaryCard(
                      title: 'Stock Balance',
                      value: '$stockBalance',
                      subtitle: 'remaining pieces in stock',
                      icon: Icons.inventory_2_rounded,
                      gradient: AppColors.cardGradient3,
                      animationDelay: 300,
                    ),

                    const SizedBox(height: 32),

                    Text(
                      'Quick Access',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    _buildNavItem(
                      context,
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Add Production',
                      subtitle: 'Record daily pieces for workers',
                      color: AppColors.primary,
                      onTap: () async {
                        final added = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddProductionScreen()),
                        );
                        if (added == true) {
                          _loadStats();
                        }
                      },
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.people_alt_rounded,
                      title: 'Workers Management',
                      subtitle: 'Add, edit, and manage workers',
                      color: AppColors.workerBadge,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WorkersListScreen()),
                      ),
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.inventory_rounded,
                      title: 'Lot Management',
                      subtitle: 'Track incoming and outgoing stock',
                      color: AppColors.success,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LotsListScreen()),
                      ),
                    ),

                    _buildNavItem(
                      context,
                      icon: Icons.bar_chart_rounded,
                      title: 'Reports',
                      subtitle: 'Daily, monthly & worker performance',
                      color: AppColors.accent,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ReportsScreen()),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}