import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../models/receipt.dart';

final receiptsProvider =
    AsyncNotifierProvider<ReceiptsNotifier, List<Receipt>>(ReceiptsNotifier.new);

final totalThisMonthProvider = Provider<double>((ref) {
  final receipts = ref.watch(receiptsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return receipts
      .where((r) => r.date.year == now.year && r.date.month == now.month)
      .fold(0.0, (sum, r) => sum + r.totalAmount);
});

final receiptCountThisMonthProvider = Provider<int>((ref) {
  final receipts = ref.watch(receiptsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  return receipts
      .where((r) => r.date.year == now.year && r.date.month == now.month)
      .length;
});

final categoryTotalsProvider = Provider<Map<String, double>>((ref) {
  final receipts = ref.watch(receiptsProvider).valueOrNull ?? [];
  final now = DateTime.now();
  final thisMonth = receipts
      .where((r) => r.date.year == now.year && r.date.month == now.month);
  final totals = <String, double>{};
  for (final r in thisMonth) {
    final cat = r.category ?? 'Other';
    totals[cat] = (totals[cat] ?? 0) + r.totalAmount;
  }
  return totals;
});

class ReceiptsNotifier extends AsyncNotifier<List<Receipt>> {
  @override
  Future<List<Receipt>> build() async => _load();

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/receipts.json');
  }

  Future<List<Receipt>> _load() async {
    try {
      final file = await _file;
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as List;
        return json
            .map((e) => Receipt.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> _save(List<Receipt> receipts) async {
    final file = await _file;
    await file
        .writeAsString(jsonEncode(receipts.map((r) => r.toJson()).toList()));
  }

  Future<void> addReceipt(Receipt receipt) async {
    final current = [...(state.valueOrNull ?? []), receipt];
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> updateReceipt(Receipt updated) async {
    final current = (state.valueOrNull ?? []).map((r) {
      return r.id == updated.id ? updated : r;
    }).toList();
    state = AsyncData(current);
    await _save(current);
  }

  Future<void> deleteReceipt(String id) async {
    final current =
        (state.valueOrNull ?? []).where((r) => r.id != id).toList();
    state = AsyncData(current);
    await _save(current);
  }
}
