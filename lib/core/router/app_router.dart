import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/admin/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/customers/presentation/pages/customers_page.dart';
import '../../features/admin/customers/presentation/pages/customer_detail_page.dart';
import '../../features/admin/invoices/presentation/pages/invoices_page.dart';
import '../../features/admin/invoices/presentation/pages/invoice_detail_page.dart';
import '../../features/admin/packages/presentation/pages/packages_page.dart';
import '../../features/admin/expenses/presentation/pages/expenses_page.dart';
import '../../features/admin/reports/presentation/pages/reports_page.dart';
import '../../features/admin/notifications/presentation/pages/notifications_page.dart';
import '../../features/admin/settings/presentation/pages/app_settings_page.dart';
import '../../features/admin/settings/presentation/pages/payment_methods_page.dart';
import '../../features/admin/settings/presentation/pages/advanced_settings_page.dart';
import '../../features/customer/dashboard/presentation/pages/customer_dashboard_page.dart';
import '../../features/customer/profile/presentation/pages/customer_profile_page.dart';
import '../../features/customer/invoices/presentation/pages/customer_invoices_page.dart';
import '../../features/customer/wifi/presentation/pages/wifi_settings_page.dart';
import '../../features/customer/payment_info/presentation/pages/payment_info_page.dart';
import '../../data/providers/auth_provider.dart';
import '../widgets/admin_scaffold.dart';
import '../widgets/customer_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/splash';

      // If not logged in and not on login/register page, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isSplash) {
        return '/login';
      }

      // If logged in and on login page, redirect based on role
      if (isLoggedIn && isLoggingIn) {
        final user = authState.value;
        return user?.isAdmin == true ? '/admin/dashboard' : '/customer/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),

      // Admin Routes (with bottom navigation)
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: const AdminDashboardPage(),
        ),
      ),
      GoRoute(
        path: '/admin/customers',
        builder: (context, state) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: const CustomersPage(),
        ),
      ),
      GoRoute(
        path: '/admin/customers/:id',
        builder: (context, state) {
          final customerId = state.pathParameters['id']!;
          return AdminScaffold(
            currentRoute: '/admin/customers',
            child: CustomerDetailPage(customerId: customerId),
          );
        },
      ),
      GoRoute(
        path: '/admin/invoices',
        builder: (context, state) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: const InvoicesPage(),
        ),
      ),
      GoRoute(
        path: '/admin/invoices/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminScaffold(
            currentRoute: '/admin/invoices',
            child: InvoiceDetailPage(invoiceId: id),
          );
        },
      ),
      GoRoute(
        path: '/admin/packages',
        builder: (context, state) => const PackagesPage(),
      ),
      GoRoute(
        path: '/admin/expenses',
        builder: (context, state) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: const ExpensesPage(),
        ),
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/admin/notifications',
        builder: (context, state) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: const NotificationsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/settings',
        builder: (context, state) => AdminScaffold(
          currentRoute: state.matchedLocation,
          child: const AppSettingsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/payment-methods',
        builder: (context, state) => AdminScaffold(
          currentRoute: '/admin/settings', // Part of settings
          child: const PaymentMethodsPage(),
        ),
      ),
      GoRoute(
        path: '/admin/advanced-settings',
        builder: (context, state) => AdminScaffold(
          currentRoute: '/admin/settings', // Part of settings
          child: const AdvancedSettingsPage(),
        ),
      ),

      // Customer Routes
      GoRoute(
        path: '/customer/dashboard',
        builder: (context, state) => CustomerScaffold(
          currentRoute: state.matchedLocation,
          child: const CustomerDashboardPage(),
        ),
      ),
      GoRoute(
        path: '/customer/profile',
        builder: (context, state) => CustomerScaffold(
          currentRoute: state.matchedLocation,
          child: const CustomerProfilePage(),
        ),
      ),
      GoRoute(
        path: '/customer/invoices',
        builder: (context, state) => CustomerScaffold(
          currentRoute: state.matchedLocation,
          child: const CustomerInvoicesPage(),
        ),
      ),
      GoRoute(
        path: '/customer/payment-info',
        builder: (context, state) => CustomerScaffold(
          currentRoute: state.matchedLocation,
          child: const PaymentInfoPage(),
        ),
      ),
      GoRoute(
        path: '/customer/wifi',
        builder: (context, state) => CustomerScaffold(
          currentRoute: state.matchedLocation,
          child: const WifiSettingsPage(),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
