import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/receipt_provider.dart';
import '../widgets/banner_ad_widget.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsProvider);
    final totalThisMonth = ref.watch(totalThisMonthProvider);
    final countThisMonth = ref.watch(receiptCountThisMonthProvider);
    final categoryTotals = ref.watch(categoryTotalsProvider);
    final theme = Theme.of(context);
    final currencyFmt = NumberFormat('#,###');

    return receiptsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (receipts) {
        if (receipts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 64,
                    color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Scan receipts to see stats',
                    style: theme.textTheme.bodyLarge),
              ],
            ),
          );
        }

        final avgPerReceipt =
            countThisMonth > 0 ? totalThisMonth / countThisMonth : 0.0;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      _StatCard(
                          title: 'This Month',
                          value:
                              '\u00a5${currencyFmt.format(totalThisMonth.round())}',
                          theme: theme),
                      const SizedBox(width: 8),
                      _StatCard(
                          title: 'Receipts',
                          value: '$countThisMonth',
                          theme: theme),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatCard(
                          title: 'Average',
                          value:
                              '\u00a5${currencyFmt.format(avgPerReceipt.round())}',
                          theme: theme),
                      const SizedBox(width: 8),
                      _StatCard(
                          title: 'Total All',
                          value: '${receipts.length}',
                          theme: theme),
                    ],
                  ),
                  if (categoryTotals.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('By Category', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    ...(categoryTotals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                        .map((e) {
                      final ratio = totalThisMonth > 0
                          ? (e.value / totalThisMonth).clamp(0.0, 1.0)
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 80,
                                child: Text(e.key,
                                    style: theme.textTheme.bodySmall)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor:
                                    theme.colorScheme.surfaceContainerHighest,
                                color: theme.colorScheme.primary,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 80,
                              child: Text(
                                  '\u00a5${currencyFmt.format(e.value.round())}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const BannerAdWidget(),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final ThemeData theme;

  const _StatCard(
      {required this.title, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
