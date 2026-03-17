import '../models/receipt.dart';

class ReceiptParser {
  static Receipt parse(String ocrText) {
    final lines = ocrText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final storeName = _extractStoreName(lines);
    final total = _extractTotal(ocrText);
    final date = _extractDate(ocrText);
    final items = _extractItems(lines);

    return Receipt(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      storeName: storeName,
      totalAmount: total,
      currency: _detectCurrency(ocrText),
      date: date ?? DateTime.now(),
      rawText: ocrText,
      items: items,
      createdAt: DateTime.now(),
    );
  }

  static String? _extractStoreName(List<String> lines) {
    // Store name is typically in the first 1-3 lines
    for (final line in lines.take(3)) {
      // Skip lines that look like dates, amounts, or addresses
      if (RegExp(r'^\d{2,4}[/\-.]').hasMatch(line)) continue;
      if (RegExp(r'^[¥$€£]').hasMatch(line)) continue;
      if (RegExp(r'^\d+[\-]\d+').hasMatch(line)) continue; // phone numbers
      if (line.length >= 2 && line.length <= 30) {
        return line;
      }
    }
    return null;
  }

  static double _extractTotal(String text) {
    // Match various total patterns
    final patterns = [
      // Japanese: 合計 ¥1,234 or 合計 1234円
      RegExp(r'(?:合計|総計|お買上|total|TOTAL|Total)\s*[¥￥]?\s*([\d,]+\.?\d*)', caseSensitive: false),
      // English: Total $12.34
      RegExp(r'(?:total|TOTAL|Total)\s*\$?\s*([\d,]+\.?\d*)', caseSensitive: false),
      // Generic: ¥1,234 or $12.34 (largest amount)
      RegExp(r'[¥￥$€£]\s*([\d,]+\.?\d*)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '');
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) return amount;
      }
    }

    // Fallback: find the largest number that looks like a price
    double maxAmount = 0;
    final allAmounts = RegExp(r'([\d,]+\.?\d*)').allMatches(text);
    for (final match in allAmounts) {
      final amountStr = match.group(1)!.replaceAll(',', '');
      final amount = double.tryParse(amountStr);
      if (amount != null && amount > maxAmount && amount < 1000000) {
        maxAmount = amount;
      }
    }
    return maxAmount;
  }

  static DateTime? _extractDate(String text) {
    // yyyy/MM/dd or yyyy-MM-dd
    final pattern1 = RegExp(r'(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})');
    final match1 = pattern1.firstMatch(text);
    if (match1 != null) {
      return DateTime.tryParse(
          '${match1.group(1)}-${match1.group(2)!.padLeft(2, '0')}-${match1.group(3)!.padLeft(2, '0')}');
    }

    // MM/dd/yyyy
    final pattern2 = RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{4})');
    final match2 = pattern2.firstMatch(text);
    if (match2 != null) {
      return DateTime.tryParse(
          '${match2.group(3)}-${match2.group(1)!.padLeft(2, '0')}-${match2.group(2)!.padLeft(2, '0')}');
    }

    return null;
  }

  static List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];
    // Look for lines with a name followed by a price
    final itemPattern = RegExp(r'^(.+?)\s+[¥￥$]?\s*([\d,]+\.?\d*)\s*$');

    for (final line in lines) {
      // Skip header/footer lines
      if (RegExp(r'(?:合計|total|小計|subtotal|tax|消費税|お釣り|change)', caseSensitive: false)
          .hasMatch(line)) {
        continue;
      }

      final match = itemPattern.firstMatch(line);
      if (match != null) {
        final name = match.group(1)!.trim();
        final priceStr = match.group(2)!.replaceAll(',', '');
        final price = double.tryParse(priceStr);
        if (price != null && price > 0 && name.length >= 2) {
          items.add(ReceiptItem(name: name, price: price));
        }
      }
    }
    return items;
  }

  static String _detectCurrency(String text) {
    if (text.contains('¥') || text.contains('￥') || text.contains('円')) {
      return 'JPY';
    }
    if (text.contains('\$')) return 'USD';
    if (text.contains('€')) return 'EUR';
    if (text.contains('£')) return 'GBP';
    return 'JPY'; // Default
  }
}
