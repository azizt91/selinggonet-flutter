import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/dashboard_provider.dart';
import '../../../../../data/providers/notification_provider.dart';
import '../widgets/revenue_chart.dart';
import '../widgets/customer_status_chart.dart';

// Provider untuk visibility nominal
final profitVisibilityProvider = StateProvider<bool>((ref) => true);
final pendapatanVisibilityProvider = StateProvider<bool>((ref) => true);
final pengeluaranVisibilityProvider = StateProvider<bool>((ref) => true);

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    _loadVisibilityPreferences();
  }

  Future<void> _loadVisibilityPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(profitVisibilityProvider.notifier).state =
        prefs.getBool('visibility_profit') ?? true;
    ref.read(pendapatanVisibilityProvider.notifier).state =
        prefs.getBool('visibility_pendapatan') ?? true;
    ref.read(pengeluaranVisibilityProvider.notifier).state =
        prefs.getBool('visibility_pengeluaran') ?? true;
  }

  Future<void> _toggleVisibility(String key, StateProvider<bool> provider) async {
    final prefs = await SharedPreferences.getInstance();
    final currentValue = ref.read(provider);
    final newValue = !currentValue;
    await prefs.setBool('visibility_$key', newValue);
    ref.read(provider.notifier).state = newValue;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(dashboardStatsProvider);
              ref.invalidate(monthlyRevenueProvider);
              ref.invalidate(recentInvoicesProvider);
              ref.invalidate(recentCustomersProvider);
            },
          ),
          // Notification Bell with Badge
          userAsync.when(
            data: (user) {
              if (user == null) return const SizedBox.shrink();
              
              final unreadCountAsync = ref.watch(unreadNotificationCountProvider(user.id!));
              
              return unreadCountAsync.when(
                data: (count) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: () => context.push('/admin/notifications'),
                    ),
                    if (count > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                loading: () => IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => context.push('/admin/notifications'),
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () => context.push('/admin/notifications'),
                ),
              );
            },
            loading: () => IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => context.push('/admin/notifications'),
            ),
            error: (_, __) => IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () => context.push('/admin/notifications'),
            ),
          ),
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
        data: (user) => _buildDashboard(context, user),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, user) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dashboardStatsProvider);
        ref.invalidate(monthlyRevenueProvider);
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(context, user),
            const SizedBox(height: 24),

            // Quick Menu Section
            _buildQuickMenuSection(context),
            const SizedBox(height: 24),

            // Filter Section
            _buildFilterSection(context),
            const SizedBox(height: 24),

            // Statistics Cards
            _buildStatisticsSection(),
            const SizedBox(height: 24),

            // Charts Section
            _buildChartsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary,
              backgroundImage: (user?.photoUrl != null && user!.photoUrl!.isNotEmpty)
                  ? NetworkImage(user.photoUrl!) as ImageProvider
                  : null,
              child: (user?.photoUrl == null || user!.photoUrl!.isEmpty)
                  ? Text(
                      user?.fullName?.substring(0, 1).toUpperCase() ?? 'A',
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
                    'Hallo, ${user?.fullName ?? 'Admin'}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selamat datang di dashboard',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Cepat',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickMenuItem(
                context: context,
                icon: Icons.assessment,
                label: 'Laporan',
                color: AppColors.primary,
                onTap: () => context.push('/admin/reports'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickMenuItem(
                context: context,
                icon: Icons.inventory_2,
                label: 'Paket',
                color: AppColors.success,
                onTap: () => context.push('/admin/packages'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickMenuItem(
                context: context,
                icon: Icons.receipt_long,
                label: 'Tagihan',
                color: AppColors.warning,
                onTap: () => context.push('/admin/invoices'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickMenuItem(
                context: context,
                icon: Icons.people,
                label: 'Pelanggan',
                color: AppColors.info,
                onTap: () => context.push('/admin/customers'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);

    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Bulan',
              prefixIcon: Icon(Icons.calendar_month),
            ),
            items: List.generate(
              12,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(months[index]),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedMonthProvider.notifier).state = value;
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: selectedYear,
            decoration: const InputDecoration(
              labelText: 'Tahun',
              prefixIcon: Icon(Icons.calendar_today),
            ),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(
                value: DateTime.now().year - index,
                child: Text('${DateTime.now().year - index}'),
              ),
            ),
            onChanged: (value) {
              if (value != null) {
                ref.read(selectedYearProvider.notifier).state = value;
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final selectedYear = ref.watch(selectedYearProvider);

    return statsAsync.when(
      data: (stats) {
        final formatter = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        );

        final profitVisible = ref.watch(profitVisibilityProvider);
        final pendapatanVisible = ref.watch(pendapatanVisibilityProvider);
        final pengeluaranVisible = ref.watch(pengeluaranVisibilityProvider);

        return Column(
          children: [
            // Profit Card (full width)
            _buildStatCard(
              title: 'Profit',
              value: formatter.format(stats.profit),
              icon: Icons.trending_up,
              color: stats.profit >= 0 ? AppColors.success : AppColors.danger,
              hasEyeToggle: true,
              isVisible: profitVisible,
              onToggleVisibility: () => _toggleVisibility('profit', profitVisibilityProvider),
            ),
            const SizedBox(height: 12),
            
            // Row 1: Pendapatan & Pengeluaran
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Pendapatan',
                    value: formatter.format(stats.totalRevenue),
                    icon: Icons.attach_money,
                    color: AppColors.primary,
                    hasEyeToggle: true,
                    isVisible: pendapatanVisible,
                    onToggleVisibility: () => _toggleVisibility('pendapatan', pendapatanVisibilityProvider),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pengeluaran',
                    value: formatter.format(stats.totalExpenses),
                    icon: Icons.money_off,
                    color: AppColors.danger,
                    hasEyeToggle: true,
                    isVisible: pengeluaranVisible,
                    onToggleVisibility: () => _toggleVisibility('pengeluaran', pengeluaranVisibilityProvider),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Row 2: Pelanggan Aktif & Tidak Aktif
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Pelanggan',
                    value: '${stats.activeCustomers}',
                    subtitle: 'Aktif: ${stats.activeCustomers}',
                    icon: Icons.people,
                    color: AppColors.info,
                    onTap: () => context.push('/admin/customers?status=AKTIF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pelanggan Tdk Aktif',
                    value: '${stats.inactiveCustomers}',
                    icon: Icons.people_outline,
                    color: AppColors.secondary,
                    onTap: () => context.push('/admin/customers?status=NONAKTIF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Row 3: Belum Bayar & Lunas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Belum Bayar',
                    value: '${stats.unpaidInvoices}',
                    icon: Icons.pending,
                    color: AppColors.warning,
                    onTap: () => context.push('/admin/invoices?status=unpaid&month=$selectedMonth&year=$selectedYear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Lunas Bulan Ini',
                    value: '${stats.paidInvoices}',
                    icon: Icons.check_circle,
                    color: AppColors.success,
                    onTap: () => context.push('/admin/invoices?status=paid&month=$selectedMonth&year=$selectedYear'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading statistics: $error',
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
    bool hasEyeToggle = false,
    bool isVisible = true,
    VoidCallback? onToggleVisibility,
    VoidCallback? onTap,
  }) {
    final displayValue = hasEyeToggle && !isVisible ? 'Rp ...' : value;

    return Card(
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  if (hasEyeToggle)
                    IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
              ],
              if (onTap != null) ...[
                const SizedBox(height: 4),
                const Text(
                  '👆 Ketuk untuk detail',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grafik',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const RevenueChart(),
        const SizedBox(height: 16),
        const CustomerStatusChart(),
      ],
    );
  }
}
