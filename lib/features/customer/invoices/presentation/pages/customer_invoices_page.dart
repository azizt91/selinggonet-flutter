import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/invoice_provider.dart';
import '../../../../../data/models/invoice_model.dart';

class CustomerInvoicesPage extends ConsumerStatefulWidget {
  const CustomerInvoicesPage({super.key});

  @override
  ConsumerState<CustomerInvoicesPage> createState() => _CustomerInvoicesPageState();
}

class _CustomerInvoicesPageState extends ConsumerState<CustomerInvoicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tagihan Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final user = userAsync.value;
              if (user != null) {
                ref.invalidate(customerInvoicesProvider(user.id!));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Belum Dibayar'),
            Tab(text: 'Cicilan'),
            Tab(text: 'Lunas'),
          ],
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          final invoicesAsync = ref.watch(customerInvoicesProvider(user.id!));

          return invoicesAsync.when(
            data: (invoices) {
              final unpaid = invoices.where((i) => i.status == 'unpaid').toList();
              final installment = invoices.where((i) => i.status == 'partially_paid' || i.status == 'installment').toList();
              final paid = invoices.where((i) => i.status == 'paid').toList();

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(customerInvoicesProvider(user.id!));
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInvoiceList(unpaid, 'Belum ada tagihan yang belum dibayar'),
                    _buildInvoiceList(installment, 'Belum ada tagihan cicilan'),
                    _buildInvoiceList(paid, 'Belum ada tagihan yang lunas'),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.danger,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error: $error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(customerInvoicesProvider(user.id!)),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInvoiceList(List<InvoiceModel> invoices, String emptyMessage) {
    if (invoices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _buildInvoiceCard(invoice);
      },
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    final statusColor = _getStatusColor(invoice.status ?? 'unpaid');
    final isOverdue = invoice.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.invoiceNumber ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        invoice.description ?? 'Tagihan bulanan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(invoice.status ?? 'unpaid'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoice.status == 'paid' ? 'Total Dibayar' : 'Total Tagihan',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(invoice.status == 'paid' ? invoice.amountPaid : invoice.amount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (invoice.isInstallment)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Sisa',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(invoice.remainingAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Due Date (only for unpaid and partially_paid)
            if (invoice.status != 'paid') ...[
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: isOverdue ? AppColors.danger : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Jatuh tempo: ${invoice.dueDate != null ? DateFormat('dd MMMM yyyy').format(invoice.dueDate!) : '-'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? AppColors.danger : Colors.grey[600],
                      fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isOverdue) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.warning, size: 16, color: AppColors.danger),
                    const SizedBox(width: 4),
                    const Text(
                      'TERLAMBAT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Paid Date for paid invoices
            if (invoice.status == 'paid' && invoice.paidAt != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                    const SizedBox(width: 8),
                    Text(
                      'Dibayar pada: ${DateFormat('dd MMMM yyyy').format(invoice.paidAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Payment Info for Installment
            if (invoice.isInstallment) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.info),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sudah dibayar: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(invoice.paidAmount ?? 0)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                // Detail Button (for all statuses)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showInvoiceDetail(invoice);
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detail'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                // Pay Button (only for unpaid)
                if (invoice.status == 'unpaid') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showPaymentDialog(invoice);
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Bayar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'installment':
        return AppColors.secondary;
      case 'unpaid':
      default:
        return AppColors.warning;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'LUNAS';
      case 'installment':
        return 'CICILAN';
      case 'unpaid':
      default:
        return 'BELUM BAYAR';
    }
  }

  void _showInvoiceDetail(InvoiceModel invoice) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Tagihan #${invoice.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Periode', invoice.invoicePeriod),
              _buildDetailRow('Status', _getStatusLabel(invoice.status)),
              _buildDetailRow('Total Tagihan', formatter.format(invoice.amount)),
              if (invoice.isInstallment) ...[
                _buildDetailRow('Sudah Dibayar', formatter.format(invoice.paidAmount ?? 0)),
                _buildDetailRow('Sisa Tagihan', formatter.format(invoice.remainingAmount ?? 0)),
              ],
              if (invoice.dueDate != null)
                _buildDetailRow('Jatuh Tempo', DateFormat('dd MMMM yyyy').format(invoice.dueDate!)),
              if (invoice.paidAt != null)
                _buildDetailRow('Dibayar Pada', DateFormat('dd MMMM yyyy').format(invoice.paidAt!)),
              if (invoice.notes != null && invoice.notes!.isNotEmpty)
                _buildDetailRow('Catatan', invoice.notes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline,
              size: 48,
              color: AppColors.info,
            ),
            const SizedBox(height: 16),
            const Text(
              'Untuk melakukan pembayaran, silakan hubungi admin atau transfer ke rekening yang tertera.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(invoice.amount)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement payment flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur pembayaran online akan segera hadir'),
                  backgroundColor: AppColors.info,
                ),
              );
            },
            child: const Text('Hubungi Admin'),
          ),
        ],
      ),
    );
  }
}
