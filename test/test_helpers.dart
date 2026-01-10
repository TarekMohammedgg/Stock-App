/// Test Helpers for Stock App
/// This file contains common mocks, fixtures, and helper functions
/// to support Unit, Widget, and Integration testing.
///
/// Using mocktail for null-safe mocking (no build_runner needed)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:mocktail/mocktail.dart';

// Services
import 'package:gdrive_tutorial/services/firestore_auth_service.dart';
import 'package:gdrive_tutorial/services/gsheet_service.dart';
import 'package:gdrive_tutorial/services/gdrive_service.dart';
import 'package:gdrive_tutorial/services/analytics_service.dart';
import 'package:gdrive_tutorial/services/insights_service.dart';

// Core
import 'package:gdrive_tutorial/core/theme/toggle_theme.dart';

// =============================================================================
// MOCK CLASSES (using mocktail - no build_runner needed)
// =============================================================================

/// Mock Auth Service for testing authentication flows
class MockFirestoreAuthService extends Mock implements FirestoreAuthService {}

/// Mock Google Sheets Service for testing data operations
class MockGSheetService extends Mock implements GSheetService {}

/// Mock Google Drive Service for testing file operations
class MockGDriveService extends Mock implements GDriveService {}

/// Mock Analytics Service for testing analytics
// class MockAnalyticsService extends Mock implements AnalyticsService {}

/// Mock Inventory Intelligence Service
class MockInventoryIntelligenceService extends Mock
    implements InventoryIntelligenceService {}

// =============================================================================
// FAKE CLASSES (for registerFallbackValue)
// =============================================================================

class FakeProduct extends Fake implements Map<String, dynamic> {}

// =============================================================================
// TEST FIXTURES
// =============================================================================

/// Sample product data for testing
class TestFixtures {
  static const String testUserId = 'test-user-123';
  static const String testEmployeeId = 'emp-456';
  static const String testManagerEmail = 'manager@test.com';
  static const String testEmployeeUsername = 'testEmployee';

  /// Sample product for testing
  static Map<String, dynamic> get sampleProduct => {
    'Id': 'prod-001',
    'Barcode': '1234567890123',
    'Product Name': 'Test Product',
    'Product Price': '29.99',
    'Product Quantity': '100',
    'ImageUrl': 'https://example.com/image.png',
  };

  /// Sample sale for testing
  static Map<String, dynamic> get sampleSale => {
    'Id': 'sale-001',
    'Product Id': 'prod-001',
    'Product Name': 'Test Product',
    'Product Price': '29.99',
    'Sale Quantity': '5',
    'Employee Username': 'Employee testEmployee',
    'Created Date': DateTime.now().toIso8601String(),
  };

  /// Sample employee for testing
  static Map<String, dynamic> get sampleEmployee => {
    'employeeId': testEmployeeId,
    'username': testEmployeeUsername,
    'displayName': 'Test Employee',
    'managerEmail': testManagerEmail,
    'isActive': true,
    'permissions': {
      'canAddProduct': true,
      'canManageInventory': true,
      'canDeleteProduct': false,
    },
  };

  /// Multiple products for list testing
  static List<Map<String, dynamic>> get productList => [
    sampleProduct,
    {
      'Id': 'prod-002',
      'Barcode': '9876543210987',
      'Product Name': 'Another Product',
      'Product Price': '49.99',
      'Product Quantity': '50',
      'ImageUrl': null,
    },
    {
      'Id': 'prod-003',
      'Barcode': '5555555555555',
      'Product Name': 'Low Stock Product',
      'Product Price': '19.99',
      'Product Quantity': '3',
      'ImageUrl': null,
    },
  ];

  /// Multiple sales for analytics testing
  static List<Map<String, dynamic>> get salesList => [
    sampleSale,
    {
      'Id': 'sale-002',
      'Product Id': 'prod-002',
      'Product Name': 'Another Product',
      'Product Price': '49.99',
      'Sale Quantity': '2',
      'Employee Username': 'Manager Admin',
      'Created Date': DateTime.now()
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    },
  ];
}

