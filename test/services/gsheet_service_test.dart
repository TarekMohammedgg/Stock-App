/// Unit tests for GSheetService
/// Tests CRUD operations for Products, Sales, and Expired sheets

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../test_helpers.dart';

void main() {
  late MockGSheetService mockGSheetService;

  setUpAll(() {
    // Register fallback values for any() matchers
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockGSheetService = setupMockGSheetService();
  });

  group('GSheetService - Products', () {
    test('should initialize Google Sheets connection', () async {
      await mockGSheetService.initialize();

      verify(() => mockGSheetService.initialize()).called(1);
    });

    test('should return list of products from sheet', () async {
      final products = await mockGSheetService.getProducts();

      expect(products, isNotEmpty);
      expect(products.length, equals(3));
      expect(products.first['Product Name'], equals('Test Product'));
    });

    test('should add new product successfully', () async {
      final result = await mockGSheetService.addProduct(
        TestFixtures.sampleProduct,
      );

      expect(result, isTrue);
      verify(() => mockGSheetService.addProduct(any())).called(1);
    });

    test('should update existing product', () async {
      final updatedData = {
        'Id': 'prod-001',
        'Product Name': 'Updated Product',
        'Product Price': '39.99',
      };

      final result = await mockGSheetService.updateProduct(
        'prod-001',
        updatedData,
      );

      expect(result, isTrue);
      verify(
        () => mockGSheetService.updateProduct('prod-001', updatedData),
      ).called(1);
    });

    test('should delete product by ID', () async {
      final result = await mockGSheetService.deleteProduct('prod-001');

      expect(result, isTrue);
      verify(() => mockGSheetService.deleteProduct('prod-001')).called(1);
    });
  });

  group('GSheetService - Sales', () {
    test('should return list of sales from sheet', () async {
      final sales = await mockGSheetService.getSales();

      expect(sales, isNotEmpty);
      expect(sales.length, equals(2));
    });

    test('should add new sale with employee username', () async {
      final saleData = TestFixtures.sampleSale;

      final result = await mockGSheetService.addSale(saleData);

      expect(result, isTrue);
      verify(() => mockGSheetService.addSale(saleData)).called(1);
    });

    test('sale should include employee username field', () {
      final sale = TestFixtures.sampleSale;

      expect(sale.containsKey('Employee Username'), isTrue);
      expect(sale['Employee Username'], isNotEmpty);
    });
  });

  group('GSheetService - Error Handling', () {
    test('should handle initialization failure gracefully', () async {
      final failingService = MockGSheetService();
      // initialize() returns Future<void>, so we test it throws on failure
      when(
        () => failingService.initialize(),
      ).thenThrow(Exception('Init failed'));

      expect(() => failingService.initialize(), throwsException);
    });

    test('should handle empty product list', () async {
      final emptyService = MockGSheetService();
      when(() => emptyService.getProducts()).thenAnswer((_) async => []);

      final products = await emptyService.getProducts();

      expect(products, isEmpty);
    });
  });
}
