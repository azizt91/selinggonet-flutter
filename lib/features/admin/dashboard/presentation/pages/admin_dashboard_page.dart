import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/dashboard_provider.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/notification_provider.dart';
import '../../../notifications/presentation/pages/admin_notifications_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  bool _showProfit = true, _showPendapatan = true, _showPengeluaran = true;
  final _months = ['Semua Bulan','Januari','Februari','Maret','April','Mei','Juni','Juli','Agustus','September','Oktober','November','Desember'];

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(dashboardStatsProvider);
    final charts = ref.watch(dashboardChartsProvider);
    final user = ref.watch(currentUserProvider);
    final month = ref.watch(selectedMonthProvider);
    final year = ref.watch(selectedYearProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: Column(children: [
          // Fixed Header
          _header(user, month, year),
          // Scrollable Content
          Expanded(child: RefreshIndicator(
            onRefresh: () async { ref.invalidate(dashboardStatsProvider); ref.invalidate(dashboardChartsProvider); },
            child: ListView(padding: EdgeInsets.zero, children: [
              Padding(padding: const EdgeInsets.all(16), child: stats.when(
                data: (s) => _statsCards(context, s),
                loading: () => _loading(),
                error: (e, _) => _error(e.toString()))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: charts.when(
                data: (d) => _chartsSection(d),
                loading: () => _chartsLoading(),
                error: (_, __) => const SizedBox.shrink())),
              const SizedBox(height: 100),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _header(AsyncValue<dynamic> user, int month, int year) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF667EEA), Color(0xFF5324E0)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
      child: SafeArea(bottom: false, child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 18), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [_avatar(user), const SizedBox(width: 10), Expanded(child: _userInfo(user)),
          // Notification Bell with Badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminNotificationsPage())),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              unreadCount.when(
                data: (count) => count > 0
                    ? Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(icon: const Icon(Icons.logout, color: Colors.white, size: 22), onPressed: _logout, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36))]),
        const SizedBox(height: 6),
        Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now()), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: _monthFilter(month)), const SizedBox(width: 10), Expanded(child: _yearFilter(year))]),
      ]))));
  }

  Widget _avatar(AsyncValue<dynamic> u) => u.when(
    data: (user) => Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3),
      image: user?.photoUrl != null ? DecorationImage(image: NetworkImage(user!.photoUrl!), fit: BoxFit.cover) : null),
      child: user?.photoUrl == null ? Center(child: Text(user?.fullName?.substring(0, 1).toUpperCase() ?? 'A', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))) : null),
    loading: () => Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3))),
    error: (_, __) => Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.3)), child: const Icon(Icons.person, color: Colors.white)));

  Widget _userInfo(AsyncValue<dynamic> u) => u.when(
    data: (user) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Hallo, ${user?.fullName ?? "Admin"}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10), overflow: TextOverflow.ellipsis)]),
    loading: () => const Text('Memuat...', style: TextStyle(color: Colors.white, fontSize: 14)),
    error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white)));

  Widget _monthFilter(int v) => Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(child: DropdownButton<int>(value: v, isExpanded: true, dropdownColor: const Color(0xFF667EEA), isDense: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      items: List.generate(_months.length, (i) => DropdownMenuItem(value: i, child: Text(_months[i]))),
      onChanged: (x) => x != null ? ref.read(selectedMonthProvider.notifier).state = x : null)));

  Widget _yearFilter(int v) => Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
    child: DropdownButtonHideUnderline(child: DropdownButton<int>(value: v, isExpanded: true, dropdownColor: const Color(0xFF667EEA), isDense: true,
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
      items: List.generate(4, (i) => DropdownMenuItem(value: DateTime.now().year - i, child: Text((DateTime.now().year - i).toString()))),
      onChanged: (x) => x != null ? ref.read(selectedYearProvider.notifier).state = x : null)));

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Konfirmasi'), content: const Text('Yakin ingin keluar?'),
      actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Keluar'))]));
    if (ok == true && mounted) { await ref.read(authControllerProvider).logout(); if (mounted) context.go('/login'); }
  }

  Widget _statsCards(BuildContext ctx, dynamic s) {
    final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final month = ref.read(selectedMonthProvider);
    final year = ref.read(selectedYearProvider);
    return Column(children: [
      _largeCard('Profit', f.format(s.profit), Icons.account_balance_wallet, [const Color(0xFF9969C7), const Color(0xFF6A359C)], _showProfit, () => setState(() => _showProfit = !_showProfit)),
      const SizedBox(height: 10),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.2, children: [
        _smallToggle('Pendapatan', f.format(s.totalRevenue), Icons.trending_up, [const Color(0xFF004e92), const Color(0xFF000428)], _showPendapatan, () => setState(() => _showPendapatan = !_showPendapatan)),
        _smallToggle('Pengeluaran', f.format(s.totalExpenses), Icons.trending_down, [const Color(0xFF485563), const Color(0xFF29323c)], _showPengeluaran, () => setState(() => _showPengeluaran = !_showPengeluaran)),
        _smallCard('Pelanggan Aktif', s.activeCustomers.toString(), Icons.people, [const Color(0xFF1e3c72), const Color(0xFF2a5298)], () => ctx.push('/admin/customers?status=AKTIF')),
        _smallCard('Pelanggan Tdk Aktif', s.inactiveCustomers.toString(), Icons.person_off, [const Color(0xFF614385), const Color(0xFF516395)], () => ctx.push('/admin/customers?status=NONAKTIF')),
        _smallCard('Belum Bayar', s.unpaidInvoicesCount.toString(), Icons.schedule, [const Color(0xFF4e4376), const Color(0xFF2b5876)], () => ctx.push('/admin/invoices?status=unpaid&bulan=$month&tahun=$year')),
        _smallCard('Lunas', s.paidInvoicesCount.toString(), Icons.check_circle, [const Color(0xFF141e30), const Color(0xFF243b55)], () => ctx.push('/admin/invoices?status=paid&bulan=$month&tahun=$year')),
      ])]);
  }

  Widget _largeCard(String l, String v, IconData icon, List<Color> g, bool vis, VoidCallback t) => Container(
    width: double.infinity,
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g), borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: g[0].withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))]),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Icon(icon, size: 32, color: Colors.white.withOpacity(0.9)),
        _eye(vis, t)]),
      const SizedBox(height: 8),
      Text(l, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 2),
      Text(vis ? v : 'Rp •••••••', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)]));

  Widget _smallToggle(String l, String v, IconData icon, List<Color> g, bool vis, VoidCallback t) => Container(
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g), borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: g[0].withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]),
    padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, size: 28, color: Colors.white.withOpacity(0.9)), _eye(vis, t, s: true)]),
      const Spacer(),
      Text(l, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(vis ? v : 'Rp •••••••', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)]));

  Widget _smallCard(String l, String v, IconData icon, List<Color> g, VoidCallback? tap) => GestureDetector(onTap: tap, child: Container(
    clipBehavior: Clip.hardEdge,
    decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g), borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: g[0].withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))]),
    padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, size: 28, color: Colors.white.withOpacity(0.9)), if (tap != null) Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white.withOpacity(0.7))]),
      const Spacer(),
      Text(l, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13, fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(v, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      if (tap != null) ...[const SizedBox(height: 4), Text('👆 Ketuk untuk detail', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10))]])));

  Widget _eye(bool vis, VoidCallback t, {bool s = false}) => GestureDetector(onTap: t, child: Container(padding: EdgeInsets.all(s ? 6 : 8),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
    child: Icon(vis ? Icons.visibility : Icons.visibility_off, color: Colors.white.withOpacity(0.9), size: s ? 16 : 20)));

  Widget _chartsSection(dynamic d) => d == null ? const SizedBox.shrink() : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _chartCardWithLegend('Pendapatan, Pengeluaran & Profit', '6 bulan terakhir', SizedBox(height: 220, child: _revenueChart(d)),
      legends: [('Pendapatan', const Color(0xFF10B981)), ('Pengeluaran', const Color(0xFFEF4444)), ('Profit', const Color(0xFF8B5CF6))]),
    const SizedBox(height: 16),
    _chartCard('Status Pembayaran', 'Bulan ini', SizedBox(height: 200, child: _paymentChart(d))),
    const SizedBox(height: 16),
    _chartCard('Pertumbuhan Pelanggan', 'Baru vs Cabut', SizedBox(height: 200, child: _growthChart(d))),
    const SizedBox(height: 16),
    _chartCard('Total Pelanggan Aktif', 'Kumulatif 6 bulan', SizedBox(height: 200, child: _totalChart(d)))]);

  Widget _chartCard(String t, String s, Widget c) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
        Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)), const SizedBox(width: 6), Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))])]),
      const SizedBox(height: 16), c]));

  Widget _chartCardWithLegend(String t, String s, Widget c, {required List<(String, Color)> legends}) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Flexible(child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)))),
        Text(s, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))]),
      const SizedBox(height: 10),
      Wrap(spacing: 16, runSpacing: 6, children: legends.map((l) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: l.$2, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(l.$1, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)))])).toList()),
      const SizedBox(height: 12), c]));

  Widget _revenueChart(dynamic d) {
    final lb = d.labels as List<String>? ?? [];
    final rv = d.revenueData as List<double>? ?? [];
    final ex = d.expensesData as List<double>? ?? [];
    final pf = d.profitData as List<double>? ?? [];
    if (lb.isEmpty || rv.isEmpty) return _noData();
    
    // Gabungkan semua data untuk menentukan interval
    final allData = [...rv, ...ex, ...pf];
    
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: _int(allData.map((e) => e as num).toList())),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(_cmp(v), style: const TextStyle(fontSize: 8, color: Colors.grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, _) { final i = v.toInt(); return i >= 0 && i < lb.length && v == i.toDouble() ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(lb[i], style: const TextStyle(fontSize: 7, color: Colors.grey))) : const SizedBox.shrink(); })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), 
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false), 
      lineBarsData: [
        // Pendapatan - Hijau
        LineChartBarData(spots: rv.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: const Color(0xFF10B981), barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xFF10B981).withOpacity(0.1))),
        // Pengeluaran - Merah
        if (ex.isNotEmpty) LineChartBarData(spots: ex.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: const Color(0xFFEF4444), barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xFFEF4444).withOpacity(0.1))),
        // Profit - Ungu
        if (pf.isNotEmpty) LineChartBarData(spots: pf.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: const Color(0xFF8B5CF6), barWidth: 2.5, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: const Color(0xFF8B5CF6).withOpacity(0.1)))]));
  }

  Widget _paymentChart(dynamic d) {
    final counts = d.invoiceStatusCounts as Map<String, int>? ?? {};
    if (counts.isEmpty) return _noData();
    final lb = ['Lunas', 'Cicilan', 'Belum Bayar'];
    final vl = [counts['paid'] ?? 0, counts['partially_paid'] ?? 0, counts['unpaid'] ?? 0];
    final cl = [const Color(0xFF10B981), const Color(0xFFF59E0B), const Color(0xFFEF4444)];
    return Row(children: [Expanded(flex: 2, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 30, sections: vl.asMap().entries.map((e) {
      final t = vl.fold<int>(0, (a, b) => a + b); final p = t > 0 ? (e.value / t * 100) : 0;
      return PieChartSectionData(value: e.value.toDouble(), color: cl[e.key % cl.length], radius: 22, title: '${p.toStringAsFixed(0)}%', titleStyle: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white));
    }).toList()))), const SizedBox(width: 10),
      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: lb.asMap().entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: cl[e.key % cl.length], borderRadius: BorderRadius.circular(2))), const SizedBox(width: 4), Expanded(child: Text(e.value, style: const TextStyle(fontSize: 9), overflow: TextOverflow.ellipsis))]))).toList()))]);
  }

  Widget _growthChart(dynamic d) {
    final lb = d.labels as List<String>? ?? [];
    final nw = d.customerGrowthData as List<int>? ?? [];
    final ch = d.customerNetData as List<int>? ?? [];
    if (lb.isEmpty || nw.isEmpty) return _noData();
    return BarChart(BarChartData(gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 8, color: Colors.grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, _) { final i = v.toInt(); return i >= 0 && i < lb.length && v == i.toDouble() ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(lb[i], style: const TextStyle(fontSize: 7, color: Colors.grey))) : const SizedBox.shrink(); })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false), barGroups: List.generate(lb.length, (i) => BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: nw[i].toDouble(), color: const Color(0xFF10B981), width: 8, borderRadius: BorderRadius.circular(2)),
        if (ch.isNotEmpty && i < ch.length) BarChartRodData(toY: ch[i].abs().toDouble(), color: const Color(0xFFEF4444), width: 8, borderRadius: BorderRadius.circular(2))]))));
  }

  Widget _totalChart(dynamic d) {
    final lb = d.labels as List<String>? ?? [];
    final vl = d.customerTotalData as List<int>? ?? [];
    if (lb.isEmpty || vl.isEmpty) return _noData();
    return LineChart(LineChartData(gridData: const FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (v, _) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 8, color: Colors.grey)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, _) { final i = v.toInt(); return i >= 0 && i < lb.length && v == i.toDouble() ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(lb[i], style: const TextStyle(fontSize: 7, color: Colors.grey))) : const SizedBox.shrink(); })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: vl.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(), isCurved: true, color: const Color(0xFF8B5CF6), barWidth: 2,
        dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(radius: 3, color: const Color(0xFF8B5CF6), strokeWidth: 1, strokeColor: Colors.white)),
        belowBarData: BarAreaData(show: true, color: const Color(0xFF8B5CF6).withOpacity(0.1)))]));
  }

  double _int(List<num> v) => v.isEmpty ? 1 : (v.reduce((a, b) => a > b ? a : b) / 4).ceilToDouble().clamp(1, double.infinity);
  String _cmp(double v) => v >= 1000000 ? '${(v / 1000000).toStringAsFixed(1)}jt' : v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}rb' : v.toInt().toString();
  Widget _noData() => const Center(child: Text('No data', style: TextStyle(color: Colors.grey, fontSize: 11)));

  Widget _loading() => LayoutBuilder(builder: (context, constraints) {
    final smallCardWidth = (constraints.maxWidth - 8) / 2;
    final smallCardHeight = smallCardWidth / 1.45;
    return Column(children: [
      _skeletonLargeCard(height: smallCardHeight),
      const SizedBox(height: 10),
      GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.15,
        children: List.generate(6, (_) => _skeletonSmallCard()))]);
  });

  Widget _chartsLoading() => Column(children: List.generate(4, (_) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _skeletonChartCard())));

  Widget _skeletonLargeCard({required double height}) => Shimmer.fromColors(
    baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
    child: Container(width: double.infinity, height: height,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 32, height: 32, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 50, height: 10, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 8),
          Container(width: 120, height: 18, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))])),
        Container(width: 28, height: 28, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(6)))])));

  Widget _skeletonSmallCard() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
    child: Container(
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
          Container(width: 20, height: 20, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))]),
        const SizedBox(height: 8),
        Container(width: 60, height: 8, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 4),
        Container(width: 80, height: 12, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))])));

  Widget _skeletonChartCard() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!,
    child: Container(height: 200,
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4))),
          Container(width: 60, height: 10, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)))]),
        const SizedBox(height: 16),
        Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(8))))])));

  Widget _error(String m) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(children: [const Icon(Icons.error_outline, size: 36, color: Colors.red), const SizedBox(height: 10), const Text('Gagal memuat data', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4), Text(m, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.grey))]));
}


