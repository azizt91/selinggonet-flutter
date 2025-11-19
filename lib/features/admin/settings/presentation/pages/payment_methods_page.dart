import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/providers/payment_method_provider.dart';
import '../../../../../data/models/payment_method_model.dart';

class PaymentMethodsPage extends ConsumerWidget {
  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metode Pembayaran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(paymentMethodsProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentMethodsProvider);
        },
        child: paymentMethodsAsync.when(
          data: (methods) {
            if (methods.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada metode pembayaran',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Klik tombol + untuk menambahkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: methods.length,
              itemBuilder: (context, index) {
                final method = methods[index];
                return _PaymentMethodCard(
                  method: method,
                  onTap: () => _showPaymentMethodDialog(context, ref, method: method),
                  onToggleActive: (value) async {
                    await ref
                        .read(paymentMethodControllerProvider.notifier)
                        .toggleActive(method.id!, value);
                    ref.invalidate(paymentMethodsProvider);
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.danger),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(paymentMethodsProvider),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPaymentMethodDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Bank'),
      ),
    );
  }

  void _showPaymentMethodDialog(
    BuildContext context,
    WidgetRef ref, {
    PaymentMethodModel? method,
  }) {
    showDialog(
      context: context,
      builder: (context) => _PaymentMethodDialog(
        method: method,
        onSave: (newMethod) async {
          try {
            if (method == null) {
              await ref
                  .read(paymentMethodControllerProvider.notifier)
                  .createPaymentMethod(newMethod);
            } else {
              await ref
                  .read(paymentMethodControllerProvider.notifier)
                  .updatePaymentMethod(newMethod);
            }
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    method == null
                        ? 'Metode pembayaran berhasil ditambahkan'
                        : 'Metode pembayaran berhasil diupdate',
                  ),
                  backgroundColor: AppColors.success,
                ),
              );
              ref.invalidate(paymentMethodsProvider);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          }
        },
        onDelete: method != null
            ? () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Metode Pembayaran'),
                    content: Text(
                      'Yakin ingin menghapus ${method.bankName}?',
                    ),
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
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  try {
                    await ref
                        .read(paymentMethodControllerProvider.notifier)
                        .deletePaymentMethod(method.id!);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Metode pembayaran berhasil dihapus'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      ref.invalidate(paymentMethodsProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal menghapus: $e'),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    }
                  }
                }
              }
            : null,
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggleActive;

  const _PaymentMethodCard({
    required this.method,
    required this.onTap,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: method.isActive
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance,
                  color: method.isActive ? AppColors.primary : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            method.bankName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!method.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Nonaktif',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.accountNumber,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      method.accountHolder,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (method.sortOrder > 0)
                      Text(
                        'Urutan: ${method.sortOrder}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              Switch(
                value: method.isActive,
                onChanged: onToggleActive,
                activeColor: AppColors.success,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodDialog extends StatefulWidget {
  final PaymentMethodModel? method;
  final Function(PaymentMethodModel) onSave;
  final VoidCallback? onDelete;

  const _PaymentMethodDialog({
    this.method,
    required this.onSave,
    this.onDelete,
  });

  @override
  State<_PaymentMethodDialog> createState() => _PaymentMethodDialogState();
}

class _PaymentMethodDialogState extends State<_PaymentMethodDialog> {
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _accountHolderController;
  late final TextEditingController _sortOrderController;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(
      text: widget.method?.bankName ?? '',
    );
    _accountNumberController = TextEditingController(
      text: widget.method?.accountNumber ?? '',
    );
    _accountHolderController = TextEditingController(
      text: widget.method?.accountHolder ?? '',
    );
    _sortOrderController = TextEditingController(
      text: widget.method?.sortOrder.toString() ?? '0',
    );
    _isActive = widget.method?.isActive ?? true;
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    _sortOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.method == null ? 'Tambah Bank Baru' : 'Edit Bank',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Bank',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'Nomor Rekening',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _accountHolderController,
              decoration: const InputDecoration(
                labelText: 'Nama Pemilik Rekening',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _sortOrderController,
              decoration: const InputDecoration(
                labelText: 'Urutan Tampilan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sort),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Aktif'),
              subtitle: const Text('Tampilkan di daftar pembayaran'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
              activeColor: AppColors.success,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: widget.onDelete,
            child: const Text(
              'Hapus',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_bankNameController.text.isEmpty ||
                _accountNumberController.text.isEmpty ||
                _accountHolderController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mohon lengkapi semua field'),
                  backgroundColor: AppColors.danger,
                ),
              );
              return;
            }

            final method = PaymentMethodModel(
              id: widget.method?.id,
              bankName: _bankNameController.text.trim(),
              accountNumber: _accountNumberController.text.trim(),
              accountHolder: _accountHolderController.text.trim(),
              sortOrder: int.tryParse(_sortOrderController.text) ?? 0,
              isActive: _isActive,
            );

            widget.onSave(method);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
