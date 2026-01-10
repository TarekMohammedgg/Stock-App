# Stock App Testing Strategy

## 📁 Test Directory Structure

The test structure mirrors the `lib/` folder to maintain consistency and ease of navigation:

```
test/
├── test_helpers.dart              # Common mocks, fixtures, and helpers
├── README.md                      # This documentation
│
├── core/                          # Core utility tests
│   ├── consts_test.dart
│   ├── helper_test.dart
│   ├── permission_helper_test.dart
│   ├── shared_prefs_test.dart
│   ├── secure_storage_helper_test.dart
│   └── theme/
│       ├── toggle_theme_test.dart
│       └── theme_provider_test.dart
│
├── services/                      # Service layer unit tests
│   ├── firestore_auth_service_test.dart
│   ├── gsheet_service_test.dart
│   ├── gdrive_service_test.dart
│   ├── analytics_service_test.dart
│   ├── gAi_service_test.dart
│   └── inventory_intelligence_service_test.dart
│
├── features/                      # Feature tests (unit + widget)
│   │
│   ├── authentication/
│   │   ├── presentation/
│   │   │   └── views/
│   │   │       ├── login_selection_screen_test.dart
│   │   │       ├── employee_login_screen_test.dart
│   │   │       ├── manager_login_screen_test.dart
│   │   │       ├── manager_signup_screen_test.dart
│   │   │       └── logout_screen_test.dart
│   │   └── data/
│   │       └── auth_repository_test.dart
│   │
│   ├── manager/
│   │   ├── presentation/
│   │   │   └── view/
│   │   │       ├── manager_screen_test.dart
│   │   │       └── widgets/
│   │   │           ├── allProducts_test.dart
│   │   │           ├── product_dialog_test.dart
│   │   │           ├── transactionDialog_screen_test.dart
│   │   │           ├── product_card_test.dart
│   │   │           ├── summary_card_test.dart
│   │   │           ├── quick_action_test.dart
│   │   │           ├── credential_screen_test.dart
│   │   │           ├── barcode_screen_test.dart
│   │   │           └── manager_employee_dashboard_test.dart
│   │   └── data/
│   │       └── product_repository_test.dart
│   │
│   ├── employee/
│   │   ├── presentation/
│   │   │   └── view/
│   │   │       ├── employee_screen_test.dart
│   │   │       └── widgets/
│   │   │           └── employee_attendance_test.dart
│   │   └── data/
│   │       └── employee_repository_test.dart
│   │
│   ├── analytics/
│   │   └── presentation/
│   │       └── view/
│   │           └── analytics_screen_test.dart
│   │
│   ├── calendar_view/
│   │   └── presentation/
│   │       └── view/
│   │           └── calendar_view_test.dart
│   │
│   ├── chatbot/
│   │   └── presentation/
│   │       └── views/
│   │           └── chatbot_screen_test.dart
│   │
│   ├── search_products/
│   │   └── presentation/
│   │       └── view/
│   │           └── search_items_screen_test.dart
│   │
│   ├── onboarding/
│   │   └── presentation/
│   │       └── views/
│   │           └── onboarding_screen_test.dart
│   │
│   └── geofencing/
│       └── geofencing_test.dart
│
└── integration_test/              # End-to-end integration tests
    ├── app_test.dart              # Main app integration test
    ├── auth_flow_test.dart        # Authentication flow test
    ├── manager_flow_test.dart     # Manager workflow test
    ├── employee_flow_test.dart    # Employee workflow test
    ├── sales_flow_test.dart       # Sales transaction flow test
    └── analytics_flow_test.dart   # Analytics flow test
```

---

## 🧪 Testing Layers

### 1. **Unit Tests** (`test/services/`, `test/core/`)
Test individual functions, methods, and classes in isolation.

**Focus Areas:**
- Service methods (CRUD operations)
- Helper functions
- Data transformations
- Permission logic
- Theme toggling

**Example:**
```dart
test('should add product to Google Sheets', () async {
  final mockService = MockGSheetService();
  when(mockService.addProduct(any)).thenAnswer((_) async => true);
  
  final result = await mockService.addProduct(TestFixtures.sampleProduct);
  
  expect(result, isTrue);
  verify(mockService.addProduct(any)).called(1);
});
```

### 2. **Widget Tests** (`test/features/**/presentation/`)
Test individual widgets in isolation with mocked dependencies.

**Focus Areas:**
- Widget rendering
- User interactions (tap, scroll, input)
- State changes
- Navigation triggers

