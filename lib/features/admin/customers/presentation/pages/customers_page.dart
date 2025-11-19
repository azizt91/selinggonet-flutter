import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/customer_provider.dart';
import '../../../../../data/models/profile_model.dart';
import '../widgets/customer_card.dart';
import '../widgets/customer_filter_sheet.dart';
import 'customer_form_page.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isFabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      // Load more (pagination)
      final currentPage = ref.read(customerPageProvider);
      ref.read(customerPageProvider.notifier).state = currentPage + 1;
    }
  }

  void _onSearchChanged(String value) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == value) {
        ref.read(customerSearchQueryProvider.notifier).state = value;
        ref.read(customerPageProvider.notifier).state = 1; // Reset to page 1
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      print('🔵 [CustomersPage] Building...');
      
      final customersAsync = ref.watch(customersProvider);
      print('🔵 [CustomersPage] customersAsync state: ${customersAsync.runtimeType}');
      
      final statsAsync = ref.watch(customerStatsProvider);
      final searchQuery = ref.watch(customerSearchQueryProvider);
      final statusFilter = ref.watch(customerStatusFilterProvider);

      return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pelanggan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => const CustomerFilterSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(customersProvider);
              ref.invalidate(customerStatsProvider);
            },
          ),
        ],
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
                    'Total',
                    '${stats['total']}',
                    AppColors.primary,
                  ),
                  _buildStatItem(
                    'Aktif',
                    '${stats['active']}',
                    AppColors.success,
                  ),
                  _buildStatItem(
                    'Nonaktif',
                    '${stats['inactive']}',
                    AppColors.danger,
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
                hintText: 'Cari nama, ID, atau nomor HP...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(customerSearchQueryProvider.notifier).state = '';
                          ref.read(customerPageProvider.notifier).state = 1;
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
          if (statusFilter != 'all')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('Status: $statusFilter'),
                    onDeleted: () {
                      ref.read(customerStatusFilterProvider.notifier).state = 'all';
                      ref.read(customerPageProvider.notifier).state = 1;
                    },
                  ),
                ],
              ),
            ),

          // Customer List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(customersProvider);
              },
              child: customersAsync.when(
                data: (customers) {
                  print('✅ [CustomersPage] Data loaded: ${customers.length} customers');
                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.isNotEmpty
                                ? 'Tidak ada pelanggan ditemukan'
                                : 'Belum ada pelanggan',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (searchQuery.isEmpty)
                            TextButton.icon(
                              onPressed: () => _navigateToAddCustomer(),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Pelanggan'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return CustomerCard(
                        customer: customer,
                        onTap: () => _navigateToDetail(customer.id!),
                        onEdit: () => _navigateToEdit(customer),
                        onDelete: () => _confirmDelete(customer),
                        onToggleStatus: () => _toggleStatus(customer),
                      );
                    },
                  );
                },
                loading: () {
                  print('⏳ [CustomersPage] Loading customers...');
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
                error: (error, stack) {
                  print('❌ [CustomersPage] Error: $error');
                  print('Stack trace: $stack');
                  return Center(
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
                          onPressed: () => ref.invalidate(customersProvider),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFabMenu(),
    );
    } catch (e, stack) {
      print('❌ [CustomersPage] Build error: $e');
      print('Stack: $stack');
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'CustomersPage Build Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  void _navigateToAddCustomer() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CustomerFormPage(),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(customersProvider);
        ref.invalidate(customerStatsProvider);
      }
    });
  }

  void _navigateToEdit(ProfileModel customer) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerFormPage(customer: customer),
      ),
    ).then((result) {
      if (result == true) {
        ref.invalidate(customersProvider);
        ref.invalidate(customerStatsProvider);
      }
    });
  }

  void _navigateToDetail(String customerId) {
    context.push('/admin/customers/$customerId');
  }

  Future<void> _confirmDelete(ProfileModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text(
          'Yakin ingin menghapus ${customer.fullName}?\n\nData pelanggan dan semua tagihan terkait akan dihapus.',
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
        await ref.read(customerControllerProvider.notifier).deleteCustomer(customer.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelanggan berhasil dihapus')),
          );
          ref.invalidate(customersProvider);
          ref.invalidate(customerStatsProvider);
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

  Future<void> _toggleStatus(ProfileModel customer) async {
    try {
      await ref.read(customerControllerProvider.notifier).toggleStatus(
            customer.id!,
            customer.status ?? 'NONAKTIF',
          );
      if (mounted) {
        final newStatus = customer.status == 'AKTIF' ? 'NONAKTIF' : 'AKTIF';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status diubah menjadi $newStatus')),
        );
        ref.invalidate(customersProvider);
        ref.invalidate(customerStatsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Widget _buildFabMenu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabMenuOpen) ...[
          _buildFabMenuItem(
            label: 'Kelola Paket',
            icon: Icons.inventory_2,
            onTap: () {
              setState(() => _isFabMenuOpen = false);
              context.push('/admin/packages');
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            label: 'Import CSV',
            icon: Icons.upload_file,
            onTap: () {
              setState(() => _isFabMenuOpen = false);
              _showImportCSVDialog();
            },
          ),
          const SizedBox(height: 12),
          _buildFabMenuItem(
            label: 'Tambah Pelanggan',
            icon: Icons.person_add,
            onTap: () {
              setState(() => _isFabMenuOpen = false);
              _navigateToAddCustomer();
            },
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: () {
            setState(() => _isFabMenuOpen = !_isFabMenuOpen);
          },
          child: AnimatedRotation(
            turns: _isFabMenuOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_isFabMenuOpen ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildFabMenuItem({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          mini: true,
          onPressed: onTap,
          child: Icon(icon),
        ),
      ],
    );
  }

  void _showImportCSVDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import CSV'),
        content: const Text(
          'Fitur import CSV akan segera tersedia.\n\n'
          'Anda akan dapat mengimpor data pelanggan dalam jumlah besar menggunakan file CSV.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
