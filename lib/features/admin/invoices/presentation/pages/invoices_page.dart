import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/invoice_provider.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/whatsapp_notification_provider.dart';
import '../../../../../data/models/invoice_model.dart';
import '../widgets/invoice_card.dart';
import '../widgets/invoice_filter_sheet.dart';
import 'invoice_form_page.dart';
import 'payment_form_page.dart';

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  final List<String> _statuses = ['unpaid', 'installment', 'paid'];
  final List<String> _tabLabels = ['Belum Dibayar', 'Cicilan', 'Lunas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(invoiceTabProvider.notifier).state = _tabController.index;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        ref.read(invoiceSearchQueryProvider.notifier).state = value;
        // Reset pages for all tabs
        for (var status in _statuses) {
          ref.read(invoicePageProvider(status).notifier).state = 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(invoiceStatsProvider);
    final searchQuery = ref.watch(invoiceSearchQueryProvider);
    final startDate = ref.watch(invoiceStartDateProvider);
    final endDate = ref.watch(invoiceEndDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Tagihan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const InvoiceFilterSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(invoiceStatsProvider);
              for (var status in _statuses) {
                ref.invalidate(invoicesProvider(status));
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Stats Card
          statsAsync.when(
            data: (stats) => Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Belum Bayar',
                    '${stats['unpaid_count']}',
                    NumberFormat.compact(locale: 'id_ID').format(stats['total_unpaid']),
                    AppColors.warning,
                  ),
                  _buildStatItem(
                    'Cicilan',
                    '${stats['installment_count']}',
                    NumberFormat.compact(locale: 'id_ID').format(stats['total_installment']),
                    AppColors.secondary,
                  ),
                  _buildStatItem(
                    'Lunas',
                    '${stats['paid_count']}',
                    NumberFormat.compact(locale: 'id_ID').format(stats['total_revenue']),
                    AppColors.success,
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari nomor invoice...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(invoiceSearchQueryProvider.notifier).state = '';
                          for (var status in _statuses) {
                            ref.read(invoicePageProvider(status).notifier).state = 1;
                          }
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Active Filters
          if (startDate != null || endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  if (startDate != null)
                    Chip(
                      label: Text('Dari: ${DateFormat('dd/MM/yyyy').format(startDate)}'),
                      onDeleted: () {
                        ref.read(invoiceStartDateProvider.notifier).state = null;
                        for (var status in _statuses) {
                          ref.read(invoicePageProvider(status).notifier).state = 1;
                        }
                      },
                    ),
                  if (endDate != null)
                    Chip(
                      label: Text('Sampai: ${DateFormat('dd/MM/yyyy').format(endDate)}'),
                      onDeleted: () {
                        ref.read(invoiceEndDateProvider.notifier).state = null;
                        for (var status in _statuses) {
                          ref.read(invoicePageProvider(status).notifier).state = 1;
                        }
                      },
                    ),
                ],
              ),
            ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _statuses.map((status) => _buildInvoiceList(status)).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 0 // Only show on unpaid tab
          ? FloatingActionButton.extended(
              onPressed: _showCreateInvoicesDialog,
              icon: const Icon(Icons.add),
              label: const Text('Buat Tagihan'),
              backgroundColor: AppColors.primary,
            )
          : null,
    );
  }

  Widget _buildStatItem(String label, String count, String amount, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          'Rp $amount',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceList(String status) {
    final invoicesAsync = ref.watch(invoicesProvider(status));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(invoicesProvider(status));
      },
      child: invoicesAsync.when(
        data: (invoices) {
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
                    'Tidak ada tagihan',
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
              return InvoiceCard(
                invoice: invoice,
                onTap: () => _navigateToDetail(invoice.id!),
                onPay: status != 'paid' ? () => _navigateToPayment(invoice) : null,
                onEdit: status == 'unpaid' ? () => _navigateToEdit(invoice) : null,
                onDelete: status == 'unpaid' ? () => _confirmDelete(invoice) : null,
                onRevert: status == 'paid' ? () => _confirmRevertPayment(invoice) : null,
                // New callbacks for unpaid and partially_paid
                onWhatsApp: (status == 'unpaid' || status == 'installment') 
                    ? () => _sendWhatsAppReminder(invoice) 
                    : null,
                onInstallment: (status == 'unpaid' || status == 'installment') 
                    ? () => _showInstallmentDialog(invoice) 
                    : null,
                onMarkPaid: (status == 'unpaid' || status == 'installment') 
                    ? () => _confirmMarkAsPaid(invoice) 
                    : null,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
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
                onPressed: () => ref.invalidate(invoicesProvider(status)),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateInvoicesDialog() async {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM', 'id_ID').format(now);
    final year = now.year;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Tagihan Bulanan'),
        content: Text(
          'Apakah Anda yakin ingin membuat tagihan untuk bulan $monthName $year?\n\n'
          'Proses ini akan dijalankan untuk semua pelanggan aktif yang belum memiliki tagihan bulan ini.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Buat Tagihan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _createMonthlyInvoices();
    }
  }

  Future<void> _createMonthlyInvoices() async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Membuat tagihan bulanan...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      // Call RPC function
      final supabase = ref.read(supabaseClientProvider);
      final response = await supabase.rpc('create_monthly_invoices_v2');

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (response != null && response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Tagihan berhasil dibuat'),
              backgroundColor: AppColors.success,
            ),
          );

          // Refresh data
          ref.invalidate(invoiceStatsProvider);
          for (var status in _statuses) {
            ref.invalidate(invoicesProvider(status));
          }
        } else {
          throw Exception(response?['message'] ?? 'Terjadi kesalahan di server');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuat tagihan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _navigateToEdit(InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceFormPage(invoice: invoice),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(invoiceStatsProvider);
        for (var status in _statuses) {
          ref.invalidate(invoicesProvider(status));
        }
      }
    });
  }

  void _navigateToPayment(InvoiceModel invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFormPage(invoice: invoice),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(invoiceStatsProvider);
        for (var status in _statuses) {
          ref.invalidate(invoicesProvider(status));
        }
      }
    });
  }

  void _navigateToDetail(String invoiceId) {
    context.push('/admin/invoices/$invoiceId');
  }

  Future<void> _confirmDelete(InvoiceModel invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tagihan'),
        content: Text(
          'Yakin ingin menghapus tagihan ${invoice.invoiceNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(invoiceControllerProvider.notifier).deleteInvoice(invoice.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tagihan berhasil dihapus')),
          );
          ref.invalidate(invoiceStatsProvider);
          for (var status in _statuses) {
            ref.invalidate(invoicesProvider(status));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _confirmRevertPayment(InvoiceModel invoice) async {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Batalkan Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${invoice.customerName}'),
            Text('Periode: ${invoice.invoicePeriod ?? 'N/A'}'),
            Text('Jumlah: ${formatter.format(invoice.amount)}'),
            const SizedBox(height: 12),
            const Text(
              'Status: LUNAS → BELUM DIBAYAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tindakan ini akan mengembalikan status tagihan ke "Belum Dibayar". '
              'Data pembayaran (tanggal & metode) akan dihapus.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
            ),
            child: const Text('Batalkan Pembayaran'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _revertPayment(invoice);
    }
  }

  Future<void> _revertPayment(InvoiceModel invoice) async {
    try {
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Membatalkan pembayaran...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Revert payment status
      final supabase = ref.read(supabaseClientProvider);
      await supabase.from('invoices').update({
        'status': 'unpaid',
        'paid_at': null,
        'payment_method': null,
        'amount': invoice.totalDue ?? invoice.amount, // Reset to full amount
        'amount_paid': 0, // Reset amount paid
      }).eq('id', invoice.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Pembayaran berhasil dibatalkan!\nTagihan "${invoice.invoicePeriod}" kembali ke status belum dibayar.',
            ),
            backgroundColor: AppColors.success,
          ),
        );

        // Refresh data and switch to unpaid tab
        ref.invalidate(invoiceStatsProvider);
        for (var status in _statuses) {
          ref.invalidate(invoicesProvider(status));
        }
        _tabController.animateTo(0); // Switch to unpaid tab
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal membatalkan pembayaran: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Send WhatsApp reminder
  Future<void> _sendWhatsAppReminder(InvoiceModel invoice) async {
    try {
      final whatsappService = ref.read(whatsappNotificationServiceProvider);
      final user = await ref.read(currentUserProvider.future);
      
      if (invoice.customerWhatsapp.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor WhatsApp pelanggan tidak tersedia'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Create reminder message
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      final amount = invoice.status == 'partially_paid' 
          ? invoice.remainingAmount 
          : invoice.amount;
      
      final message = '''
Halo ${invoice.customerName},

Ini adalah pengingat tagihan internet Anda:
📅 Periode: ${invoice.invoicePeriod}
💰 Jumlah: ${formatter.format(amount)}
${invoice.status == 'partially_paid' ? '⚠️ Status: Cicilan (Sisa pembayaran)' : ''}

Mohon segera lakukan pembayaran. Terima kasih!

_Pesan otomatis dari ${user?.fullName ?? 'Admin'}_
''';

      await whatsappService.sendMessage(
        phoneNumber: invoice.customerWhatsapp,
        message: message,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Pesan WhatsApp berhasil dikirim'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengirim WhatsApp: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Show installment payment dialog
  Future<void> _showInstallmentDialog(InvoiceModel invoice) async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedMethod = 'cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bayar Cicilan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pelanggan: ${invoice.customerName}'),
              Text('Periode: ${invoice.invoicePeriod}'),
              const SizedBox(height: 8),
              Text(
                'Sisa Tagihan: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(invoice.remainingAmount)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Jumlah Bayar',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Metode Pembayaran',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                  DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                  DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                ],
                onChanged: (value) {
                  if (value != null) selectedMethod = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Catatan (Opsional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Proses'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final amount = double.tryParse(amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jumlah pembayaran tidak valid'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      await _processInstallment(
        invoice: invoice,
        amount: amount,
        method: selectedMethod,
        note: noteController.text,
      );
    }
  }

  Future<void> _processInstallment({
    required InvoiceModel invoice,
    required double amount,
    required String method,
    required String note,
  }) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Memproses pembayaran cicilan...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final controller = ref.read(invoiceControllerProvider.notifier);
      final user = await ref.read(currentUserProvider.future);
      
      final result = await controller.processInstallmentPayment(
        invoiceId: invoice.id!,
        paymentAmount: amount,
        adminName: user?.fullName ?? 'Admin',
        paymentMethod: method,
        note: note,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: AppColors.success,
          ),
        );

        // Refresh data
        ref.invalidate(invoiceStatsProvider);
        for (var status in _statuses) {
          ref.invalidate(invoicesProvider(status));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal memproses pembayaran: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // Confirm mark as paid
  Future<void> _confirmMarkAsPaid(InvoiceModel invoice) async {
    String selectedMethod = 'cash';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tandai Lunas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pelanggan: ${invoice.customerName}'),
            Text('Periode: ${invoice.invoicePeriod}'),
            const SizedBox(height: 8),
            Text(
              'Total: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(invoice.status == 'partially_paid' ? invoice.remainingAmount : invoice.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Tandai tagihan ini sebagai LUNAS?'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Tunai')),
                DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
                DropdownMenuItem(value: 'qris', child: Text('QRIS')),
              ],
              onChanged: (value) {
                if (value != null) selectedMethod = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Ya, Tandai Lunas'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _markInvoiceAsPaid(invoice, selectedMethod);
    }
  }

  Future<void> _markInvoiceAsPaid(InvoiceModel invoice, String method) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text('Menandai sebagai lunas...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      final controller = ref.read(invoiceControllerProvider.notifier);
      await controller.markAsPaid(
        invoiceId: invoice.id!,
        paymentMethod: method,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Tagihan "${invoice.invoicePeriod}" berhasil ditandai lunas!'),
            backgroundColor: AppColors.success,
          ),
        );

        // Refresh data
        ref.invalidate(invoiceStatsProvider);
        for (var status in _statuses) {
          ref.invalidate(invoicesProvider(status));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal menandai lunas: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
