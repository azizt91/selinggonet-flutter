import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../data/providers/auth_provider.dart';

// Report Data Model
class ReportData {
  final List<ReportItem> items;
  final double totalPendapatan;
  final double totalLunas;
  final double totalUnpaid;
  final double totalInstallment;
  final double totalPengeluaran;
  final int countLunas;
  final int countUnpaid;
  final int countInstallment;
  final int countPengeluaran;

  ReportData({
    required this.items,
    required this.totalPendapatan,
    required this.totalLunas,
    required this.totalUnpaid,
    required this.totalInstallment,
    required this.totalPengeluaran,
    required this.countLunas,
    required this.countUnpaid,
    required this.countInstallment,
    required this.countPengeluaran,
  });
}

class ReportItem {
  final String type; // 'income' or 'expense'
  final DateTime date;
  final String customerName;
  final String customerId;
  final String description;
  final double amount;
  final String status;
  final String paymentMethod;

  ReportItem({
    required this.type,
    required this.date,
    required this.customerName,
    required this.customerId,
    required this.description,
    required this.amount,
    required this.status,
    required this.paymentMethod,
  });
}

// Filter State
class ReportFilter {
  final String periode;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;

  ReportFilter({this.periode = 'all', this.status = 'all', this.startDate, this.endDate});
}

final reportFilterProvider = StateProvider<ReportFilter>((ref) => ReportFilter());

final reportDataProvider = FutureProvider.autoDispose<ReportData>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final filter = ref.watch(reportFilterProvider);

  // Fetch invoices
  final invoicesResponse = await supabase.from('invoices').select('*, profiles:customer_id(full_name, idpl)').order('created_at', ascending: false);
  
  // Fetch expenses
  final expensesResponse = await supabase.from('expenses').select('*').order('expense_date', ascending: false);

  final invoices = invoicesResponse as List;
  final expenses = expensesResponse as List;

  // Filter by date
  List<dynamic> filteredInvoices = invoices;
  List<dynamic> filteredExpenses = expenses;

  if (filter.periode != 'all' || filter.startDate != null) {
    final now = DateTime.now();
    DateTime? start;
    DateTime? end;

    switch (filter.periode) {
      case 'bulan-ini':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0);
        break;
      case 'bulan-lalu':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0);
        break;
      case '3-bulan':
        start = DateTime(now.year, now.month - 3, now.day);
        break;
      case 'tahun-ini':
        start = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        start = filter.startDate;
        end = filter.endDate;
        break;
    }

    if (start != null) {
      filteredInvoices = invoices.where((inv) {
        final date = DateTime.tryParse(inv['created_at']?.toString() ?? '');
        if (date == null) return false;
        if (end != null) return date.isAfter(start!) && date.isBefore(end.add(const Duration(days: 1)));
        return date.isAfter(start!);
      }).toList();

      filteredExpenses = expenses.where((exp) {
        final date = DateTime.tryParse(exp['expense_date']?.toString() ?? '');
        if (date == null) return false;
        if (end != null) return date.isAfter(start!) && date.isBefore(end.add(const Duration(days: 1)));
        return date.isAfter(start!);
      }).toList();
    }
  }

  // Filter by status
  if (filter.status != 'all') {
    filteredInvoices = filteredInvoices.where((inv) => inv['status'] == filter.status).toList();
  }

  // Build report items
  final items = <ReportItem>[];

  for (final inv in filteredInvoices) {
    final profile = inv['profiles'] as Map<String, dynamic>?;
    items.add(ReportItem(
      type: 'income',
      date: DateTime.tryParse(inv['paid_at']?.toString() ?? inv['created_at']?.toString() ?? '') ?? DateTime.now(),
      customerName: profile?['full_name']?.toString() ?? 'N/A',
      customerId: profile?['idpl']?.toString() ?? 'N/A',
      description: inv['invoice_period']?.toString() ?? '-',
      amount: inv['status'] == 'paid' ? (inv['total_due'] as num?)?.toDouble() ?? 0 : (inv['amount'] as num?)?.toDouble() ?? 0,
      status: inv['status']?.toString() ?? 'unpaid',
      paymentMethod: inv['payment_method']?.toString() ?? '-',
    ));
  }

  for (final exp in filteredExpenses) {
    items.add(ReportItem(
      type: 'expense',
      date: DateTime.tryParse(exp['expense_date']?.toString() ?? '') ?? DateTime.now(),
      customerName: '-',
      customerId: '-',
      description: exp['description']?.toString() ?? '-',
      amount: (exp['amount'] as num?)?.toDouble() ?? 0,
      status: 'expense',
      paymentMethod: '-',
    ));
  }

  // Sort by date
  items.sort((a, b) => b.date.compareTo(a.date));

  // Calculate totals
  final paid = filteredInvoices.where((inv) => inv['status'] == 'paid').toList();
  final unpaid = filteredInvoices.where((inv) => inv['status'] == 'unpaid').toList();
  final installment = filteredInvoices.where((inv) => inv['status'] == 'partially_paid').toList();

  return ReportData(
    items: items,
    totalPendapatan: paid.fold(0.0, (sum, inv) => sum + ((inv['total_due'] as num?)?.toDouble() ?? 0)),
    totalLunas: paid.fold(0.0, (sum, inv) => sum + ((inv['total_due'] as num?)?.toDouble() ?? 0)),
    totalUnpaid: unpaid.fold(0.0, (sum, inv) => sum + ((inv['amount'] as num?)?.toDouble() ?? 0)),
    totalInstallment: installment.fold(0.0, (sum, inv) => sum + ((inv['amount_paid'] as num?)?.toDouble() ?? 0)),
    totalPengeluaran: filteredExpenses.fold(0.0, (sum, exp) => sum + ((exp['amount'] as num?)?.toDouble() ?? 0)),
    countLunas: paid.length,
    countUnpaid: unpaid.length,
    countInstallment: installment.length,
    countPengeluaran: filteredExpenses.length,
  );
});

