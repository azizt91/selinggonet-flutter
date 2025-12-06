import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../data/providers/auth_provider.dart';
import '../../../../../data/providers/dashboard_provider.dart';
import '../../../packages/presentation/pages/admin_packages_page.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  const CustomerFormPage({super.key});
  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _deviceController = TextEditingController();
  final _ipController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  
  String _gender = '';
  String _status = 'AKTIF';
  int? _packageId;
  double _amount = 0;
  DateTime? _installationDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _whatsappController.dispose();
    _deviceController.dispose();
    _ipController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(packagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF110E1B)),
          onPressed: () {
            if (_nameController.text.isNotEmpty || _emailController.text.isNotEmpty) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Konfirmasi'),
                  content: const Text('Yakin ingin kembali? Data yang belum disimpan akan hilang.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    TextButton(onPressed: () { Navigator.pop(ctx); Navigator.pop(context); }, child: const Text('Ya')),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Tambah Pelanggan', style: TextStyle(color: Color(0xFF110E1B), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Nama Lengkap', _nameController, 'Masukkan nama lengkap', required: true),
            const SizedBox(height: 16),
            _buildTextField('Email Login', _emailController, 'email@example.com', required: true, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField('Password', _passwordController, 'Min. 6 karakter', required: true, obscure: true),
            const SizedBox(height: 16),
            _buildTextField('Alamat Lengkap', _addressController, 'Masukkan alamat', required: true, maxLines: 2),
            const SizedBox(height: 16),
            _buildTextField('Nomor WhatsApp', _whatsappController, '08xxxxxxxxxx', required: true, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildDropdown('Jenis Kelamin', ['LAKI-LAKI', 'PEREMPUAN'], _gender, (v) => setState(() => _gender = v ?? ''), required: true),
            const SizedBox(height: 16),
            // Package Dropdown
            packages.when(
              data: (pkgs) => _buildPackageDropdown(pkgs),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Gagal memuat paket'),
            ),
            const SizedBox(height: 16),
            _buildTextField('Tagihan Bulanan', TextEditingController(text: _amount.toInt().toString()), 'Otomatis dari paket', enabled: false),
            const SizedBox(height: 16),
            _buildDropdown('Status', ['AKTIF', 'NONAKTIF'], _status, (v) => setState(() => _status = v ?? 'AKTIF')),
            const SizedBox(height: 16),
            _buildTextField('Jenis Perangkat', _deviceController, 'Contoh: ONT ZTE F609'),
            const SizedBox(height: 16),
            _buildTextField('IP Static / PPOE', _ipController, 'Contoh: 192.168.1.100'),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildLocationFields(),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF683FE4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool required = false, TextInputType? keyboardType, int maxLines = 1, bool obscure = false, bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(text: label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF110E1B)), children: required ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : null)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          obscureText: obscure,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: enabled ? const Color(0xFFEAE8F3) : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF683FE4), width: 2)),
          ),
          validator: required ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, Function(String?) onChanged, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: TextSpan(text: label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF110E1B)), children: required ? [const TextSpan(text: ' *', style: TextStyle(color: Colors.red))] : null)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? null : value,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFEAE8F3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          hint: Text('Pilih $label'),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
          validator: required ? (v) => v == null || v.isEmpty ? '$label wajib dipilih' : null : null,
        ),
      ],
    );
  }

  Widget _buildPackageDropdown(List<PackageModel> packages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(text: const TextSpan(text: 'Paket', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF110E1B)), children: [TextSpan(text: ' *', style: TextStyle(color: Colors.red))])),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _packageId,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFEAE8F3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          hint: const Text('Pilih Paket'),
          items: packages.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.packageName} - ${p.speedMbps} Mbps'))).toList(),
          onChanged: (v) {
            setState(() {
              _packageId = v;
              final pkg = packages.firstWhere((p) => p.id == v);
              _amount = pkg.price;
            });
          },
          validator: (v) => v == null ? 'Paket wajib dipilih' : null,
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tanggal Instalasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF110E1B))),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(context: context, initialDate: _installationDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
            if (date != null) setState(() => _installationDate = date);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEAE8F3), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: Text(_installationDate != null ? '${_installationDate!.day}/${_installationDate!.month}/${_installationDate!.year}' : 'Pilih tanggal (default: hari ini)', style: TextStyle(color: _installationDate != null ? Colors.black : Colors.grey[400]))),
                const Icon(Icons.calendar_today, color: Color(0xFF625095)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Lokasi (Opsional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF110E1B))),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: TextFormField(controller: _latController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: 'Latitude', filled: true, fillColor: const Color(0xFFEAE8F3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _lngController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: 'Longitude', filled: true, fillColor: const Color(0xFFEAE8F3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
          ],
        ),
        const SizedBox(height: 4),
        Text('Contoh: -6.9174639, 107.6191228', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final photoUrl = _gender == 'LAKI-LAKI'
          ? 'https://sb-admin-pro.startbootstrap.com/assets/img/illustrations/profiles/profile-2.png'
          : 'https://sb-admin-pro.startbootstrap.com/assets/img/illustrations/profiles/profile-1.png';

      final customerData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'full_name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'whatsapp_number': _whatsappController.text.trim(),
        'gender': _gender,
        'status': _status,
        'device_type': _deviceController.text.trim().isEmpty ? null : _deviceController.text.trim(),
        'ip_static_pppoe': _ipController.text.trim().isEmpty ? null : _ipController.text.trim(),
        'photo_url': photoUrl,
        'installation_date': (_installationDate ?? DateTime.now()).toIso8601String(),
        'package_id': _packageId,
        'amount': _amount,
        'latitude': _latController.text.trim().isEmpty ? null : double.tryParse(_latController.text),
        'longitude': _lngController.text.trim().isEmpty ? null : double.tryParse(_lngController.text),
      };

      final response = await ref.read(supabaseClientProvider).functions.invoke('create-customer', body: customerData);

      if (response.data != null && response.data['error'] != null) {
        throw Exception(response.data['error']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelanggan berhasil ditambahkan')));
        ref.invalidate(allCustomersProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
