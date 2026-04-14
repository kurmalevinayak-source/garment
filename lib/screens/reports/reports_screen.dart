import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';
import '../../models/worker_model.dart';
import '../../models/lot_model.dart';
import '../../models/production_record.dart';
import '../../theme/app_colors.dart';
import '../../widgets/loading_widget.dart';
import '../../utils/pdf_generator.dart';
import '../../utils/constants.dart';

/// Reports screen with tabs for Daily, Monthly, and Worker Performance.
///
/// Uses fl_chart for bar and line charts.
/// Includes PDF export functionality.
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  // Data holders
  List<ProductionRecord> _last7DaysRecords = [];
  List<WorkerModel> _workers = [];
  List<LotModel> _lots = [];
  Map<int, int> _monthlyData = {}; // month -> total pieces
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load all data needed for reports
  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);

    try {
      // Last 7 days production
      _last7DaysRecords = await _firestoreService.getProductionLastDays(7);

      // Workers (for performance tab)
      final workersSnapshot = await _firestoreService.getWorkers().first;
      _workers = workersSnapshot;

      // Lots (for PDF export)
      final lotsSnapshot = await _firestoreService.getLots().first;
      _lots = lotsSnapshot;

      // Monthly data for last 6 months
      final now = DateTime.now();
      _monthlyData = {};
      for (int i = 5; i >= 0; i--) {
        final targetDate = DateTime(now.year, now.month - i, 1);
        final total = await _firestoreService.getMonthlyProduction(
            targetDate.year, targetDate.month);
        _monthlyData[5 - i] = total;
      }
    } catch (e) {
      // Silent fail — charts will show empty
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          // Export menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export PDF',
            onSelected: _handleExport,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'workers',
                child: ListTile(
                  leading: Icon(Icons.people_rounded),
                  title: Text('Worker Report'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'lots',
                child: ListTile(
                  leading: Icon(Icons.inventory_rounded),
                  title: Text('Lot Report'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'production',
                child: ListTile(
                  leading: Icon(Icons.bar_chart_rounded),
                  title: Text('Production Report'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Daily', icon: Icon(Icons.today_rounded, size: 20)),
            Tab(text: 'Monthly', icon: Icon(Icons.calendar_month_rounded, size: 20)),
            Tab(text: 'Workers', icon: Icon(Icons.people_rounded, size: 20)),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading reports...')
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDailyTab(),
                _buildMonthlyTab(),
                _buildWorkerPerformanceTab(),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DAILY TAB — Bar chart of production per day (last 7 days)
  // ═══════════════════════════════════════════════════════════
  Widget _buildDailyTab() {
    // Aggregate records by date
    final Map<String, int> dailyTotals = {};
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = DateFormat('dd/MM').format(date);
      dailyTotals[key] = 0;
    }
    for (var record in _last7DaysRecords) {
      final key = DateFormat('dd/MM').format(record.date);
      dailyTotals[key] = (dailyTotals[key] ?? 0) + record.pieces;
    }

    final entries = dailyTotals.entries.toList();
    final maxY = entries.isEmpty
        ? 100.0
        : (entries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(10.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Production',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Last 7 days',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Bar chart
          SizedBox(
            height: 280,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${entries[group.x.toInt()].key}\n${rod.toY.toInt()} pcs',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[idx].key,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: entries.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value.toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 22,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Daily breakdown list
          ...entries.map((e) => _buildDataRow(e.key, '${e.value} pieces')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  MONTHLY TAB — Line chart of monthly production trends
  // ═══════════════════════════════════════════════════════════
  Widget _buildMonthlyTab() {
    final now = DateTime.now();
    final List<FlSpot> spots = [];
    final List<String> monthLabels = [];

    for (int i = 5; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      monthLabels.add(DateFormat('MMM').format(monthDate));
      spots.add(FlSpot(
        (5 - i).toDouble(),
        (_monthlyData[5 - i] ?? 0).toDouble(),
      ));
    }

    final maxY = spots.isEmpty
        ? 100.0
        : (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3)
            .clamp(10.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Production',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Last 6 months trend',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Line chart
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        return LineTooltipItem(
                          '${monthLabels[idx]}\n${spot.y.toInt()} pcs',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < monthLabels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthLabels[idx],
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                    ),
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: const Color(0xFF11998E),
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF11998E).withAlpha(77),
                          const Color(0xFF38EF7D).withAlpha(13),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  WORKER PERFORMANCE TAB — Horizontal bar chart
  // ═══════════════════════════════════════════════════════════
  Widget _buildWorkerPerformanceTab() {
    if (_workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 48, color: AppColors.textSecondary.withAlpha(102)),
            const SizedBox(height: 16),
            Text('No worker data available',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      );
    }

    // Sort workers by total pieces (descending)
    final sorted = List<WorkerModel>.from(_workers)
      ..sort((a, b) => b.totalPieces.compareTo(a.totalPieces));
    final topWorkers = sorted.take(10).toList();

    final maxVal = topWorkers.isEmpty
        ? 100.0
        : (topWorkers.first.totalPieces * 1.2).clamp(10.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Worker Performance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Total pieces produced (top ${topWorkers.length})',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Horizontal bar chart
          SizedBox(
            height: topWorkers.length * 52.0 + 40,
            child: BarChart(
              BarChartData(
                maxY: maxVal,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final w = topWorkers[group.x.toInt()];
                      return BarTooltipItem(
                        '${w.name}\n${w.totalPieces} pcs\n${AppConstants.currencySymbol}${w.salary.toStringAsFixed(0)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < topWorkers.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              topWorkers[idx].name.length > 6
                                  ? '${topWorkers[idx].name.substring(0, 6)}.'
                                  : topWorkers[idx].name,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: topWorkers.asMap().entries.map((entry) {
                  final isHelper = entry.value.role == AppConstants.roleHelper;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.totalPieces.toDouble(),
                        gradient: LinearGradient(
                          colors: isHelper
                              ? [const Color(0xFFF97316), const Color(0xFFFBBF24)]
                              : [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 20,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Worker', AppColors.workerBadge),
              const SizedBox(width: 24),
              _buildLegend('Helper', AppColors.helperBadge),
            ],
          ),

          const SizedBox(height: 24),

          // Worker ranking list
          ...topWorkers.asMap().entries.map((entry) {
            final w = entry.value;
            return _buildRankRow(
              rank: entry.key + 1,
              name: w.name,
              role: w.role,
              value: '${w.totalPieces} pcs',
              salary: '${AppConstants.currencySymbol}${w.salary.toStringAsFixed(0)}',
            );
          }),
        ],
      ),
    );
  }

  // ─── Helper Widgets ──────────────────────────────────────

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRankRow({
    required int rank,
    required String name,
    required String role,
    required String value,
    required String salary,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: rank <= 3
            ? AppColors.accent.withAlpha(20)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: rank <= 3
            ? Border.all(color: AppColors.accent.withAlpha(77))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? AppColors.accent : Theme.of(context).colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: rank <= 3 ? AppColors.textPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(role,
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Pieces + salary
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(salary,
                  style: TextStyle(
                      fontSize: 11, color: AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  /// Handle PDF export
  void _handleExport(String type) async {
    try {
      switch (type) {
        case 'workers':
          await PdfGenerator.generateWorkerReport(_workers);
          break;
        case 'lots':
          await PdfGenerator.generateLotReport(_lots);
          break;
        case 'production':
          final Map<String, int> dailyData = {};
          for (int i = 6; i >= 0; i--) {
            final date = DateTime.now().subtract(Duration(days: i));
            final key = DateFormat('dd MMM yyyy').format(date);
            dailyData[key] = 0;
          }
          for (var record in _last7DaysRecords) {
            final key = DateFormat('dd MMM yyyy').format(record.date);
            dailyData[key] = (dailyData[key] ?? 0) + record.pieces;
          }

          final now = DateTime.now();
          final monthlyTotal = await _firestoreService.getMonthlyProduction(
              now.year, now.month);

          await PdfGenerator.generateProductionReport(
            dailyData: dailyData,
            monthlyTotal: monthlyTotal,
            monthName: DateFormat('MMMM yyyy').format(now),
          );
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