class AdminReportsPage extends ConsumerStatefulWidget {
  const AdminReportsPage({super.key});
  @override
  ConsumerState<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends ConsumerState<AdminReportsPage> {
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final reportData = ref.watch(reportDataProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F8FB),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: reportData.when(
                data: (data) => _buildContent(data),
                loading: () => _buildLoading(),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Color(0xFF110E1B))),
              const Expanded(child: Text('Laporan', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF110E1B)))),
              GestureDetector(onTap: _showFilterModal, child: const Icon(Icons.filter_list, color: Color(0xFF110E1B))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ReportData data) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(reportDataProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary Cards
          _buildSummaryCards(data),
          const SizedBox(height: 16),
          // Data Table
          _buildDataTable(data),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ReportData data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Pendapatan', _currencyFormat.format(data.totalPendapatan), '${data.countLunas} Transaksi', const Color(0xFF22C55E))),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Lunas', _currencyFormat.format(data.totalLunas), '${data.countLunas} Tagihan', const Color(0xFF3B82F6))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildSummaryCard('Belum Bayar', _currencyFormat.format(data.totalUnpaid), '${data.countUnpaid} Tagihan', const Color(0xFFEF4444))),
            const SizedBox(width: 12),
            Expanded(child: _buildSummaryCard('Cicilan', _currencyFormat.format(data.totalInstallment), '${data.countInstallment} Tagihan', const Color(0xFFF97316))),
          ],
        ),
        const SizedBox(height: 12),
        _buildSummaryCard('Pengeluaran', _currencyFormat.format(data.totalPengeluaran), '${data.countPengeluaran} Pengeluaran', const Color(0xFF8B5CF6), fullWidth: true),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtitle, Color color, {bool fullWidth = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildDataTable(ReportData data) {
    if (data.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Column(
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Tidak ada data', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Data Transaksi (${data.items.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 1),
          ...data.items.take(50).map((item) => _buildDataRow(item)),
          if (data.items.length > 50)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('... dan ${data.items.length - 50} data lainnya', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
        ],
      ),
    );
  }

  Widget _buildDataRow(ReportItem item) {
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
    final isExpense = item.type == 'expense';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6)))),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.customerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(item.description, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(dateFormat.format(item.date), style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '${isExpense ? '-' : '+'}${_currencyFormat.format(item.amount)}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isExpense ? const Color(0xFF8B5CF6) : const Color(0xFF22C55E)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))), const SizedBox(width: 12), Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))))]),
          const SizedBox(height: 12),
          Row(children: [Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)))), const SizedBox(width: 12), Expanded(child: Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))))]),
          const SizedBox(height: 16),
          Container(height: 300, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }

  Future<void> _showFilterModal() async {
    final filter = ref.read(reportFilterProvider);
    String selectedPeriode = filter.periode;
    String selectedStatus = filter.status;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Filter Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(onTap: () => Navigator.pop(ctx), child: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Periode', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedPeriode,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua Periode')),
                  DropdownMenuItem(value: 'bulan-ini', child: Text('Bulan Ini')),
                  DropdownMenuItem(value: 'bulan-lalu', child: Text('Bulan Lalu')),
                  DropdownMenuItem(value: '3-bulan', child: Text('3 Bulan Terakhir')),
                  DropdownMenuItem(value: 'tahun-ini', child: Text('Tahun Ini')),
                ],
                onChanged: (v) => setModalState(() => selectedPeriode = v ?? 'all'),
              ),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua Status')),
                  DropdownMenuItem(value: 'paid', child: Text('Lunas')),
                  DropdownMenuItem(value: 'partially_paid', child: Text('Cicilan')),
                  DropdownMenuItem(value: 'unpaid', child: Text('Belum Bayar')),
                ],
                onChanged: (v) => setModalState(() => selectedStatus = v ?? 'all'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(reportFilterProvider.notifier).state = ReportFilter();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(reportFilterProvider.notifier).state = ReportFilter(periode: selectedPeriode, status: selectedStatus);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF683FE4)),
                      child: const Text('Terapkan', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
