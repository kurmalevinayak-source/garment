/// App-wide constants including Firestore collection names
/// and default configuration values.
class AppConstants {
  AppConstants._();

  // ─── App Info ─────────────────────────────────────────────
  static const String appName = 'Siddhivinayak Garments';
  static const String appTagline = 'Garment Business Management';

  // ─── Firestore Collection Names ───────────────────────────
  static const String workersCollection = 'workers';
  static const String lotsCollection = 'lots';
  static const String productionCollection = 'production';

  // ─── Default Values ───────────────────────────────────────
  static const double defaultRatePerPiece = 5.0; // ₹5 per piece
  static const String currencySymbol = '₹';

  // ─── Roles ────────────────────────────────────────────────
  static const String roleWorker = 'Worker';
  static const String roleHelper = 'Helper';
  static const List<String> roles = [roleWorker, roleHelper];
}
