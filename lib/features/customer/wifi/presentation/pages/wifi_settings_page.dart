import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/wifi_provider.dart';

class WifiSettingsPage extends ConsumerStatefulWidget {
  const WifiSettingsPage({super.key});

  @override
  ConsumerState<WifiSettingsPage> createState() => _WifiSettingsPageState();
}

class _WifiSettingsPageState extends ConsumerState<WifiSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ganti WiFi'),
      ),
      body: userAsync.when(
        data: (user) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info Card
                Card(
                  color: AppColors.info.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.info,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Perubahan WiFi akan mempengaruhi semua perangkat yang terhubung',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pastikan Anda mengingat SSID dan password baru',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Current WiFi Info
                if (user?.ipStaticPppoe != null) ...[
                  _buildCurrentWifiInfo(ref, user!.ipStaticPppoe!),
                  const SizedBox(height: 24),
                ],

                // WiFi Change History
                if (user?.id != null) ...[
                  _buildChangeHistory(ref, user!.id),
                  const SizedBox(height: 24),
                ],

                // Current Info (if available)
                if (user?.ipStaticPppoe != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Router',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.router, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'IP: ${user?.ipStaticPppoe}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Form Title
                const Text(
                  'Pengaturan WiFi Baru',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // SSID Field
                TextFormField(
                  controller: _ssidController,
                  decoration: const InputDecoration(
                    labelText: 'SSID (Nama WiFi) *',
                    prefixIcon: Icon(Icons.wifi),
                    helperText: 'Nama WiFi yang akan ditampilkan',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'SSID harus diisi';
                    }
                    if (value.length < 3) {
                      return 'SSID minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock),
                    helperText: 'Minimal 8 karakter',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password harus diisi';
                    }
                    if (value.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Warning Card
                Card(
                  color: AppColors.warning.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: AppColors.warning,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Proses perubahan WiFi membutuhkan waktu beberapa menit',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : const Text('Ganti WiFi'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
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
            const Text('Yakin ingin mengubah WiFi?'),
            const SizedBox(height: 12),
            Text(
              'SSID: ${_ssidController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Password: ${_passwordController.text}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Semua perangkat akan terputus dan perlu reconnect dengan kredensial baru.',
              style: TextStyle(fontSize: 12, color: AppColors.danger),
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Get user data
      final userAsync = ref.read(currentUserProvider);
      final user = userAsync.value;

      if (user == null || user.ipStaticPppoe == null) {
        throw Exception('IP Address tidak ditemukan');
      }

      // Get current SSID for logging
      final currentWifiAsync = ref.read(currentWifiInfoProvider(user.ipStaticPppoe!));
      final currentSsid = currentWifiAsync.value?['ssid'] ?? 'Unknown';

      // Call WiFi controller to change WiFi
      final result = await ref.read(wifiControllerProvider.notifier).changeWifi(
        customerId: user.id!,
        ipAddress: user.ipStaticPppoe!,
        oldSsid: currentSsid,
        newSsid: _ssidController.text.isNotEmpty ? _ssidController.text : null,
        newPassword: _passwordController.text.isNotEmpty ? _passwordController.text : null,
      );

      if (!result['success']) {
        throw Exception(result['message']);
      }

      if (mounted) {
        // Invalidate providers to refresh data
        final user = ref.read(currentUserProvider).value;
        if (user != null) {
          if (user.ipStaticPppoe != null) {
            ref.invalidate(currentWifiInfoProvider(user.ipStaticPppoe!));
          }
          if (user.id != null) {
            ref.invalidate(wifiChangeHistoryProvider(user.id!));
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? 'Permintaan perubahan WiFi berhasil dikirim. Proses akan memakan waktu beberapa menit.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );

        // Clear form
        _ssidController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCurrentWifiInfo(WidgetRef ref, String ipAddress) {
    final wifiInfoAsync = ref.watch(currentWifiInfoProvider(ipAddress));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'WiFi Saat Ini',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: () {
                    ref.invalidate(currentWifiInfoProvider(ipAddress));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            wifiInfoAsync.when(
              data: (info) {
                if (info['success'] == true) {
                  return Column(
                    children: [
                      _buildInfoRow('SSID', info['ssid'] ?? '-'),
                      const SizedBox(height: 8),
                      _buildInfoRow('Password', info['password'] ?? '-'),
                    ],
                  );
                }
                return Text(
                  info['message'] ?? 'Gagal mengambil data WiFi',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.danger,
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Text(
                'Error: $error',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeHistory(WidgetRef ref, String customerId) {
    final historyAsync = ref.watch(wifiChangeHistoryProvider(customerId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Perubahan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const Text(
                    'Belum ada riwayat perubahan',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  );
                }
                return Column(
                  children: history.take(5).map((log) {
                    final status = log['status'] as String?;
                    final statusColor = status == 'success'
                        ? AppColors.success
                        : status == 'failed'
                            ? AppColors.danger
                            : AppColors.warning;
                    final statusText = status == 'success'
                        ? 'Berhasil'
                        : status == 'failed'
                            ? 'Gagal'
                            : 'Diproses';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
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
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                if (log['error_message'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    log['error_message'],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Text(
                'Error: $error',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
