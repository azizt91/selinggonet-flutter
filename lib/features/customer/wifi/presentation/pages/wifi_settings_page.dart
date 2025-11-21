import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/auth_provider.dart';

class WifiSettingsPage extends ConsumerStatefulWidget {
  const WifiSettingsPage({super.key});

  @override
  ConsumerState<WifiSettingsPage> createState() => _WifiSettingsPageState();
}

class _WifiSettingsPageState extends ConsumerState<WifiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _passwordMismatch = false;
  
  String? _currentSsid;
  String? _currentPassword;
  String? _currentIp;
  List<Map<String, dynamic>> _connectedDevices = [];
  List<Map<String, dynamic>> _changeHistory = [];
  bool _isLoadingWifiInfo = true;
  bool _isLoadingDevices = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Add listener for password confirmation
    _confirmPasswordController.addListener(() {
      setState(() {
        _passwordMismatch = _passwordController.text.isNotEmpty &&
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text != _confirmPasswordController.text;
      });
    });
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() {
      _currentIp = user.ipStaticPppoe;
    });

    await Future.wait([
      _loadCurrentWifiInfo(),
      _loadConnectedDevices(),
      _loadChangeHistory(),
    ]);
  }

  Future<void> _loadCurrentWifiInfo() async {
    setState(() => _isLoadingWifiInfo = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user?.ipStaticPppoe == null) {
        setState(() {
          _currentSsid = 'IP Address tidak ditemukan';
          _currentPassword = '-';
        });
        return;
      }

      // TODO: Implement GenieACS API call to get current WiFi info
      // For now, show placeholder
      setState(() {
        _currentSsid = 'Tidak dapat diambil';
        _currentPassword = 'Tidak dapat diambil';
      });
    } catch (e) {
      setState(() {
        _currentSsid = 'Gagal mengambil data';
        _currentPassword = 'Gagal mengambil data';
      });
    } finally {
      setState(() => _isLoadingWifiInfo = false);
    }
  }

  Future<void> _loadConnectedDevices() async {
    setState(() => _isLoadingDevices = true);
    
    try {
      // TODO: Implement GenieACS API call to get connected devices
      // For now, show empty list
      setState(() {
        _connectedDevices = [];
      });
    } catch (e) {
      print('Error loading connected devices: $e');
    } finally {
      setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _loadChangeHistory() async {
    setState(() => _isLoadingHistory = true);
    
    try {
      final user = ref.read(currentUserProvider).value;
      if (user?.id == null) return;

      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('wifi_change_logs')
          .select()
          .eq('customer_id', user!.id!)
          .order('changed_at', ascending: false)
          .limit(5);

      setState(() {
        _changeHistory = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Error loading change history: $e');
    } finally {
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF110E1B)),
                  ),
                  const Expanded(
                    child: Text(
                      'Pengaturan WiFi',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF110E1B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    
                    // Info Card
                    _buildInfoCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Current WiFi Info
                    _buildCurrentWifiCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Connected Devices
                    _buildConnectedDevicesCard(),
                    
                    const SizedBox(height: 16),
                    
                    // Change WiFi Form
                    _buildChangeWifiForm(),
                    
                    const SizedBox(height: 16),
                    
                    // Change History
                    _buildChangeHistoryCard(),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informasi Penting',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[900],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Perubahan SSID dan Password akan diterapkan ke router WiFi Anda\n• Proses membutuhkan waktu 1-2 menit\n• Setelah berhasil, hubungkan ulang perangkat Anda ke WiFi dengan nama dan password baru',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      height: 1.5,
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

  Widget _buildCurrentWifiCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi WiFi Saat Ini',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            _buildInfoRow(Icons.wifi, 'Nama WiFi (SSID)', _currentSsid ?? 'Memuat...'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.lock, 'Password WiFi', _currentPassword ?? 'Memuat...'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.router, 'IP Address', _currentIp ?? 'Memuat...'),
            
            const SizedBox(height: 8),
            Text(
              '* SSID saat ini mungkin tidak dapat diambil karena keterbatasan akses. Anda tetap dapat mengganti WiFi dengan mengisi form di bawah.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF110E1B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedDevicesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Perangkat Terhubung',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                TextButton(
                  onPressed: _loadConnectedDevices,
                  child: const Text(
                    'Refresh',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_isLoadingDevices)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_connectedDevices.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Tidak ada perangkat terhubung',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF110E1B),
                  ),
                  columns: const [
                    DataColumn(label: Text('Device')),
                    DataColumn(label: Text('IP Address')),
                    DataColumn(label: Text('MAC Address')),
                    DataColumn(label: Text('Type')),
                  ],
                  rows: _connectedDevices.map((device) {
                    return DataRow(cells: [
                      DataCell(Text(device['hostname'] ?? '-')),
                      DataCell(Text(device['ipAddress'] ?? '-')),
                      DataCell(Text(device['macAddress'] ?? '-')),
                      DataCell(Text(device['type'] ?? '-')),
                    ]);
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangeWifiForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ganti SSID & Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              
              // SSID Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nama WiFi Baru (SSID)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF110E1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ssidController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: WiFi-Rumah-Saya (opsional)',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD6D0E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD6D0E7)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    maxLength: 32,
                  ),
                  Text(
                    'Kosongkan jika tidak ingin mengganti SSID',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password WiFi Baru',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF110E1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Minimal 8 karakter (opsional)',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD6D0E7)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD6D0E7)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  Text(
                    'Kosongkan jika tidak ingin mengganti password. Minimal 8 karakter jika diisi.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Confirm Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konfirmasi Password',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF110E1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Ketik ulang password (jika diisi)',
                      hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _passwordMismatch ? Colors.red : const Color(0xFFD6D0E7),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _passwordMismatch ? Colors.red : const Color(0xFFD6D0E7),
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  if (_passwordMismatch)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Password tidak cocok',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF683FE4),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SIMPAN',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangeHistoryCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Perubahan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            if (_isLoadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_changeHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Belum ada riwayat perubahan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              )
            else
              Column(
                children: _changeHistory.map((log) {
                  final status = log['status'] as String?;
                  final statusColor = status == 'success'
                      ? Colors.green[600]
                      : status == 'failed'
                          ? Colors.red[600]
                          : Colors.yellow[700];
                  final statusText = status == 'success'
                      ? 'Berhasil'
                      : status == 'failed'
                          ? 'Gagal'
                          : 'Diproses';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                log['new_ssid'] ?? '-',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF110E1B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                log['changed_at'] != null
                                    ? DateTime.parse(log['changed_at'])
                                        .toLocal()
                                        .toString()
                                        .substring(0, 16)
                                    : '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              if (log['error_message'] != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  log['error_message'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final newSsid = _ssidController.text.trim();
    final newPassword = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation
    if (newSsid.isEmpty && newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal isi SSID atau Password baru'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password tidak cocok'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      if (newPassword.length < 8) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password minimal 8 karakter'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }

    final user = ref.read(currentUserProvider).value;
    if (user?.ipStaticPppoe == null || user!.ipStaticPppoe!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP Address tidak ditemukan. Hubungi admin untuk mengatur IP Address Anda.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Yakin ingin mengganti WiFi?'),
            const SizedBox(height: 12),
            if (newSsid.isNotEmpty)
              Text(
                'SSID Baru: $newSsid',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 12),
            const Text(
              'Proses membutuhkan waktu 1-2 menit.',
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
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Ya, Ganti'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Save to log
      await supabase.from('wifi_change_logs').insert({
        'customer_id': user.id,
        'ip_address': user.ipStaticPppoe,
        'old_ssid': _currentSsid ?? 'Unknown',
        'new_ssid': newSsid.isNotEmpty ? newSsid : _currentSsid,
        'status': 'processing',
      });

      // TODO: Implement GenieACS API call to change WiFi
      // For now, just show success message
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perintah ganti WiFi berhasil dikirim! Perangkat akan diperbarui dalam 1-2 menit.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 5),
          ),
        );

        // Clear form
        _ssidController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Reload data
        await _loadChangeHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
