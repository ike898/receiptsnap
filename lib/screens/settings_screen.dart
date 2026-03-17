import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/purchase_provider.dart';
import '../services/notification_service.dart';

final _reminderEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);
    final reminderEnabled = ref.watch(_reminderEnabledProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Notifications', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            title: const Text('Receipt Reminders'),
            subtitle: const Text('Daily reminder at 9:00 PM'),
            value: reminderEnabled,
            onChanged: (value) {
              ref.read(_reminderEnabledProvider.notifier).state = value;
              if (value) {
                NotificationService.scheduleReceiptReminder(
                    hour: 21, minute: 0);
              } else {
                NotificationService.cancelAll();
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        Text('Premium', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: isPremium
                ? Row(
                    children: [
                      Icon(Icons.verified, color: Colors.amber, size: 32),
                      const SizedBox(width: 16),
                      Text('Premium Active',
                          style: theme.textTheme.titleSmall),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 32),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Upgrade to Premium',
                                    style: theme.textTheme.titleSmall),
                                Text(
                                    'No ads, AI parsing, export CSV',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant)),
                              ],
                            ),
                          ),
                          Text('\$2.99',
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                ref
                                    .read(purchaseServiceProvider)
                                    .buyPremium();
                              },
                              child: const Text('Buy'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ref
                                    .read(purchaseServiceProvider)
                                    .restorePurchases();
                              },
                              child: const Text('Restore'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text('About', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () {},
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info),
                title: Text('Version'),
                trailing: Text('1.0.0'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
