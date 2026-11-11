import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/invoice_model.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../payment/presentation/widgets/payment_modal.dart';

class CustomerDashboardPage extends ConsumerStatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  ConsumerState<CustomerDashboardPage> createState() => _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends ConsumerState<CustomerDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: dashboardAsync.when(
        data: (data) => _buildDashboardContent(context, ref, data.user, data.invoices),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(dashboardDataProvider),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, user, List<InvoiceModel> invoices) {
    final unpaidInvoices = invoices.where((i) => i.status == 'unpaid').toList();
    final paidInvoices = invoices.where((i) => i.status == 'paid').toList();
    paidInvoices.sort((a, b) => (b.paidAt ?? DateTime(0)).compareTo(a.paidAt ?? DateTime(0)));

    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(dashboardDataProvider.future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Blue gradient header
            _buildBlueHeader(context, ref, user),
            // Status card overlapping the header
            Container(
              margin: const EdgeInsets.fromLTRB(16, -36, 16, 0),
              child: _buildStatusCard(context, user, unpaidInvoices, paidInvoices),
            ),
            const SizedBox(height: 16),

            // Tunggakan card (only when there are unpaid invoices)
            if (unpaidInvoices.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildTunggakanCard(context, ref, unpaidInvoices, user),
              ),
              const SizedBox(height: 16),
            ],

            // Shortcut buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildShortcuts(context),
            ),
            const SizedBox(height: 24),

            // Riwayat Pembayaran header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Pembayaran',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF110E1B)),
                  ),
                  TextButton(
                    onPressed: () => context.go(Uri(path: '/customer/invoices', queryParameters: {'tab': '0'}).toString()),
                    child: const Text('Lihat Semua', style: TextStyle(color: AppColors.customerBlue, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Riwayat Pembayaran list
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: _buildRiwayatList(context, invoices),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlueHeader(BuildContext context, WidgetRef ref, user) {
    final firstName = (user.fullName ?? 'Pelanggan').split(' ').first;
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 56),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            backgroundImage: (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                ? NetworkImage(user.photoUrl!)
                : null,
            onBackgroundImageError: (exception, stackTrace) {
              print('Error loading profile image: $exception');
            },
            child: (user.photoUrl == null || user.photoUrl!.isEmpty)
                ? Text(
                    (user.fullName ?? 'P').substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E40AF),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo! Selamat Datang $firstName',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  user.idpl ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Yakin ingin logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authControllerProvider).logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, user, List<InvoiceModel> unpaidInvoices, List<InvoiceModel> paidInvoices) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    final packageName = user.package?.packageName ?? '-';
    final packagePrice = user.package?.price ??
        (paidInvoices.isNotEmpty ? paidInvoices.first.amount : 0.0);

    DateTime? dueDate;
    if (unpaidInvoices.isNotEmpty) {
      final sorted = [...unpaidInvoices]..sort((a, b) => (a.dueDate ?? DateTime(0)).compareTo(b.dueDate ?? DateTime(0)));
      dueDate = sorted.first.dueDate;
    } else if (paidInvoices.isNotEmpty) {
      dueDate = paidInvoices.first.dueDate;
    }

    final isPaid = unpaidInvoices.isEmpty;
    final latestPaid = paidInvoices.isNotEmpty ? paidInvoices.first : null;
    final statusRaw = (user.status as String?)?.toLowerCase() ?? 'active';
    final statusTitle = statusRaw == 'active'
        ? 'Internet Aktif'
        : statusRaw == 'isolir'
            ? 'Internet Diisolir'
            : 'Internet ${statusRaw[0].toUpperCase()}${statusRaw.substring(1)}';
    final installationDate = user.installationDate;
    final formattedSince = installationDate != null
        ? DateFormat('dd MMMM yyyy', 'id_ID').format(installationDate)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Blue header strip
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Selamat menikmati layanan internet Selinggonet Anda',
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nama Paket', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(packageName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF110E1B))),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Harga Paket', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          const SizedBox(height: 2),
                          Text(currencyFormat.format(packagePrice), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF110E1B))),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tanggal Jatuh Tempo', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          const SizedBox(height: 2),
                          Text(
                            dueDate != null ? dateFormat.format(dueDate) : '-',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF110E1B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Status Pembayaran', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          const SizedBox(height: 2),
                          Text(
                            isPaid ? 'LUNAS' : 'BELUM DIBAYAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPaid ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Tanggal Pembayaran', style: TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                          const SizedBox(height: 2),
                          Text(
                            latestPaid?.paidAt != null ? dateFormat.format(latestPaid!.paidAt!) : '-',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF110E1B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (formattedSince != null) ...[
                  const Divider(height: 28),
                  Text(
                    'Berlangganan sejak $formattedSince',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTunggakanCard(BuildContext context, WidgetRef ref, List<InvoiceModel> unpaidInvoices, user) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalTunggakan = unpaidInvoices.fold(0.0, (sum, i) => sum + i.amount);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Tunggakan', style: TextStyle(color: Color(0xFF6B7280), fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(currencyFormat.format(totalTunggakan), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${unpaidInvoices.length} tagihan belum dibayar', style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          ...unpaidInvoices.take(2).map((invoice) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long, color: Colors.red, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tagihan ${invoice.invoicePeriod}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text('Belum Dibayar', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                Text(currencyFormat.format(invoice.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaymentModal(context, ref, unpaidInvoices, user),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.customerBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcuts(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildShortcutItem(
          context,
          icon: Icons.wifi,
          label: 'Ganti WiFi',
          onTap: () => context.go('/customer/wifi'),
        ),
        const SizedBox(width: 48),
        _buildShortcutItem(
          context,
          icon: Icons.help_outline,
          label: 'Bantuan',
          onTap: () => context.go('/customer/help'),
        ),
      ],
    );
  }

  Widget _buildShortcutItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.customerBlue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E40AF))),
        ],
      ),
    );
  }

  Widget _buildRiwayatList(BuildContext context, List<InvoiceModel> invoices) {
    final paidInvoices = invoices.where((i) => i.status == 'paid').toList();
    paidInvoices.sort((a, b) => (b.paidAt ?? DateTime(0)).compareTo(a.paidAt ?? DateTime(0)));
    final recentPaid = paidInvoices.take(4).toList();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (recentPaid.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Belum ada riwayat pembayaran.', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: recentPaid.asMap().entries.map((entry) {
          final index = entry.key;
          final invoice = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pembayaran ${invoice.invoicePeriod}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              invoice.paidAt != null ? DateFormat('d MMM yyyy', 'id_ID').format(invoice.paidAt!) : '-',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(currencyFormat.format(invoice.amountPaid), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              if (index < recentPaid.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  void _showPaymentModal(BuildContext context, WidgetRef ref, List<InvoiceModel> invoices, user) {
    final totalAmount = invoices.fold(0.0, (sum, i) => sum + i.amount);
    final periods = invoices.map((i) => i.invoicePeriod).join(', ');
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PaymentModal(
        totalAmount: totalAmount,
        periods: periods,
        formattedAmount: currencyFormat.format(totalAmount),
        user: user,
      ),
    );
  }
}
