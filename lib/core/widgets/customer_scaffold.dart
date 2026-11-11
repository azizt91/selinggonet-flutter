import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class CustomerScaffold extends StatefulWidget {
  final Widget child;
  final String currentRoute;

  const CustomerScaffold({
    super.key,
    required this.child,
    required this.currentRoute,
  });

  @override
  State<CustomerScaffold> createState() => _CustomerScaffoldState();
}

class _CustomerScaffoldState extends State<CustomerScaffold> {
  static final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _getSelectedIndex() {
    if (widget.currentRoute.contains('/customer/dashboard')) return 0;
    if (widget.currentRoute.contains('/customer/invoices')) return 1;
    if (widget.currentRoute.contains('/customer/help')) return 2;
    if (widget.currentRoute.contains('/customer/profile') ||
        widget.currentRoute.contains('/customer/wifi') ||
        widget.currentRoute.contains('/customer/payment-info')) return 3;
    return 0;
  }

  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isActive = _getSelectedIndex() == index;
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.customerBlueSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon),
      ),
      label: label,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // For iOS
      ),
      child: Scaffold(
      key: _scaffoldKey,
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _getSelectedIndex(),
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/customer/dashboard');
              break;
            case 1:
              context.go('/customer/invoices');
              break;
            case 2:
              context.go('/customer/help');
              break;
            case 3:
              context.go('/customer/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedItemColor: AppColors.customerBlue,
        unselectedItemColor: const Color(0xFF9CA3AF),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          _navItem(Icons.home, 'Home', 0),
          _navItem(Icons.history, 'Riwayat', 1),
          _navItem(Icons.help_outline, 'Bantuan', 2),
          _navItem(Icons.person, 'Akun', 3),
        ],
      ),
      ),
    );
  }
}
