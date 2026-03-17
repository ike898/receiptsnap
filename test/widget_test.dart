import 'package:flutter_test/flutter_test.dart';
import 'package:receiptsnap/models/receipt.dart';
import 'package:receiptsnap/services/receipt_parser.dart';

void main() {
  test('Receipt JSON round-trip', () {
    final receipt = Receipt(
      id: '1',
      storeName: 'Test Store',
      totalAmount: 1234.0,
      currency: 'JPY',
      date: DateTime(2024, 1, 1),
      rawText: 'Test',
      createdAt: DateTime(2024, 1, 1),
    );
    final json = receipt.toJson();
    final restored = Receipt.fromJson(json);
    expect(restored.id, '1');
    expect(restored.storeName, 'Test Store');
    expect(restored.totalAmount, 1234.0);
    expect(restored.currency, 'JPY');
  });

  test('ReceiptParser extracts total from Japanese receipt', () {
    const text = '''
セブンイレブン
2024/03/15 14:30
おにぎり 150
お茶 130
合計 ¥280
''';
    final receipt = ReceiptParser.parse(text);
    expect(receipt.totalAmount, 280.0);
    expect(receipt.storeName, 'セブンイレブン');
  });

  test('ReceiptParser extracts date', () {
    const text = '''
Store Name
2024/06/15
Total \$25.99
''';
    final receipt = ReceiptParser.parse(text);
    expect(receipt.date.year, 2024);
    expect(receipt.date.month, 6);
    expect(receipt.date.day, 15);
  });
}
