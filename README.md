# 📦 Stock App - Inventory Management System

<p align="center">
  <img src="assets/images/stock-logo.png" alt="Stock App Logo" width="150"/>
</p>

<p align="center">
  <strong>A powerful, feature-rich inventory management application built with Flutter</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#installation">Installation</a> •
  <a href="#configuration">Configuration</a> •
  <a href="#challenges">Challenges</a>
</p>

---

## 📋 Overview

**Stock App** is a comprehensive inventory management solution designed for businesses to track products, manage sales, and analyze performance. Built with Flutter, it offers a seamless cross-platform experience with real-time data synchronization through Google Sheets and cloud backup via Google Drive.

---

## ✨ Features

### 🔐 Authentication & Security
- **Multi-role Authentication**: Separate login flows for Managers and Employees
- **Secure Credential Storage**: Using `flutter_secure_storage` for sensitive data
- **Role-based Permissions**: Granular permission control for employees
- **Device Identification**: Unique device tracking for security

### 📱 Manager Dashboard
- **Product Management**: Add, edit, delete, and view all products
- **Employee Management**: Create accounts, assign permissions, monitor activity
- **Sales Tracking**: View transaction history with detailed analytics
- **Credential Configuration**: Easy setup for Google Sheets and Drive integration

### 👨‍💼 Employee Portal
- **Quick Sales Entry**: Streamlined transaction interface
- **Barcode Scanner**: Fast product lookup via QR/barcode scanning
- **Attendance Tracking**: Geofenced check-in/check-out system
- **Product Search**: Efficient search with filters

### 📊 Analytics & Insights
- **Revenue Visualization**: Interactive charts using `fl_chart`
- **Period Comparison**: Daily, weekly, monthly, yearly analytics
- **Top Products**: Identify best-selling items
- **Sales Trends**: Track performance over time

### 🤖 AI-Powered Assistant
- **Stocky AI Chatbot**: Powered by Firebase AI (Gemini)
- **Inventory Insights**: Ask questions about your stock
- **Smart Recommendations**: AI-driven inventory suggestions

### 🌐 Connectivity & Reliability
- **Real-time Internet Monitoring**: Graceful offline handling
- **Connection Status Overlay**: Visual feedback on connectivity
- **Debounced Notifications**: Prevents false connection alerts

### 📅 Calendar View
- **Date-based Product View**: See products created on specific dates
- **Collapsible Calendar**: Smooth week/month view transitions
- **Interactive Selection**: Quick date navigation

### 🌍 Internationalization
- **Multi-language Support**: Using `easy_localization`
- **RTL Support**: Ready for Arabic and other RTL languages

### 🎨 Theming
- **Dark/Light Mode**: Seamless theme switching
- **Custom Color Schemes**: Premium, modern design aesthetic

---

## 🛠 Tech Stack

### Core Framework
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | SDK | UI Framework |
| `provider` | ^6.1.2 | State Management |

### Firebase & Backend
| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | ^4.3.0 | Firebase initialization |
| `cloud_firestore` | ^6.1.1 | NoSQL database for auth & data |
| `firebase_ai` | ^3.4.0 | AI/ML capabilities (Gemini) |

### Google Integration
| Package | Version | Purpose |
|---------|---------|---------|
| `google_sign_in` | ^7.2.0 | OAuth authentication |
| `gsheets` | ^0.5.0 | Google Sheets API integration |
| `http` | ^1.6.0 | HTTP client for Drive API |

### UI & Design
| Package | Version | Purpose |
|---------|---------|---------|
| `fl_chart` | ^0.69.2 | Beautiful, interactive charts |
| `table_calendar` | ^3.1.3 | Calendar widget |
| `cached_network_image` | ^3.4.1 | Efficient image caching |
| `animated_text_kit` | ^4.3.0 | Text animations |
| `dash_chat_2` | ^0.0.21 | Chat UI for AI assistant |
| `flutter_native_splash` | ^2.4.7 | Splash screen |
| `flutter_launcher_icons` | ^0.14.4 | App icon generation |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| `connectivity_plus` | ^6.0.0 | Network connectivity detection |
| `internet_connection_checker_plus` | ^2.0.0 | Internet access verification |
| `flutter_secure_storage` | ^9.2.2 | Secure credential storage |
| `shared_preferences` | ^2.5.3 | Local key-value storage |
| `easy_localization` | ^3.0.7 | Multi-language support |
| `flutter_dotenv` | ^6.0.0 | Environment variables |
| `geolocator` | ^14.0.2 | GPS & geofencing |
| `mobile_scanner` | ^6.0.3 | QR/Barcode scanning |
| `device_info_plus` | ^12.3.0 | Device identification |
| `path_provider` | ^2.1.5 | File system paths |
| `uuid` | ^4.5.2 | Unique ID generation |
| `synchronized` | ^3.4.0 | Thread-safe operations |
| `mime` | ^2.0.0 | MIME type detection |
| `intl` | ^0.20.2 | Internationalization utilities |

