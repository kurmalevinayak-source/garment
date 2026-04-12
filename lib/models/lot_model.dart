import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a lot (batch) of garment pieces.
///
/// Tracks incoming and outgoing stock with auto-calculated remaining balance.
class LotModel {
  final String id;
  final String lotName;
  final DateTime date;
  final int piecesIn; // Pieces received
  final int piecesOut; // Pieces dispatched
  final String notes; // Optional notes
  final DateTime createdAt;

  LotModel({
    required this.id,
    required this.lotName,
    required this.date,
    required this.piecesIn,
    required this.piecesOut,
    this.notes = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Auto-calculated remaining balance
  int get remaining => piecesIn - piecesOut;

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'lotName': lotName,
      'date': Timestamp.fromDate(date),
      'piecesIn': piecesIn,
      'piecesOut': piecesOut,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Create a LotModel from Firestore document
  factory LotModel.fromMap(String id, Map<String, dynamic> map) {
    return LotModel(
      id: id,
      lotName: map['lotName'] ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      piecesIn: map['piecesIn'] ?? 0,
      piecesOut: map['piecesOut'] ?? 0,
      notes: map['notes'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create a copy with updated fields
  LotModel copyWith({
    String? lotName,
    DateTime? date,
    int? piecesIn,
    int? piecesOut,
    String? notes,
  }) {
    return LotModel(
      id: id,
      lotName: lotName ?? this.lotName,
      date: date ?? this.date,
      piecesIn: piecesIn ?? this.piecesIn,
      piecesOut: piecesOut ?? this.piecesOut,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
