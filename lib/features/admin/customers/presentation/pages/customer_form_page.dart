import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/profile_model.dart';
import '../../../../../data/providers/customer_provider.dart';

class CustomerFormPage extends ConsumerStatefulWidget {
  final ProfileModel? customer;

  const CustomerFormPage({super.key, this.customer});

  @override
  ConsumerState<CustomerFormPage> createState() => _CustomerFormPageState();
}

class _CustomerFormPageState extends ConsumerState<CustomerFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _ipStaticController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPackageId;
  String? _selectedStatus;
  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isEditMode => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadCustomerData();
    }
  }

  void _loadCustomerData() {
    final customer = widget.customer!;
    _emailController.text = customer.email ?? '';
    _fullNameController.text = customer.fullName ?? '';
    _phoneController.text = customer.phone ?? '';
    _addressController.text = customer.address ?? '';
    _latitudeController.text = customer.latitude?.toString() ?? '';
    _longitudeController.text = customer.longitude?.toString() ?? '';
    _ipStaticController.text = customer.ipStaticPppoe ?? '';
    _notesController.text = customer.notes ?? '';
    _selectedPackageId = customer.packageId?.toString();
    _selectedStatus = customer.status ?? 'AKTIF';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _ipStaticController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Pelanggan' : 'Tambah Pelanggan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Account Info Section
            _buildSectionTitle('Informasi Akun'),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !isEditMode, // Email tidak bisa diubah
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                helperText: 'Email untuk login',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email harus diisi';
                }
                if (!value.contains('@')) {
                  return 'Email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (!isEditMode)
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password *',
                  prefixIcon: const Icon(Icons.lock),
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
                  helperText: 'Minimal 6 karakter',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password harus diisi';
                  }
                  if (value.length < 6) {
                    return 'Password minimal 6 karakter';
                  }
                  return null;
                },
              ),
            const SizedBox(height: 24),

            // Personal Info Section
            _buildSectionTitle('Informasi Pribadi'),
            TextFormField(
              controller: _fullNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap *',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP *',
                prefixIcon: Icon(Icons.phone),
                helperText: 'Contoh: 081234567890',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nomor HP harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Alamat *',
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Alamat harus diisi';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Package & Status Section
            _buildSectionTitle('Paket & Status'),
            DropdownButtonFormField<String>(
              value: _selectedPackageId,
              decoration: const InputDecoration(
                labelText: 'Paket Layanan *',
                prefixIcon: Icon(Icons.inventory),
              ),
              items: const [
                // TODO: Load from packages provider
                DropdownMenuItem(value: '1', child: Text('Paket 1 - 10 Mbps')),
                DropdownMenuItem(value: '2', child: Text('Paket 2 - 20 Mbps')),
                DropdownMenuItem(value: '3', child: Text('Paket 3 - 50 Mbps')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPackageId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Paket harus dipilih';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (isEditMode)
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: const [
                  DropdownMenuItem(value: 'AKTIF', child: Text('Aktif')),
                  DropdownMenuItem(value: 'NONAKTIF', child: Text('Nonaktif')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
            const SizedBox(height: 24),

            // Technical Info Section
            _buildSectionTitle('Informasi Teknis (Opsional)'),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latitudeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _longitudeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      prefixIcon: Icon(Icons.map),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ipStaticController,
              decoration: const InputDecoration(
                labelText: 'IP Static / PPPoE',
                prefixIcon: Icon(Icons.network_check),
                helperText: 'Untuk integrasi GenieACS',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditMode ? 'Simpan Perubahan' : 'Tambah Pelanggan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (isEditMode) {
        await ref.read(customerControllerProvider.notifier).updateCustomer(
              id: widget.customer!.id!,
              fullName: _fullNameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              packageId: _selectedPackageId,
              status: _selectedStatus,
              latitude: _latitudeController.text.isEmpty ? null : _latitudeController.text,
              longitude: _longitudeController.text.isEmpty ? null : _longitudeController.text,
              ipStaticPppoe: _ipStaticController.text.isEmpty ? null : _ipStaticController.text,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelanggan berhasil diupdate')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await ref.read(customerControllerProvider.notifier).createCustomer(
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text,
              phone: _phoneController.text,
              address: _addressController.text,
              packageId: _selectedPackageId!,
              latitude: _latitudeController.text.isEmpty ? null : _latitudeController.text,
              longitude: _longitudeController.text.isEmpty ? null : _longitudeController.text,
              ipStaticPppoe: _ipStaticController.text.isEmpty ? null : _ipStaticController.text,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelanggan berhasil ditambahkan')),
          );
          Navigator.pop(context, true);
        }
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
}
