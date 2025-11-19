import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../models/profile_model.dart';

class DashboardStats {
  final double totalRevenue;
  final double totalExpenses;
  final double profit;
  final int activeCustomers;
  final int inactiveCustomers;
  final int unpaidInvoicesCount;
  final int paidInvoicesCount;

  DashboardStats({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.profit,
    required this.activeCustomers,
    required this.inactiveCustomers,
    required this.unpaidInvoicesCount,
    required this.paidInvoicesCount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      activeCustomers: json['active_customers'] as int? ?? 0,
      inactiveCustomers: json['inactive_customers'] as int? ?? 0,
      unpaidInvoicesCount: json['unpaid_invoices_count'] as int? ?? 0,
      paidInvoicesCount: json['paid_invoices_count'] as int? ?? 0,
    );
  }

  // Computed properties for compatibility
  int get totalCustomers => activeCustomers + inactiveCustomers;
  int get unpaidInvoices => unpaidInvoicesCount;
  int get paidInvoices => paidInvoicesCount;
  int get installmentInvoices => 0; // Not provided by RPC
}

class DashboardChartsData {
  final List<double> revenueData;
  final List<double> expensesData;
  final List<double> profitData;
  final List<int> customerGrowthData;
  final List<int> customerTotalData;
  final List<int> customerNetData;
  final List<String> labels;
  final Map<String, int> invoiceStatusCounts;

  DashboardChartsData({
    required this.revenueData,
    required this.expensesData,
    required this.profitData,
    required this.customerGrowthData,
    required this.customerTotalData,
    required this.customerNetData,
    required this.labels,
    required this.invoiceStatusCounts,
  });

  factory DashboardChartsData.fromJson(Map<String, dynamic> json) {
    return DashboardChartsData(
      revenueData: (json['revenue_data'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      expensesData: (json['expenses_data'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      profitData: (json['profit_data'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      customerGrowthData: (json['customer_growth_data'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      customerTotalData: (json['customer_total_data'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      customerNetData: (json['customer_net_data'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      labels:
          (json['labels_data'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      invoiceStatusCounts: {
        'paid': (json['invoice_status_counts']?['paid'] as int?) ?? 0,
        'partially_paid':
            (json['invoice_status_counts']?['partially_paid'] as int?) ?? 0,
        'unpaid': (json['invoice_status_counts']?['unpaid'] as int?) ?? 0,
      },
    );
  }
}

class MonthlyRevenue {
  final String month;
  final double amount;

  MonthlyRevenue({required this.month, required this.amount});
}

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  /// Get dashboard statistics using RPC function
  Future<DashboardStats> getDashboardStats({
    int? month,
    int? year,
  }) async {
    try {
      final now = DateTime.now();
      final filterMonth = month ?? 0; // 0 = all months
      final filterYear = year ?? now.year;

      final response = await _supabase.rpc(
        'get_dashboard_stats',
        params: {
          'p_month': filterMonth,
          'p_year': filterYear,
        },
      );

      if (response == null || (response as List).isEmpty) {
        throw Exception('No data returned from get_dashboard_stats');
      }

      final data = (response as List).first as Map<String, dynamic>;
      return DashboardStats.fromJson(data);
    } catch (e) {
      throw Exception('Failed to fetch dashboard stats: $e');
    }
  }

  /// Get dashboard charts data using RPC function
  Future<DashboardChartsData> getDashboardChartsData({int months = 6}) async {
    try {
      print('🔵 [DashboardRepo] Fetching charts data for $months months...');
      
      final response = await _supabase.rpc(
        'get_dashboard_charts_data',
        params: {'p_months': months},
      );

      if (response == null) {
        throw Exception('No data returned from get_dashboard_charts_data');
      }

      print('✅ [DashboardRepo] Charts data fetched successfully');
      return DashboardChartsData.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ [DashboardRepo] Charts data error: $e');
      
      // Fallback: Return empty data instead of throwing
      print('⚠️ [DashboardRepo] Using empty charts data as fallback');
      return DashboardChartsData(
        labels: [],
        revenueData: [],
        customerData: [],
      );
    }
  }

  /// Get monthly revenue for chart (using charts data)
  Future<List<MonthlyRevenue>> getMonthlyRevenue({int months = 6}) async {
    try {
      final chartsData = await getDashboardChartsData(months: months);

      final List<MonthlyRevenue> monthlyData = [];
      for (int i = 0; i < chartsData.labels.length; i++) {
        monthlyData.add(MonthlyRevenue(
          month: chartsData.labels[i],
          amount: chartsData.revenueData[i],
        ));
      }

      return monthlyData;
    } catch (e) {
      throw Exception('Failed to fetch monthly revenue: $e');
    }
  }

  /// Get all customers using RPC function
  Future<List<ProfileModel>> getAllCustomers({
    String filter = 'all',
    String searchTerm = '',
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_all_customers',
        params: {
          'p_filter': filter,
          'p_search_term': searchTerm,
        },
      );

      if (response == null) {
        return [];
      }

      return (response as List)
          .map((e) => ProfileModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// Get recent invoices
  Future<List<InvoiceModel>> getRecentInvoices({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('invoices')
          .select('*, profiles!invoices_customer_id_fkey(full_name, idpl)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => InvoiceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent invoices: $e');
    }
  }

  /// Get recent customers
  Future<List<ProfileModel>> getRecentCustomers({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'USER')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((e) => ProfileModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent customers: $e');
    }
  }

  /// Get customer by ID
  Future<ProfileModel?> getCustomerById(String customerId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', customerId)
          .single();

      return ProfileModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  /// Get customer invoices
  Future<List<InvoiceModel>> getCustomerInvoices(String customerId) async {
    try {
      final response = await _supabase
          .from('invoices')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => InvoiceModel.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer invoices: $e');
    }
  }
}
