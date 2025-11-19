import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/dashboard_provider.dart';
import '../../../../../data/providers/expense_provider.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Default to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showDateRangePicker,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          if (_startDate != null && _endDate != null) {
            ref.read(expenseStartDateProvider.notifier).state = _startDate;
            ref.read(expenseEndDateProvider.notifier).state = _endDate;
            ref.invalidate(totalExpensesProvider);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Card
              _buildPeriodCard(),
              const SizedBox(height: 16),

              // Summary Cards
              _buildSummarySection(),
              const SizedBox(height: 24),

              // Details Section
              _buildDetailsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodCard() {
    final formatter = DateFormat('dd MMM yyyy');
    return Card(
      color: AppColors.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Periode Laporan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _startDate != null && _endDate != null
                        ? '${formatter.format(_startDate!)} - ${formatter.format(_endDate!)}'
                        : 'Pilih periode',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primary),
              onPressed: _showDateRangePicker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    final statsAsync = ref.watch(dashboardStatsProvider);
    
    // Set expense date filters
    if (_startDate != null && _endDate != null) {
      Future.microtask(() {
        ref.read(expenseStartDateProvider.notifier).state = _startDate;
        ref.read(expenseEndDateProvider.notifier).state = _endDate;
      });
    }
    
    final totalExpensesAsync = ref.watch(totalExpensesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ringkasan Keuangan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) {
            return totalExpensesAsync.when(
              data: (totalExpenses) {
                final revenue = stats.totalRevenue;
                final profit = revenue - totalExpenses;
                final profitMargin = revenue > 0 ? (profit / revenue * 100) : 0.0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Pendapatan',
                            value: revenue,
                            icon: Icons.trending_up,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Pengeluaran',
                            value: totalExpenses,
                            icon: Icons.trending_down,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Profit',
                            value: profit,
                            icon: Icons.account_balance_wallet,
                            color: profit >= 0 ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPercentageCard(
                            title: 'Margin',
                            percentage: profitMargin,
                            icon: Icons.percent,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading expenses'),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double value,
    required IconData icon,
    required Color color,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(value),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageCard({
    required String title,
    required double percentage,
    required IconData icon,
  }) {
    final color = percentage >= 0 ? AppColors.success : AppColors.danger;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detail Pelanggan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        statsAsync.when(
          data: (stats) {
            return Column(
              children: [
                _buildDetailCard(
                  title: 'Total Pelanggan',
                  value: '${stats.totalCustomers}',
                  icon: Icons.people,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _buildDetailCard(
                  title: 'Pelanggan Aktif',
                  value: '${stats.activeCustomers}',
                  icon: Icons.check_circle,
                  color: AppColors.success,
                ),
                const SizedBox(height: 8),
                _buildDetailCard(
                  title: 'Pelanggan Tidak Aktif',
                  value: '${stats.inactiveCustomers}',
                  icon: Icons.cancel,
                  color: AppColors.danger,
                ),
                const SizedBox(height: 8),
                _buildDetailCard(
                  title: 'Tagihan Belum Dibayar',
                  value: '${stats.unpaidInvoices}',
                  icon: Icons.receipt,
                  color: AppColors.warning,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Text('Error: $error'),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final result = await showDialog<Map<String, DateTime?>>(
      context: context,
      builder: (context) => _DateRangePickerDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _startDate = result['start'];
        _endDate = result['end'];
      });
      // Refresh data
      ref.invalidate(dashboardStatsProvider);
      if (_startDate != null && _endDate != null) {
        ref.read(expenseStartDateProvider.notifier).state = _startDate;
        ref.read(expenseEndDateProvider.notifier).state = _endDate;
        ref.invalidate(totalExpensesProvider);
      }
    }
  }
}

class _DateRangePickerDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const _DateRangePickerDialog({
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<_DateRangePickerDialog> createState() => _DateRangePickerDialogState();
}

class _DateRangePickerDialogState extends State<_DateRangePickerDialog> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: const Text('Pilih Periode'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Dari Tanggal'),
            subtitle: Text(
              _startDate != null ? formatter.format(_startDate!) : 'Pilih tanggal',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
          ),
          ListTile(
            title: const Text('Sampai Tanggal'),
            subtitle: Text(
              _endDate != null ? formatter.format(_endDate!) : 'Pilih tanggal',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() => _endDate = date);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'start': _startDate,
              'end': _endDate,
            });
          },
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}