### Development
| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_lints` | ^5.0.0 | Code linting rules |
| `mocktail` | ^1.0.3 | Mocking for tests |

---

## 📥 Installation

### Prerequisites
- Flutter SDK ^3.8.1
- Android Studio / VS Code
- Google Cloud Console project (for Sheets/Drive)
- Firebase project

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/stock_app.git
   cd stock_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Create a `.env` file in the root directory:
   ```env
      GSHEET_CREDENTIALS
  ```

4. **Firebase Setup**
   - Add `google-services.json` (Android) to `android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `ios/Runner/`

5. **Run the app**
   ```bash
   flutter run
   ```

---

## ⚙️ Configuration

### Required Credentials
After logging in as a Manager, you'll need to configure:

| Credential | Description |
|------------|-------------|
| **Spreadsheet ID** | Google Sheets ID for data storage |
| **Drive Folder ID** | Google Drive folder for backups |
| **App Script URL** | Google Apps Script deployment URL |

### Google Cloud Setup
1. Enable Google Sheets API
2. Enable Google Drive API
3. Create OAuth 2.0 credentials
4. Add authorized redirect URIs

---

## 🏆 Challenges Overcome

### 1. **State Management Architecture**
- **Challenge**: Migrating from GetX to Provider/Bloc for cleaner architecture
- **Solution**: Implemented a hybrid approach using `Provider` for global state and local `StatefulWidget` for UI-specific state

### 2. **Google OAuth Token Management**
- **Challenge**: Handling token refresh and silent authentication with `google_sign_in` v7
- **Solution**: Implemented token refresh logic with race condition prevention using `_isRefreshing` flags

### 3. **Internet Connectivity Handling**
- **Challenge**: False-positive connection notifications on app startup
- **Solution**: Implemented debounced status broadcasting with 3-second initialization delay

### 4. **Secure Credential Storage**
- **Challenge**: Migrating from `shared_preferences` to encrypted storage
- **Solution**: Created `SecureStorageHelper` wrapper around `flutter_secure_storage`

### 5. **Role-based Access Control**
- **Challenge**: Implementing granular permissions for employees
- **Solution**: Created `PermissionHelper` with cached permission checks and Firestore sync

### 6. **Calendar Animation**
- **Challenge**: Smooth week-to-month calendar transitions
- **Solution**: Custom animated height transitions with scroll-based collapse/expand

### 7. **AI Integration**
- **Challenge**: Providing context-aware AI responses about inventory
- **Solution**: Injecting product and sales data as context to Firebase AI prompts

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── consts.dart              # App-wide constants
│   ├── helper.dart              # Utility functions
│   ├── internet_connection_helper.dart
│   ├── permission_helper.dart
│   ├── secure_storage_helper.dart
│   ├── shared_prefs.dart
│   ├── theme/                   # Theme configuration
│   └── widgets/                 # Reusable widgets
├── features/
│   ├── analytics/               # Analytics dashboard
│   ├── authentication/          # Login, signup, logout
│   ├── calendar_view/           # Date-based product view
│   ├── chatbot/                 # AI assistant
│   ├── employee/                # Employee portal
│   ├── geofencing/              # Location-based features
│   ├── manager/                 # Manager dashboard
│   ├── onboarding/              # First-time user experience
│   └── search_products/         # Product search
├── services/
│   ├── analytics_service.dart
│   ├── firestore_auth_service.dart
│   ├── gAi_service.dart
│   ├── gdrive_service.dart
│   ├── gsheet_service.dart
│   └── inventory_intelligence_service.dart
├── firebase_options.dart
└── main.dart
```

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Tarek Mohammed**
- GitHub: [@TarekMohammedgg](https://github.com/TarekMohammedgg)
- LinkedIn: [@tarekmohammed](linkedin.com/in/tarekmohammed)

---

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- Firebase for backend services
- Google for Sheets/Drive API

---

<p align="center">
  Made with ❤️ using Flutter
</p>
