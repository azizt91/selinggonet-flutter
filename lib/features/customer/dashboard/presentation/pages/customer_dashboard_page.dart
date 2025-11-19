import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/invoice_provider.dart';

class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await ref.read(authControllerProvider).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) => _buildDashboard(context, ref, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, WidgetRef ref, user) {
    final customerInvoicesAsync = ref.watch(customerInvoicesProvider(user?.id ?? ''));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(customerInvoicesProvider(user?.id ?? ''));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                          backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                              ? NetworkImage(user.photoUrl!) as ImageProvider
                              : null,
                          child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                              ? Text(
                                  user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 24,
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
                                'Hallo, ${user?.fullName ?? 'Pelanggan'}',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ID: ${user?.idpl ?? '-'}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: user?.isActive == true
                            ? AppColors.successLight
                            : AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            user?.isActive == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: user?.isActive == true
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${user?.status ?? 'NONAKTIF'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: user?.isActive == true
                                  ? AppColors.success
                                  : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Stats Cards - 4 Cards Grid
            customerInvoicesAsync.when(
              data: (invoices) {
                final unpaidInvoices = invoices.where((i) => i.status == 'unpaid').toList();
                final paidInvoices = invoices.where((i) => i.status == 'paid').toList();
                final totalUnpaid = unpaidInvoices.fold<double>(
                  0,
                  (sum, invoice) => sum + invoice.amount,
                );

                // Format installation date
                final installDate = user?.createdAt;
                final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
                final installDateStr = installDate != null 
                    ? dateFormat.format(installDate)
                    : 'Tidak tersedia';

                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _buildGradientCard(
                      context,
                      'Total Belum Dibayar',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(totalUnpaid),
                      '',
                      '💳',
                      [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
                    ),
                    _buildGradientCard(
                      context,
                      'Berlangganan Sejak',
                      installDateStr.split(' ').take(2).join(' '),
                      installDateStr.split(' ').last,
                      '📅',
                      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
                    ),
                    _buildGradientCard(
                      context,
                      'Belum Lunas',
                      unpaidInvoices.length.toString(),
                      'Tagihan',
                      '⚠️',
                      [const Color(0xFFF093FB), const Color(0xFFF5576C)],
                      onTap: () => context.push('/customer/invoices'),
                    ),
                    _buildGradientCard(
                      context,
                      'Sudah Lunas',
                      paidInvoices.length.toString(),
                      'Pembayaran',
                      '✅',
                      [const Color(0xFF667EEA), const Color(0xFF764BA2)],
                      onTap: () => context.push('/customer/invoices'),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error: $error'),
            ),

            // Quick Actions
            Text(
              'Menu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.receipt_long,
                  title: 'Tagihan',
                  subtitle: 'Lihat tagihan',
                  color: AppColors.primary,
                  onTap: () => context.push('/customer/invoices'),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.person,
                  title: 'Profile',
                  subtitle: 'Lihat profile',
                  color: AppColors.success,
                  onTap: () => context.push('/customer/profile'),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.wifi,
                  title: 'Ganti WiFi',
                  subtitle: 'Ubah SSID/Password',
                  color: AppColors.warning,
                  onTap: () => context.push('/customer/wifi'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientCard(
    BuildContext context,
    String title,
    String value,
    String subtitle,
    String emoji,
    List<Color> gradientColors, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white.withOpacity(0.7),
                      size: 16,
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
