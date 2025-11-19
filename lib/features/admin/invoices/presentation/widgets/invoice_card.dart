import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/invoice_model.dart';

class InvoiceCard extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onTap;
  final VoidCallback? onPay;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRevert;
  final VoidCallback? onWhatsApp;
  final VoidCallback? onInstallment;
  final VoidCallback? onMarkPaid;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
    this.onPay,
    this.onEdit,
    this.onDelete,
    this.onRevert,
    this.onWhatsApp,
    this.onInstallment,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isOverdue = invoice.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.customerName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (invoice.invoicePeriod != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPeriodColor().withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              invoice.invoicePeriod!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getPeriodColor(),
                              ),
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
                      _getStatusLabel(),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.status == 'paid' ? 'Dibayar' : 'Total',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(invoice.status == 'paid' ? invoice.amountPaid : invoice.amount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (invoice.status == 'installment' || invoice.status == 'partially_paid')
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
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              // Only show due date for unpaid and partially_paid invoices
              if (invoice.status != 'paid') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Jatuh tempo: ${invoice.dueDate != null ? DateFormat('dd MMM yyyy').format(invoice.dueDate!) : '-'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOverdue ? AppColors.danger : Colors.grey[600],
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.warning, size: 14, color: AppColors.danger),
                    ],
                  ],
                ),
              ],
              // Action buttons based on invoice status
              if (invoice.status == 'unpaid' && (onWhatsApp != null || onInstallment != null || onMarkPaid != null)) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onWhatsApp != null)
                      IconButton(
                        onPressed: onWhatsApp,
                        icon: const Icon(Icons.chat, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.all(6),
                        ),
                        tooltip: 'Kirim WhatsApp',
                      ),
                    const SizedBox(width: 6),
                    if (onInstallment != null)
                      ElevatedButton(
                        onPressed: onInstallment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Cicil'),
                      ),
                    const SizedBox(width: 6),
                    if (onMarkPaid != null)
                      ElevatedButton(
                        onPressed: onMarkPaid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('LUNAS'),
                      ),
                  ],
                ),
              ] else if (invoice.status == 'partially_paid' && (onWhatsApp != null || onInstallment != null || onMarkPaid != null)) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onWhatsApp != null)
                      IconButton(
                        onPressed: onWhatsApp,
                        icon: const Icon(Icons.chat, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(32, 32),
                          padding: const EdgeInsets.all(6),
                        ),
                        tooltip: 'Kirim WhatsApp',
                      ),
                    const SizedBox(width: 6),
                    if (onInstallment != null)
                      ElevatedButton(
                        onPressed: onInstallment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Cicil'),
                      ),
                    const SizedBox(width: 6),
                    if (onMarkPaid != null)
                      ElevatedButton(
                        onPressed: onMarkPaid,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        child: const Text('Lunas'),
                      ),
                  ],
                ),
              ] else if (onPay != null || onEdit != null || onDelete != null || onRevert != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onPay != null)
                      TextButton.icon(
                        onPressed: onPay,
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Bayar'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.success,
                        ),
                      ),
                    if (onRevert != null)
                      TextButton.icon(
                        onPressed: onRevert,
                        icon: const Icon(Icons.undo, size: 16),
                        label: const Text('Batalkan'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.warning,
                        ),
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 16),
                        label: const Text('Hapus'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.danger,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case 'paid':
        return AppColors.success;
      case 'installment':
        return AppColors.secondary;
      case 'unpaid':
      default:
        return AppColors.warning;
    }
  }

  String _getStatusLabel() {
    switch (invoice.status) {
      case 'paid':
        return 'LUNAS';
      case 'installment':
        return 'CICILAN';
      case 'unpaid':
      default:
        return 'BELUM BAYAR';
    }
  }

  Color _getPeriodColor() {
    // Get month from period string (e.g., "November 2025")
    final period = invoice.invoicePeriod?.toLowerCase() ?? '';
    
    if (period.contains('januari')) return Colors.blue;
    if (period.contains('februari')) return Colors.indigo;
    if (period.contains('maret')) return Colors.green;
    if (period.contains('april')) return Colors.lightGreen;
    if (period.contains('mei')) return Colors.lime;
    if (period.contains('juni')) return Colors.yellow.shade700;
    if (period.contains('juli')) return Colors.orange;
    if (period.contains('agustus')) return Colors.deepOrange;
    if (period.contains('september')) return Colors.red;
    if (period.contains('oktober')) return Colors.pink;
    if (period.contains('november')) return Colors.purple;
    if (period.contains('desember')) return Colors.deepPurple;
    
    return Colors.grey;
  }
}
