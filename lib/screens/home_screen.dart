import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import '../providers/receipt_provider.dart';
import '../services/receipt_parser.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);
    final totalThisMonth = ref.watch(totalThisMonthProvider);
    final countThisMonth = ref.watch(receiptCountThisMonthProvider);
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat('#,###');

    return Column(
      children: [
        Expanded(
          child: receiptsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (receipts) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Monthly summary card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '\u00a5${currencyFmt.format(totalThisMonth.round())}',
                            style: theme.textTheme.headlineLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$countThisMonth receipts',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilledButton.icon(
                                onPressed: () =>
                                    _scanReceipt(context, ref, ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Scan'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _scanReceipt(context, ref, ImageSource.gallery),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent receipts
                  if (receipts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 64,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('No receipts yet',
                                style: theme.textTheme.bodyLarge),
                            const SizedBox(height: 8),
                            Text('Scan a receipt to get started',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Text('Recent', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...receipts.reversed.take(20).map((receipt) =>
                        Dismissible(
                          key: Key(receipt.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            color: Colors.red,
                            child: const Icon(Icons.delete,
                                color: Colors.white),
                          ),
                          onDismissed: (_) {
                            ref
                                .read(receiptsProvider.notifier)
                                .deleteReceipt(receipt.id);
                          },
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                    _categoryIcon(receipt.category),
                                    color: theme
                                        .colorScheme.onPrimaryContainer),
                              ),
                              title: Text(
                                  receipt.storeName ?? 'Unknown Store'),
                              subtitle: Text(DateFormat('MM/dd')
                                  .format(receipt.date)),
                              trailing: Text(
                                '\u00a5${currencyFmt.format(receipt.totalAmount.round())}',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )),
                  ],
                ],
              );
            },
          ),
        ),
        const BannerAdWidget(),
      ],
    );
  }

  IconData _categoryIcon(String? category) {
    return switch (category) {
      'Food' => Icons.restaurant,
      'Shopping' => Icons.shopping_bag,
      'Transport' => Icons.directions_car,
      'Health' => Icons.local_hospital,
      'Entertainment' => Icons.movie,
      _ => Icons.receipt,
    };
  }

  Future<void> _scanReceipt(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);
    if (image == null) return;

    if (!context.mounted) return;
    _showProcessingDialog(context);

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizer = TextRecognizer();
      final result = await recognizer.processImage(inputImage);
      await recognizer.close();

      final receipt = ReceiptParser.parse(result.text);

      if (!context.mounted) return;
      Navigator.pop(context); // Close processing dialog

      _showReceiptDialog(context, ref, receipt);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to scan receipt: $e')),
      );
    }
  }

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Scanning receipt...'),
          ],
        ),
      ),
    );
  }

  void _showReceiptDialog(
      BuildContext context, WidgetRef ref, receipt) {
    final storeCtrl =
        TextEditingController(text: receipt.storeName ?? '');
    final amountCtrl =
        TextEditingController(text: receipt.totalAmount.toString());
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Receipt'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: storeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Total Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\u00a5',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text('Date: ${DateFormat('yyyy/MM/dd').format(receipt.date)}',
                  style: theme.textTheme.bodyMedium),
              if (receipt.items.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('${receipt.items.length} items detected',
                    style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final amount =
                  double.tryParse(amountCtrl.text) ?? receipt.totalAmount;
              final updated = receipt.copyWith(
                storeName: storeCtrl.text.isEmpty ? null : storeCtrl.text,
                totalAmount: amount,
              );
              ref.read(receiptsProvider.notifier).addReceipt(updated);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
