# Siddhivinayak Garments

A professional Flutter mobile application for managing a garments business — built with **Firebase Authentication** and **Cloud Firestore**.

## ✨ Features

### 🔐 Authentication
- Email & password login via Firebase Auth
- Secure login screen with input validation
- Auto-redirect to dashboard when already logged in

### 📊 Dashboard
- **Total Workers** — workers + helpers count
- **Today's Production** — pieces made today
- **Stock Balance** — remaining pieces across all lots
- Pull-to-refresh for real-time stats

### 👥 Workers Management
- Add, edit, and delete workers
- Role assignment (Worker / Helper)
- Rate per piece & auto-calculated salary
- Daily and total piece tracking
- Swipe-to-delete with confirmation dialog

### 📦 Lot Management
- Track incoming / outgoing stock per lot
- Auto-calculated remaining balance
- Date picker, notes, and lot naming
- Real-time stock overview header

### 📈 Reports
- **Daily** — bar chart of last 7 days' production
- **Monthly** — line chart of 6-month production trend
- **Worker Performance** — ranked bar chart with salary info
- Color-coded worker/helper legend

### 🎁 Bonus Features
- ✅ Salary auto-calculation (`rate × totalPieces`)
- ✅ PDF export (worker, lot, and production reports)
- ✅ Admin-only access control (single-admin login)
- ✅ Dark & Light mode support (follows system theme)

---

## 🏗 Project Structure

```
lib/
├── main.dart                   # App entry point
├── firebase_options.dart       # Firebase config (placeholder)
├── models/
│   ├── worker_model.dart       # Worker data model
│   ├── lot_model.dart          # Lot data model
│   └── production_record.dart  # Daily production record
├── services/
│   ├── auth_service.dart       # Firebase Auth (ChangeNotifier)
│   └── firestore_service.dart  # Firestore CRUD operations
├── screens/
│   ├── splash_screen.dart      # Animated splash screen
│   ├── login_screen.dart       # Email/password login
│   ├── dashboard_screen.dart   # Main dashboard
│   ├── workers/
│   │   ├── workers_list_screen.dart
│   │   └── add_edit_worker_screen.dart
│   ├── lots/
│   │   ├── lots_list_screen.dart
│   │   └── add_edit_lot_screen.dart
│   └── reports/
│       └── reports_screen.dart # Tabbed reports with charts
├── widgets/
│   ├── summary_card.dart       # Animated gradient cards
│   ├── worker_card.dart        # Worker list item
│   ├── lot_card.dart           # Lot list item
│   ├── loading_widget.dart     # Loading spinner
│   └── custom_text_field.dart  # Reusable text input
├── theme/
│   ├── app_colors.dart         # Color palette & gradients
│   └── app_theme.dart          # Light & dark ThemeData
└── utils/
    ├── constants.dart          # Collection names & defaults
    └── pdf_generator.dart      # PDF report generation
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable, 3.11+)
- A Firebase project with **Authentication** and **Cloud Firestore** enabled
- Android Studio or VS Code with Flutter extensions

### 1. Clone & Install Dependencies
```bash
cd garment
flutter pub get
```

### 2. Configure Firebase
```bash
# Install FlutterFire CLI (if not installed)
dart pub global activate flutterfire_cli

# Connect to your Firebase project
flutterfire configure
```
This generates the real `firebase_options.dart` with your project credentials.

> ⚠️ **Important**: The included `firebase_options.dart` contains placeholder values. You **must** run `flutterfire configure` to replace them with your actual Firebase project config.

### 3. Add google-services.json (Android)
After running `flutterfire configure`, ensure `android/app/google-services.json` is present.

### 4. Enable Firebase Services
In the [Firebase Console](https://console.firebase.google.com):
1. **Authentication** → Enable **Email/Password** sign-in method
2. **Cloud Firestore** → Create database (start in test mode for development)
3. Create an admin user account via the Firebase Auth console

### 5. Run the App
```bash
flutter run
```

---

## 📱 Firestore Collections

| Collection    | Fields                                                       |
|---------------|--------------------------------------------------------------|
| `workers`     | name, role, ratePerPiece, piecesToday, totalPieces, createdAt |
| `lots`        | lotName, date, piecesIn, piecesOut, notes, createdAt          |
| `production`  | workerId, workerName, date, pieces, createdAt                 |

---

## 🎨 Tech Stack

| Category         | Technology                        |
|------------------|-----------------------------------|
| Framework        | Flutter 3.11+                     |
| Language         | Dart                              |
| Auth             | Firebase Auth                     |
| Database         | Cloud Firestore                   |
| State Management | Provider (ChangeNotifier)         |
| Charts           | fl_chart                          |
| PDF Export       | pdf + printing                    |
| Typography       | Google Fonts (Poppins)            |
| Design           | Material Design 3                 |

---

## 📄 License

This project is proprietary to Siddhivinayak Garments.
