import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/worker_model.dart';
import '../models/lot_model.dart';
import '../models/production_record.dart';
import '../utils/constants.dart';

/// Centralized service for all Firestore CRUD operations.
///
/// Provides real-time streams for workers, lots, and production records,
/// plus aggregated dashboard statistics.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════
  //  WORKERS
  // ═══════════════════════════════════════════════════════════

  /// Real-time stream of all workers, ordered by creation date (newest first).
  Stream<List<WorkerModel>> getWorkers() {
    return _db
        .collection(AppConstants.workersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkerModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get a single worker by ID.
  Future<WorkerModel?> getWorkerById(String id) async {
    final doc =
        await _db.collection(AppConstants.workersCollection).doc(id).get();
    if (doc.exists && doc.data() != null) {
      return WorkerModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Add a new worker to Firestore.
  Future<void> addWorker(WorkerModel worker) async {
    await _db
        .collection(AppConstants.workersCollection)
        .add(worker.toMap());
  }

  /// Update an existing worker.
  Future<void> updateWorker(WorkerModel worker) async {
    await _db
        .collection(AppConstants.workersCollection)
        .doc(worker.id)
        .update(worker.toMap());
  }

  /// Delete a worker by ID.
  Future<void> deleteWorker(String id) async {
    await _db.collection(AppConstants.workersCollection).doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════
  //  LOTS
  // ═══════════════════════════════════════════════════════════

  /// Real-time stream of all lots, ordered by date (newest first).
  Stream<List<LotModel>> getLots() {
    return _db
        .collection(AppConstants.lotsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LotModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Add a new lot entry.
  Future<void> addLot(LotModel lot) async {
    await _db.collection(AppConstants.lotsCollection).add(lot.toMap());
  }

  /// Update an existing lot.
  Future<void> updateLot(LotModel lot) async {
    await _db
        .collection(AppConstants.lotsCollection)
        .doc(lot.id)
        .update(lot.toMap());
  }

  /// Delete a lot by ID.
  Future<void> deleteLot(String id) async {
    await _db.collection(AppConstants.lotsCollection).doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════
  //  PRODUCTION RECORDS
  // ═══════════════════════════════════════════════════════════

  /// Add a new production record.
  Future<void> addProductionRecord(ProductionRecord record) async {
    await _db
        .collection(AppConstants.productionCollection)
        .add(record.toMap());
  }

  /// Get production records for a specific date.
  Stream<List<ProductionRecord>> getProductionByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(AppConstants.productionCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductionRecord.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get production records for the last N days.
  Future<List<ProductionRecord>> getProductionLastDays(int days) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final snapshot = await _db
        .collection(AppConstants.productionCollection)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ProductionRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Get production records for a specific worker.
  Future<List<ProductionRecord>> getProductionByWorker(String workerId) async {
    final snapshot = await _db
        .collection(AppConstants.productionCollection)
        .where('workerId', isEqualTo: workerId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProductionRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Get total production for a given month.
  Future<int> getMonthlyProduction(int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _db
        .collection(AppConstants.productionCollection)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['pieces'] as int?) ?? 0;
    }
    return total;
  }

  // ═══════════════════════════════════════════════════════════
  //  DASHBOARD STATISTICS
  // ═══════════════════════════════════════════════════════════

  /// Get aggregated dashboard stats.
  ///
  /// Returns a map with keys: totalWorkers, totalHelpers, todayProduction,
  /// stockBalance.
  Future<Map<String, dynamic>> getDashboardStats() async {
    // Count workers and helpers
    final workersSnapshot =
        await _db.collection(AppConstants.workersCollection).get();
    int totalWorkers = 0;
    int totalHelpers = 0;
    for (var doc in workersSnapshot.docs) {
      final role = doc.data()['role'] ?? 'Worker';
      if (role == 'Helper') {
        totalHelpers++;
      } else {
        totalWorkers++;
      }
    }

    // Today's production
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final productionSnapshot = await _db
        .collection(AppConstants.productionCollection)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    int todayProduction = 0;
    for (var doc in productionSnapshot.docs) {
      todayProduction += (doc.data()['pieces'] as int?) ?? 0;
    }

    // Stock balance (total pieces in - total pieces out across all lots)
    final lotsSnapshot =
        await _db.collection(AppConstants.lotsCollection).get();
    int totalIn = 0;
    int totalOut = 0;
    for (var doc in lotsSnapshot.docs) {
      totalIn += (doc.data()['piecesIn'] as int?) ?? 0;
      totalOut += (doc.data()['piecesOut'] as int?) ?? 0;
    }

    return {
      'totalWorkers': totalWorkers,
      'totalHelpers': totalHelpers,
      'todayProduction': todayProduction,
      'stockBalance': totalIn - totalOut,
    };
  }
}
