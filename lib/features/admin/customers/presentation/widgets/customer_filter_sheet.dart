import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/customer_provider.dart';

class CustomerFilterSheet extends ConsumerWidget {
  const CustomerFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(customerStatusFilterProvider);
    final packageFilter = ref.watch(customerPackageFilterProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Pelanggan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(customerStatusFilterProvider.notifier).state = 'all';
                    ref.read(customerPackageFilterProvider.notifier).state = 'all';
                    ref.read(customerPageProvider.notifier).state = 1;
                    Navigator.pop(context);
                  },
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          const Divider(),
          // Status Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip(
                      context,
                      ref,
                      label: 'Semua',
                      value: 'all',
                      currentValue: statusFilter,
                      onSelected: (value) {
                        ref.read(customerStatusFilterProvider.notifier).state = value;
                        ref.read(customerPageProvider.notifier).state = 1;
                      },
                    ),
                    _buildFilterChip(
                      context,
                      ref,
                      label: 'Aktif',
                      value: 'AKTIF',
                      currentValue: statusFilter,
                      color: AppColors.success,
                      onSelected: (value) {
                        ref.read(customerStatusFilterProvider.notifier).state = value;
                        ref.read(customerPageProvider.notifier).state = 1;
                      },
                    ),
                    _buildFilterChip(
                      context,
                      ref,
                      label: 'Nonaktif',
                      value: 'NONAKTIF',
                      currentValue: statusFilter,
                      color: AppColors.danger,
                      onSelected: (value) {
                        ref.read(customerStatusFilterProvider.notifier).state = value;
                        ref.read(customerPageProvider.notifier).state = 1;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          // Apply Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Terapkan Filter'),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String value,
    required String currentValue,
    Color? color,
    required Function(String) onSelected,
  }) {
    final isSelected = currentValue == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onSelected(value),
      selectedColor: color?.withOpacity(0.2) ?? AppColors.primary.withOpacity(0.2),
      checkmarkColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? (color ?? AppColors.primary) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
