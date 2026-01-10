import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class NumberTextInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter =
      NumberFormat.decimalPattern('en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // remove commas
    final text = newValue.text.replaceAll(',', '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(text);
    final newText = _formatter.format(number);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: newText.length,
      ),
    );
  }
}