**Example:**
```dart
testWidgets('shows product list correctly', (tester) async {
  await tester.pumpWidget(pumpApp(
    AllProductsScreen(),
    additionalProviders: [
      Provider<GSheetService>.value(value: setupMockGSheetService()),
    ],
  ));
  
  await tester.pumpAndSettle();
  
  expect(find.text('Test Product'), findsOneWidget);
  expect(find.byType(ProductCard), findsNWidgets(3));
});
```

### 3. **Integration Tests** (`integration_test/`)
Test complete user flows across multiple screens and services.

**Focus Areas:**
- Complete user journeys
- Real service interactions (or mocked backend)
- Navigation flows
- Data persistence

---

## ✅ Critical Flows Checklist

### 🔐 Authentication Flows
- [ ] **Manager Login** - Google Sign-In → Credential verification → Dashboard access
- [ ] **Manager Signup** - Google Sign-In → New account creation → Credential setup
- [ ] **Employee Login** - Username/Password → Validation → Employee dashboard
- [ ] **Logout Flow** - Confirm logout → Clear session → Redirect to login selection
- [ ] **Session Persistence** - App restart → Auto-login if session valid
- [ ] **Device Conflict** - Login on new device → Handle existing session

### 📦 Product Management Flows
- [ ] **Add Product** - Open dialog → Fill form → Submit → Verify in list
- [ ] **Edit Product** - Select product → Modify → Save → Verify changes
- [ ] **Delete Product** - Select product → Confirm → Verify removal
- [ ] **View All Products** - Load list → Pagination/scroll → Verify data
- [ ] **Search Product** - Enter query → Filter results → Select product
- [ ] **Barcode Scan** - Scan barcode → Load product → Add to transaction

### 💰 Sales Transaction Flows
- [ ] **Add Sale (Employee)** - Check-in → Search product → Set quantity → Submit → Verify stock update
- [ ] **Add Sale (Manager)** - Open transaction dialog → Select product → Submit → Verify
- [ ] **Multi-product Sale** - Add multiple products → Adjust quantities → Submit all
- [ ] **Employee Username Tracking** - Verify sale records include correct username

### 📊 Analytics Flows
- [ ] **Load Analytics** - Navigate → Fetch data → Display charts
- [ ] **Date Range Filter** - Select range → Update data → Verify charts
- [ ] **Most Sold Product** - Verify calculation accuracy
- [ ] **Peak Sales Time** - Verify time analysis

### 👥 Employee Management Flows
- [ ] **Create Employee** - Fill form → Submit → Verify in Firestore
- [ ] **Update Permissions** - Select employee → Modify permissions → Save
- [ ] **Employee Check-In** - Location verification → Record check-in time
- [ ] **Employee Check-Out** - Record check-out → Calculate hours

### 📅 Calendar View Flows
- [ ] **View Calendar** - Navigate → Load current month → Display data
- [ ] **Select Date** - Tap date → Load transactions for that day
- [ ] **Month Navigation** - Previous/next month → Update view

### 🤖 Chatbot Flows
- [ ] **Send Message** - Enter text → Submit → Receive AI response
- [ ] **Conversation History** - Multiple messages → Maintain context

### 🌐 Connectivity Flows
- [ ] **Offline Detection** - Lose connection → Show offline banner
- [ ] **Reconnection** - Restore connection → Hide banner → Sync data

---

## 🚀 Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
flutter test test/services/gsheet_service_test.dart
```

### Run with Coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Run Integration Tests
```bash
flutter test integration_test/
```

### Run Integration Tests on Device
```bash
flutter test integration_test/app_test.dart -d <device_id>
```

---

## 📝 Test Writing Guidelines

1. **Naming Convention**: Use descriptive names: `should_[expected_behavior]_when_[condition]`
2. **Arrange-Act-Assert**: Structure tests with clear setup, action, and verification phases
3. **Single Responsibility**: Each test should verify one behavior
4. **Use Fixtures**: Leverage `TestFixtures` for consistent test data
5. **Mock External Dependencies**: Never call real APIs in unit/widget tests
6. **Test Edge Cases**: Include null, empty, error, and boundary conditions
7. **Keep Tests Fast**: Avoid unnecessary delays; use `pumpAndSettle()` judiciously

---

## 📦 Required Dev Dependencies

Add these to `pubspec.yaml` if not already present:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
  integration_test:
    sdk: flutter
```

Then generate mocks:
```bash
dart run build_runner build --delete-conflicting-outputs
```