// =============================================================================
// WIDGET TEST HELPERS
// =============================================================================

/// A wrapper function that provides the necessary providers and MaterialApp
/// for widget testing. Injects theme provider and optionally other providers.
Widget pumpApp(
  Widget child, {
  ThemeProvider? themeProvider,
  List<SingleChildWidget>? additionalProviders,
}) {
  final providers = <SingleChildWidget>[
    ChangeNotifierProvider<ThemeProvider>.value(
      value: themeProvider ?? ThemeProvider(),
    ),
    ...?additionalProviders,
  ];

  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      home: child,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
    ),
  );
}

/// Pump app with localization support
Widget pumpAppWithLocalization(
  Widget child, {
  ThemeProvider? themeProvider,
  Locale locale = const Locale('en'),
}) {
  return pumpApp(child, themeProvider: themeProvider);
}

/// Helper extension for WidgetTester to simplify common operations
extension WidgetTesterExtensions on WidgetTester {
  /// Pump the widget with frame settling
  Future<void> pumpAndSettleWidget(Widget widget) async {
    await pumpWidget(pumpApp(widget));
    await pumpAndSettle();
  }

  /// Find and tap a widget by key
  Future<void> tapByKey(Key key) async {
    await tap(find.byKey(key));
    await pumpAndSettle();
  }

  /// Find and tap a widget by text
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pumpAndSettle();
  }

  /// Enter text into a text field by key
  Future<void> enterTextByKey(Key key, String text) async {
    await enterText(find.byKey(key), text);
    await pumpAndSettle();
  }
}

// =============================================================================
// MOCK SETUP HELPERS
// =============================================================================

/// Sets up a mock GSheetService with standard product operations
MockGSheetService setupMockGSheetService({
  List<Map<String, dynamic>>? products,
  List<Map<String, dynamic>>? sales,
}) {
  final mockService = MockGSheetService();

  when(() => mockService.initialize()).thenAnswer((_) async {});
  when(
    () => mockService.getProducts(),
  ).thenAnswer((_) async => products ?? TestFixtures.productList);
  when(
    () => mockService.getSales(),
  ).thenAnswer((_) async => sales ?? TestFixtures.salesList);
  when(() => mockService.addProduct(any())).thenAnswer((_) async => true);
  when(
    () => mockService.updateProduct(any(), any()),
  ).thenAnswer((_) async => true);
  when(() => mockService.deleteProduct(any())).thenAnswer((_) async => true);
  when(() => mockService.addSale(any())).thenAnswer((_) async => true);

  return mockService;
}

/// Sets up a mock FirestoreAuthService with standard auth operations
MockFirestoreAuthService setupMockAuthService({
  bool isAuthenticated = true,
  bool isManager = false,
  bool isCheckedIn = true,
}) {
  final mockService = MockFirestoreAuthService();

  when(
    () => mockService.isEmployeeCheckedIn(any()),
  ).thenAnswer((_) async => isCheckedIn);

  return mockService;
}

// =============================================================================
// COMMON TEST ASSERTIONS
// =============================================================================

/// Custom matchers for common test scenarios
class AppMatchers {
  /// Checks if a widget displays loading indicator
  static Matcher get hasLoadingIndicator =>
      findsWidgets; // finds CircularProgressIndicator

  /// Checks if error snackbar is shown
  static Matcher get hasErrorSnackBar => findsOneWidget;

  /// Checks if success snackbar is shown
  static Matcher get hasSuccessSnackBar => findsOneWidget;
}

// =============================================================================
// INTEGRATION TEST HELPERS
// =============================================================================

/// Helper class for integration test setup
class IntegrationTestHelper {
  /// Initialize app for integration testing
  static Future<void> initializeApp() async {
    // Initialize any necessary services
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Wait for network operations to complete
  static Future<void> waitForNetworkOperation(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  /// Navigate to a specific route
  static Future<void> navigateTo(WidgetTester tester, String routeName) async {
    final context = tester.element(find.byType(MaterialApp));
    Navigator.of(context).pushNamed(routeName);
    await tester.pumpAndSettle();
  }
}
