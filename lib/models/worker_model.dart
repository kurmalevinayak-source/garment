import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a worker or helper in the garments business.
///
/// Salary is auto-calculated as [totalPieces] × [ratePerPiece].
class WorkerModel {
  final String id;
  final String name;
  final String role; // 'Worker' or 'Helper'
  final double ratePerPiece; // Rate in ₹ per piece
  final int piecesToday; // Pieces produced today
  final int totalPieces; // Total pieces produced overall
  final DateTime createdAt;

  WorkerModel({
    required this.id,
    required this.name,
    required this.role,
    required this.ratePerPiece,
    this.piecesToday = 0,
    this.totalPieces = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Auto-calculated salary based on total pieces × rate per piece
  double get salary => totalPieces * ratePerPiece;

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'ratePerPiece': ratePerPiece,
      'piecesToday': piecesToday,
      'totalPieces': totalPieces,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a WorkerModel from Firestore document
  factory WorkerModel.fromMap(String id, Map<String, dynamic> map) {
    return WorkerModel(
      id: id,
      name: map['name'] ?? '',
      role: map['role'] ?? 'Worker',
      ratePerPiece: (map['ratePerPiece'] ?? 5.0).toDouble(),
      piecesToday: map['piecesToday'] ?? 0,
      totalPieces: map['totalPieces'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  WorkerModel copyWith({
    String? name,
    String? role,
    double? ratePerPiece,
    int? piecesToday,
    int? totalPieces,
  }) {
    return WorkerModel(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      ratePerPiece: ratePerPiece ?? this.ratePerPiece,
      piecesToday: piecesToday ?? this.piecesToday,
      totalPieces: totalPieces ?? this.totalPieces,
      createdAt: createdAt,
    );
  }
}
