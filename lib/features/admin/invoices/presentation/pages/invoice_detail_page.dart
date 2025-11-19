import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/invoice_provider.dart';

class InvoiceDetailPage extends ConsumerWidget {
  final String invoiceId;

  const InvoiceDetailPage({
    super.key,
    required this.invoiceId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoiceAsync = ref.watch(invoiceByIdProvider(invoiceId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Tagihan'),
        centerTitle: true,
      ),
      body: invoiceAsync.when(
        data: (invoice) {
          final formatter = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(invoice.status),
                          color: _getStatusColor(invoice.status),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusLabel(invoice.status),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(invoice.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Customer Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pelanggan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Nama Pelanggan', invoice.customerName),
                        const SizedBox(height: 12),
                        _buildInfoRow('ID Pelanggan', invoice.customerIdpl),
                        const SizedBox(height: 12),
                        _buildInfoRow('WhatsApp', invoice.customerWhatsapp.isNotEmpty 
                            ? invoice.customerWhatsapp 
                            : '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pembayaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Periode Tagihan', invoice.invoicePeriod),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Jumlah Tagihan',
                          formatter.format(invoice.totalDue ?? invoice.amount),
                        ),
                        if (invoice.status == 'partially_paid') ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Sudah Dibayar',
                            formatter.format(invoice.amountPaid),
                            valueColor: AppColors.success,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Sisa Tagihan',
                            formatter.format(invoice.remainingAmount),
                            valueColor: AppColors.danger,
                          ),
                        ],
                        if (invoice.status == 'paid') ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Total Dibayar',
                            formatter.format(invoice.amountPaid),
                            valueColor: AppColors.success,
                          ),
                        ],
                        if (invoice.paidAt != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Tanggal Bayar',
                            DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(invoice.paidAt!),
                          ),
                        ],
                        if (invoice.paymentMethod != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Metode Pembayaran',
                            _getPaymentMethodLabel(invoice.paymentMethod!),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Status',
                          '',
                          customValue: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(invoice.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getStatusLabel(invoice.status),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(invoice.status),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Payment History (if exists)
                if (invoice.paymentHistory != null && invoice.paymentHistory!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Riwayat Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...invoice.paymentHistory!.asMap().entries.map((entry) {
                            final index = entry.key;
                            final payment = entry.value;
                            final amount = payment['amount'] as num?;
                            final date = payment['date'] as String?;
                            final method = payment['method'] as String?;
                            final admin = payment['admin'] as String?;
                            final note = payment['note'] as String?;

                            return Column(
                              children: [
                                if (index > 0) const Divider(height: 24),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            formatter.format(amount ?? 0),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (date != null)
                                            Text(
                                              DateFormat('dd MMM yyyy, HH:mm', 'id_ID')
                                                  .format(DateTime.parse(date)),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          if (method != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Metode: ${_getPaymentMethodLabel(method)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                          if (admin != null) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Diproses: $admin',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                          if (note != null && note.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Catatan: $note',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(invoiceByIdProvider(invoiceId)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, Widget? customValue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 16),
        customValue ?? Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partially_paid':
        return AppColors.warning;
      case 'unpaid':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'partially_paid':
        return Icons.hourglass_bottom;
      case 'unpaid':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'LUNAS';
      case 'partially_paid':
        return 'CICILAN';
      case 'unpaid':
        return 'BELUM DIBAYAR';
      default:
        return status.toUpperCase();
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer Bank';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }
}
