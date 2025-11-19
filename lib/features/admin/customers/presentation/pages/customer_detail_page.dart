import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/dashboard_provider.dart';
import '../../../../../data/models/profile_model.dart';
import '../../../../../data/models/invoice_model.dart';

class CustomerDetailPage extends ConsumerWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerDetailAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.push('/admin/customers/edit/$customerId');
            },
          ),
        ],
      ),
      body: customerDetailAsync.when(
        data: (data) {
          final customer = data['customer'] as ProfileModel?;
          final invoices = data['invoices'] as List<InvoiceModel>;

          if (customer == null) {
            return const Center(child: Text('Pelanggan tidak ditemukan'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(customerDetailProvider(customerId));
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Customer Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar and Name
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppColors.primary,
                              backgroundImage: customer.photoUrl != null &&
                                      customer.photoUrl!.isNotEmpty
                                  ? NetworkImage(customer.photoUrl!)
                                  : null,
                              child: customer.photoUrl == null ||
                                      customer.photoUrl!.isEmpty
                                  ? Text(
                                      customer.fullName
                                              ?.substring(0, 1)
                                              .toUpperCase() ??
                                          'C',
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.fullName ?? 'Nama tidak tersedia',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${customer.idpl ?? '-'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: customer.status == 'AKTIF'
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.danger.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      customer.status ?? 'NONAKTIF',
                                      style: TextStyle(
                                        color: customer.status == 'AKTIF'
                                            ? AppColors.success
                                            : AppColors.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        
                        // Contact Info
                        _buildInfoRow(
                          Icons.phone,
                          'WhatsApp',
                          customer.phone ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.location_on,
                          'Alamat',
                          customer.address ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.person,
                          'Jenis Kelamin',
                          customer.gender ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.router,
                          'Tipe Device',
                          customer.deviceType ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.network_check,
                          'IP Static/PPPoE',
                          customer.ipStaticPppoe ?? '-',
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Tanggal Instalasi',
                          customer.installationDate != null
                              ? DateFormat('dd MMM yyyy', 'id_ID')
                                  .format(customer.installationDate!)
                              : '-',
                        ),
                        if (customer.churnDate != null) ...[
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.event_busy,
                            'Tanggal Churn',
                            DateFormat('dd MMM yyyy', 'id_ID')
                                .format(customer.churnDate!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Invoices Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Riwayat Tagihan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.push('/admin/invoices?customer=$customerId');
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                if (invoices.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('Belum ada tagihan'),
                      ),
                    ),
                  )
                else
                  ...invoices.take(5).map((invoice) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          _getStatusIcon(invoice.status),
                          color: _getStatusColor(invoice.status),
                        ),
                        title: Text(invoice.invoicePeriod),
                        subtitle: Text(
                          NumberFormat.currency(
                            locale: 'id_ID',
                            symbol: 'Rp ',
                            decimalDigits: 0,
                          ).format(invoice.amount),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(invoice.status)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _getStatusText(invoice.status),
                            style: TextStyle(
                              color: _getStatusColor(invoice.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        onTap: () {
                          context.push('/admin/invoices/${invoice.id}');
                        },
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: AppColors.danger),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(customerDetailProvider(customerId));
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'paid':
        return Icons.check_circle;
      case 'partially_paid':
        return Icons.pending;
      case 'unpaid':
        return Icons.warning;
      case 'overdue':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.success;
      case 'partially_paid':
        return AppColors.secondary;
      case 'unpaid':
        return AppColors.warning;
      case 'overdue':
        return AppColors.danger;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'LUNAS';
      case 'partially_paid':
        return 'CICILAN';
      case 'unpaid':
        return 'BELUM BAYAR';
      case 'overdue':
        return 'TERLAMBAT';
      default:
        return status.toUpperCase();
    }
  }
}
