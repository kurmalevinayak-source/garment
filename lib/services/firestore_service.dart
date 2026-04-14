import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/worker_model.dart';
import '../models/lot_model.dart';
import '../models/production_record.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ USER BASED COLLECTION
  CollectionReference<Map<String, dynamic>> _collection(String name) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not logged in");
    }
    return _db.collection('users').doc(uid).collection(name);
  }

  // ================= WORKERS =================

  Stream<List<WorkerModel>> getWorkers() {
    return _collection(AppConstants.workersCollection)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkerModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addWorker(WorkerModel worker) async {
    await _collection(AppConstants.workersCollection).add(worker.toMap());
  }

  Future<void> updateWorker(WorkerModel worker) async {
    await _collection(AppConstants.workersCollection)
        .doc(worker.id)
        .update(worker.toMap());
  }

  Future<void> deleteWorker(String id) async {
    await _collection(AppConstants.workersCollection).doc(id).delete();
  }

  // ================= LOTS =================

  Stream<List<LotModel>> getLots() {
    return _collection(AppConstants.lotsCollection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LotModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addLot(LotModel lot) async {
    await _collection(AppConstants.lotsCollection).add(lot.toMap());
  }

  Future<void> updateLot(LotModel lot) async {
    await _collection(AppConstants.lotsCollection)
        .doc(lot.id)
        .update(lot.toMap());
  }

  Future<void> deleteLot(String id) async {
    await _collection(AppConstants.lotsCollection).doc(id).delete();
  }

  // ================= PRODUCTION =================

  Future<void> addProductionRecord(ProductionRecord record) async {
    final batch = _db.batch();

    final prodRef = _collection(AppConstants.productionCollection).doc();
    batch.set(prodRef, record.toMap());

    final workerRef =
        _collection(AppConstants.workersCollection).doc(record.workerId);

    batch.update(workerRef, {
      'totalPieces': FieldValue.increment(record.pieces),
      'piecesToday': FieldValue.increment(record.pieces),
    });

    await batch.commit();
  }

  Stream<List<ProductionRecord>> getProductionByDate(DateTime date) {
    if (_auth.currentUser == null) return Stream.value([]);

    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    return _collection(AppConstants.productionCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductionRecord.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ✅ FIXED METHOD 1
  Future<List<ProductionRecord>> getProductionLastDays(int days) async {
    if (_auth.currentUser == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _collection(AppConstants.productionCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('date', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => ProductionRecord.fromMap(doc.id, doc.data()))
        .toList();
  }

  // ✅ FIXED METHOD 2
  Future<int> getMonthlyProduction(int year, int month) async {
    if (_auth.currentUser == null) return 0;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final snapshot = await _collection(AppConstants.productionCollection)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    int total = 0;

    for (var doc in snapshot.docs) {
      total += (doc.data()['pieces'] as int?) ?? 0;
    }

    return total;
  }

  // ================= DASHBOARD =================

  Future<Map<String, dynamic>> getDashboardStats() async {
    if (_auth.currentUser == null) {
      return {
        'totalWorkers': 0,
        'totalHelpers': 0,
        'todayProduction': 0,
        'stockBalance': 0,
      };
    }

    final workersSnapshot =
        await _collection(AppConstants.workersCollection).get();

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

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    final productionSnapshot =
        await _collection(AppConstants.productionCollection)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end))
            .get();

    int todayProduction = 0;

    for (var doc in productionSnapshot.docs) {
      todayProduction += (doc.data()['pieces'] as int?) ?? 0;
    }

    final lotsSnapshot =
        await _collection(AppConstants.lotsCollection).get();

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

  // ================= PROFILE =================

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .get();
    
    if (doc.exists) {
      return doc.data();
    } else {
      // Create default profile if it doesn't exist
      final defaultProfile = {
        'name': _auth.currentUser?.displayName ?? 'User',
        'email': _auth.currentUser?.email ?? '',
        'phone': _auth.currentUser?.phoneNumber ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db
          .collection('users')
          .doc(uid)
          .collection('profile')
          .doc('info')
          .set(defaultProfile);
      return defaultProfile;
    }
  }

  /// Update user profile data
  Future<void> updateUserProfile(String name, String phone) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception("User not logged in");

    await _db
        .collection('users')
        .doc(uid)
        .collection('profile')
        .doc('info')
        .update({
      'name': name,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}