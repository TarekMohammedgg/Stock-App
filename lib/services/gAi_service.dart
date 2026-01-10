import 'dart:convert';
import 'dart:developer';
import 'package:firebase_ai/firebase_ai.dart';

abstract class GoogleAiService {
  static Future<String> generateText({
    String? notes,
    List<dynamic>? allProducts,
    List<dynamic>? allSales,
  }) async {
    final model = FirebaseAI.googleAI().generativeModel(
      model: "gemini-2.5-flash",
    );

    // Sanitize data to convert Excel serial dates to readable strings
    final sanitizedProducts = _sanitizeData(allProducts);
    final sanitizedSales = _sanitizeData(allSales);

    final productsJson = jsonEncode(sanitizedProducts);
    log("json product: $productsJson");
    final salesJson = jsonEncode(sanitizedSales);
    log("json sales: $salesJson");

    final roles =
        '''
### ROLE
You are a helpful Inventory Assistant.

### DATA
[PRODUCTS_START]
$productsJson
[PRODUCTS_END]

[SALES_START]
$salesJson
[SALES_END]

### STRICT OUTPUT RULES
1. **Direct Answer Only:** Do NOT explain your calculation steps, formulas, or how you found the ID.
2. **No Fluff:** Do not say "Based on the logs..." or "The analysis shows...". Just say the answer.
3. **ID Supremacy:** Link Sales to Products by ID.
4. **Dates:** Ensure all dates are in human readable format (e.g., "Jan 2, 2026").
5. **Tone:** Friendly, precise, and professional.

### EXAMPLES
User: "How many Pens do we have?"
Bad Response: "I checked the logs for ID 8da4... and found two entries. 1995 + 2000 equals 3995."
Good Response: "You currently have 3,995 Pens in stock."

### USER QUESTION
$notes
''';

    final textPart = TextPart(roles);
    final List<Part> parts = [textPart];
    final prompt = Content.multi(parts);

    final response = await model.generateContent([prompt]);
    final result = response.text?.trim() ?? "Unable to calculate.";

    return result;
  }

  static List<Map<String, dynamic>> _sanitizeData(List<dynamic>? data) {
    if (data == null) return [];
    return data.map((item) {
      if (item is Map) {
        final newItem = Map<String, dynamic>.from(item);
        newItem.forEach((key, value) {
          if (key.toString().toLowerCase().contains('date')) {
            newItem[key] = _convertIfExcelDate(value);
          }
        });
        return newItem;
      }
      return <String, dynamic>{};
    }).toList();
  }

  static dynamic _convertIfExcelDate(dynamic value) {
    if (value == null) return value;
    double? serial;
    if (value is num) {
      serial = value.toDouble();
    } else if (value is String) {
      serial = double.tryParse(value);
    }

    // Excel dates are usually between 30000 (1982) and 60000 (2064)
    if (serial != null && serial > 30000 && serial < 60000) {
      final date = DateTime(
        1899,
        12,
        30,
      ).add(Duration(milliseconds: (serial * 24 * 60 * 60 * 1000).round()));
      return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    }
    return value;
  }
}
