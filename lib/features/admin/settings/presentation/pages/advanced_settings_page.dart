import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/app_settings_provider.dart';
import '../../../../../data/providers/genieacs_provider.dart';
import '../../../../../data/models/app_settings_model.dart';
import '../../../../../data/models/genieacs_settings_model.dart';

class AdvancedSettingsPage extends ConsumerStatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  ConsumerState<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends ConsumerState<AdvancedSettingsPage> {
  // Controllers
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _offlineNameController = TextEditingController();
  final _offlineAddressController = TextEditingController();
  final _genieacsUrlController = TextEditingController();
  final _genieacsUsernameController = TextEditingController();
  final _genieacsPasswordController = TextEditingController();
  
  // WhatsApp Settings Controllers
  final _fonnteTokenController = TextEditingController();
  final _appUrlController = TextEditingController();
  final _templateFullController = TextEditingController();
  final _templateInstallmentController = TextEditingController();
  final _templateCustomController = TextEditingController();
  
  bool _showQris = true;
  bool _autoNotification = false;
  bool _genieacsEnabled = false;
  bool _obscureGeniePassword = true;
  bool _obscureFonnteToken = true;
  File? _selectedQrisImage;
  String? _currentQrisUrl;

  @override
  void dispose() {
    _whatsappController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _offlineNameController.dispose();
    _offlineAddressController.dispose();
    _genieacsUrlController.dispose();
    _genieacsUsernameController.dispose();
    _genieacsPasswordController.dispose();
    _fonnteTokenController.dispose();
    _appUrlController.dispose();
    _templateFullController.dispose();
    _templateInstallmentController.dispose();
    _templateCustomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final whatsappAsync = ref.watch(whatsappSettingsProvider);
    final genieacsAsync = ref.watch(genieacsConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Lanjutan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) {
          // Populate controllers once
          if (settings != null && _whatsappController.text.isEmpty) {
            _populateControllers(settings);
          }
          
          // Load WhatsApp settings
          whatsappAsync.whenData((waSettings) {
            if (_fonnteTokenController.text.isEmpty) {
              _populateWhatsAppControllers(waSettings);
            }
          });

          // Load GenieACS settings
          genieacsAsync.whenData((genieConfig) {
            if (_genieacsUrlController.text.isEmpty) {
              _populateGenieAcsControllers(genieConfig);
            }
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Informasi Kontak'),
                _buildContactSection(),
                const SizedBox(height: 24),
                
                _buildSectionTitle('Pembayaran Offline'),
                _buildOfflinePaymentSection(),
                const SizedBox(height: 24),
                
                _buildSectionTitle('QRIS Payment'),
                _buildQrisSection(),
                const SizedBox(height: 24),
                
                _buildSectionTitle('WhatsApp Notification'),
                _buildWhatsAppSection(),
                const SizedBox(height: 24),
                
                _buildSectionTitle('GenieACS Integration'),
                _buildGenieACSSection(),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  void _populateControllers(AppSettingsModel settings) {
    _whatsappController.text = settings.whatsappNumber ?? '';
    _emailController.text = settings.supportEmail ?? '';
    _addressController.text = settings.officeAddress ?? '';
    _offlineNameController.text = settings.offlinePaymentName ?? '';
    _offlineAddressController.text = settings.offlinePaymentAddress ?? '';
    _genieacsUrlController.text = settings.genieacsUrl ?? '';
    _genieacsUsernameController.text = settings.genieacsUsername ?? '';
    _genieacsPasswordController.text = settings.genieacsPassword ?? '';
    _showQris = settings.showQris;
    _currentQrisUrl = settings.qrisImageUrl;
  }

  void _populateWhatsAppControllers(Map<String, String> settings) {
    _fonnteTokenController.text = settings['fonnte_token'] ?? '';
    _appUrlController.text = settings['app_url'] ?? '';
    _templateFullController.text = settings['template_payment_full'] ?? '';
    _templateInstallmentController.text = settings['template_payment_installment'] ?? '';
    _templateCustomController.text = settings['template_custom_message'] ?? '';
    _autoNotification = settings['auto_notification_enabled'] == 'true';
  }

  void _populateGenieAcsControllers(GenieAcsConfig config) {
    setState(() {
      _genieacsEnabled = config.enabled;
      _genieacsUrlController.text = config.url;
      _genieacsUsernameController.text = config.username;
      _genieacsPasswordController.text = config.password;
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'Nomor WhatsApp',
                hintText: '628123456789',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Support',
                hintText: 'support@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Kantor',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflinePaymentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _offlineNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                hintText: 'Nama lengkap penerima pembayaran',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _offlineAddressController,
              decoration: const InputDecoration(
                labelText: 'Alamat Penerima',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrisSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Tampilkan QRIS'),
              subtitle: const Text('Aktifkan pembayaran via QRIS'),
              value: _showQris,
              onChanged: (value) {
                setState(() => _showQris = value);
              },
              activeColor: AppColors.success,
            ),
            const SizedBox(height: 16),
            if (_selectedQrisImage != null || _currentQrisUrl != null)
              Container(
                height: 200,
                width: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _selectedQrisImage != null
                    ? Image.file(_selectedQrisImage!, fit: BoxFit.contain)
                    : (_currentQrisUrl != null
                        ? Image.network(_currentQrisUrl!, fit: BoxFit.contain)
                        : const Icon(Icons.qr_code, size: 64)),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickQrisImage,
              icon: const Icon(Icons.upload),
              label: const Text('Upload QRIS Image'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Auto Notification'),
              subtitle: const Text('Kirim notifikasi otomatis via WhatsApp'),
              value: _autoNotification,
              onChanged: (value) {
                setState(() => _autoNotification = value);
              },
              activeColor: AppColors.success,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fonnteTokenController,
              decoration: InputDecoration(
                labelText: 'Fonnte Token',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: Icon(_obscureFonnteToken ? Icons.visibility_off : Icons.visibility),
                  onPressed: () {
                    setState(() => _obscureFonnteToken = !_obscureFonnteToken);
                  },
                ),
              ),
              obscureText: _obscureFonnteToken,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _appUrlController,
              decoration: const InputDecoration(
                labelText: 'App URL',
                hintText: 'https://yourapp.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _templateFullController,
              decoration: const InputDecoration(
                labelText: 'Template Pembayaran Lunas',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _templateInstallmentController,
              decoration: const InputDecoration(
                labelText: 'Template Pembayaran Cicilan',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _templateCustomController,
              decoration: const InputDecoration(
                labelText: 'Template Pesan Custom',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _resetWhatsAppTemplates,
              icon: const Icon(Icons.restore),
              label: const Text('Reset ke Default'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenieACSSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Aktifkan GenieACS'),
              subtitle: const Text('Enable integrasi dengan GenieACS untuk manajemen perangkat'),
              value: _genieacsEnabled,
              onChanged: (value) {
                setState(() => _genieacsEnabled = value);
              },
              activeColor: AppColors.primary,
            ),
            const Divider(),
            const SizedBox(height: 8),
            TextField(
              controller: _genieacsUrlController,
              decoration: const InputDecoration(
                labelText: 'GenieACS URL',
                hintText: 'http://localhost:7547',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
              enabled: _genieacsEnabled,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _genieacsUsernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: _genieacsEnabled,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _genieacsPasswordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureGeniePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscureGeniePassword = !_obscureGeniePassword);
                  },
                ),
              ),
              obscureText: _obscureGeniePassword,
              enabled: _genieacsEnabled,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickQrisImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedQrisImage = File(pickedFile.path);
      });
    }
  }

  void _resetWhatsAppTemplates() {
    setState(() {
      _templateFullController.text = '''Terima kasih atas pembayaran Anda!

Nama: {customer_name}
Periode: {invoice_period}
Jumlah: {amount}
Metode: {payment_method}

Pembayaran Anda telah kami terima.''';

      _templateInstallmentController.text = '''Pembayaran cicilan diterima!

Nama: {customer_name}
Periode: {invoice_period}
Dibayar: {amount_paid}
Sisa: {remaining}

Terima kasih!''';

      _templateCustomController.text = '''Halo {customer_name},

{custom_message}

Terima kasih.''';
    });
  }

  Future<void> _saveSettings() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyimpan pengaturan...')),
      );

      final currentSettings = await ref.read(appSettingsProvider.future);
      String? qrisUrl = _currentQrisUrl;

      // Upload QRIS image if selected
      if (_selectedQrisImage != null) {
        final bytes = await _selectedQrisImage!.readAsBytes();
        final fileName = 'qris_${DateTime.now().millisecondsSinceEpoch}.png';
        qrisUrl = await ref
            .read(appSettingsControllerProvider.notifier)
            .uploadQrisImage(bytes, fileName);
      }

      // Save app settings
      final settings = AppSettingsModel(
        id: currentSettings?.id,
        appName: currentSettings?.appName ?? 'SelinggoNet',
        whatsappNumber: _whatsappController.text.trim(),
        supportEmail: _emailController.text.trim(),
        officeAddress: _addressController.text.trim(),
        offlinePaymentName: _offlineNameController.text.trim(),
        offlinePaymentAddress: _offlineAddressController.text.trim(),
        qrisImageUrl: qrisUrl,
        showQris: _showQris,
        genieacsUrl: _genieacsUrlController.text.trim(),
        genieacsUsername: _genieacsUsernameController.text.trim(),
        genieacsPassword: _genieacsPasswordController.text.trim(),
      );

      await ref
          .read(appSettingsControllerProvider.notifier)
          .saveAppSettings(settings);

      // Save WhatsApp settings
      final waSettings = {
        'auto_notification_enabled': _autoNotification.toString(),
        'fonnte_token': _fonnteTokenController.text.trim(),
        'app_url': _appUrlController.text.trim(),
        'template_payment_full': _templateFullController.text.trim(),
        'template_payment_installment': _templateInstallmentController.text.trim(),
        'template_custom_message': _templateCustomController.text.trim(),
      };

      await ref
          .read(appSettingsControllerProvider.notifier)
          .saveWhatsAppSettings(waSettings);

      // Save GenieACS settings
      final genieacsConfig = GenieAcsConfig(
        enabled: _genieacsEnabled,
        url: _genieacsUrlController.text.trim(),
        username: _genieacsUsernameController.text.trim(),
        password: _genieacsPasswordController.text.trim(),
      );

      await ref
          .read(genieacsControllerProvider.notifier)
          .saveSettings(genieacsConfig);

      // Invalidate providers to refresh
      ref.invalidate(genieacsConfigProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(appSettingsProvider);
        ref.invalidate(whatsappSettingsProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
