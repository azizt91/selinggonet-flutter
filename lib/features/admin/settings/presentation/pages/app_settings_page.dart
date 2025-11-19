import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/auth_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AppSettingsPage extends ConsumerStatefulWidget {
  const AppSettingsPage({super.key});

  @override
  ConsumerState<AppSettingsPage> createState() => _AppSettingsPageState();
}

class _AppSettingsPageState extends ConsumerState<AppSettingsPage> {
  bool _isEditMode = false;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  File? _selectedImage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() => _isEditMode = true);
                final user = userAsync.value;
                if (user != null) {
                  _nameController.text = user.fullName ?? '';
                  _emailController.text = user.email ?? '';
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile Photo Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primary,
                        backgroundImage: _selectedImage != null
                            ? FileImage(_selectedImage!)
                            : (user.photoUrl != null && user.photoUrl!.isNotEmpty
                                ? NetworkImage(user.photoUrl!)
                                : null) as ImageProvider?,
                        child: _selectedImage == null &&
                                (user.photoUrl == null || user.photoUrl!.isEmpty)
                            ? Text(
                                user.fullName?.substring(0, 1).toUpperCase() ?? 'A',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      if (_isEditMode)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.primary,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                              onPressed: _pickImage,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Info Card or Edit Form
                if (!_isEditMode)
                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Nama Lengkap',
                    value: user.fullName ?? '-',
                  ),
                if (!_isEditMode)
                  const SizedBox(height: 12),
                if (!_isEditMode)
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'Email',
                    value: user.email ?? '-',
                  ),
                if (!_isEditMode)
                  const SizedBox(height: 12),
                if (!_isEditMode)
                  _buildInfoCard(
                    icon: Icons.badge,
                    title: 'Role',
                    value: user.role ?? '-',
                  ),
                
                // Edit Form
                if (_isEditMode)
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Lengkap',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                if (_isEditMode)
                  const SizedBox(height: 16),
                if (_isEditMode)
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                if (_isEditMode)
                  const SizedBox(height: 16),
                if (_isEditMode)
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password Baru (Opsional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                if (_isEditMode)
                  const SizedBox(height: 24),
                if (_isEditMode)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditMode = false;
                              _selectedImage = null;
                              _passwordController.clear();
                            });
                          },
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Settings Sections
                if (!_isEditMode)
                  _buildSectionTitle('Pengaturan Lainnya'),
                if (!_isEditMode)
                  const SizedBox(height: 12),
                if (!_isEditMode)
                  _buildSettingsTile(
                    icon: Icons.payment,
                    title: 'Metode Pembayaran',
                    subtitle: 'Kelola rekening bank',
                    onTap: () => context.push('/admin/payment-methods'),
                  ),
                if (!_isEditMode)
                  _buildSettingsTile(
                    icon: Icons.settings_applications,
                    title: 'Pengaturan Lanjutan',
                    subtitle: 'Kontak, WhatsApp, QRIS, GenieACS',
                    onTap: () => context.push('/admin/advanced-settings'),
                  ),
                if (!_isEditMode)
                  _buildSettingsTile(
                    icon: Icons.info,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Versi 1.0.0',
                    onTap: () => _showAboutDialog(),
                  ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email tidak boleh kosong'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password minimal 6 karakter'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menyimpan perubahan...')),
      );

      final supabase = ref.read(supabaseClientProvider);
      final currentUser = ref.read(currentUserProvider).value;
      
      if (currentUser == null) {
        throw Exception('User not found');
      }

      String? photoUrl;

      // 1. Upload photo if selected
      if (_selectedImage != null) {
        final fileExt = _selectedImage!.path.split('.').last;
        final fileName = '${currentUser.id}-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = fileName;

        // Upload to Supabase Storage
        final bytes = await _selectedImage!.readAsBytes();
        await supabase.storage
            .from('avatars')
            .uploadBinary(filePath, bytes);

        // Get public URL
        photoUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      // 2. Update profile (name and photo)
      final profileData = {
        'full_name': _nameController.text.trim(),
      };
      
      if (photoUrl != null) {
        profileData['photo_url'] = photoUrl;
      }

      await supabase
          .from('profiles')
          .update(profileData)
          .eq('id', currentUser.id);

      // 3. Update auth (email and/or password)
      if (_emailController.text.trim() != currentUser.email ||
          _passwordController.text.isNotEmpty) {
        final updateAttributes = UserAttributes(
          email: _emailController.text.trim() != currentUser.email
              ? _emailController.text.trim()
              : null,
          password: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        );
        await supabase.auth.updateUser(updateAttributes);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _isEditMode = false;
          _selectedImage = null;
          _passwordController.clear();
        });
        ref.invalidate(currentUserProvider);
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

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authControllerProvider).logout();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tentang Aplikasi'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SelinggoNet ISP Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Versi: 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Aplikasi manajemen pelanggan dan tagihan untuk ISP.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
