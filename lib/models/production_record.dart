import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a daily production record for a worker.
///
/// Used for generating daily/monthly reports and worker performance charts.
class ProductionRecord {
  final String id;
  final String workerId;
  final String workerName;
  final DateTime date;
  final int pieces; // Pieces produced on this date
  final DateTime createdAt;

  ProductionRecord({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.pieces,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'workerId': workerId,
      'workerName': workerName,
      'date': Timestamp.fromDate(date),
      'pieces': pieces,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a ProductionRecord from Firestore document
  factory ProductionRecord.fromMap(String id, Map<String, dynamic> map) {
    return ProductionRecord(
      id: id,
      workerId: map['workerId'] ?? '',
      workerName: map['workerName'] ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      pieces: map['pieces'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
