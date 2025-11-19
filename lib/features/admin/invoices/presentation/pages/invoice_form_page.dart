import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/invoice_model.dart';
import '../../../../../data/models/profile_model.dart';
import '../../../../../data/providers/invoice_provider.dart';
import '../../../../../data/providers/customer_provider.dart';

class InvoiceFormPage extends ConsumerStatefulWidget {
  final InvoiceModel? invoice;

  const InvoiceFormPage({super.key, this.invoice});

  @override
  ConsumerState<InvoiceFormPage> createState() => _InvoiceFormPageState();
}

class _InvoiceFormPageState extends ConsumerState<InvoiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCustomerId;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  bool get isEditMode => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    if (isEditMode) {
      _loadInvoiceData();
    }
  }

  void _loadInvoiceData() {
    final invoice = widget.invoice!;
    _selectedCustomerId = invoice.customerId;
    _amountController.text = invoice.amount.toString();
    _selectedDueDate = invoice.dueDate;
    _descriptionController.text = invoice.description ?? '';
    _notesController.text = invoice.notes ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Tagihan' : 'Buat Tagihan'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Customer Selection
            customersAsync.when(
              data: (customers) {
                return DropdownButtonFormField<String>(
                  value: _selectedCustomerId,
                  decoration: const InputDecoration(
                    labelText: 'Pelanggan *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: customers.map((customer) {
                    return DropdownMenuItem(
                      value: customer.id,
                      child: Text('${customer.fullName} (${customer.idpl})'),
                    );
                  }).toList(),
                  onChanged: isEditMode
                      ? null
                      : (value) {
                          setState(() {
                            _selectedCustomerId = value;
                          });
                        },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pelanggan harus dipilih';
                    }
                    return null;
                  },
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                'Error loading customers: $error',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah Tagihan *',
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Rp ',
                helperText: 'Masukkan jumlah tagihan',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah harus diisi';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Due Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() {
                    _selectedDueDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Jatuh Tempo *',
                  prefixIcon: const Icon(Icons.calendar_today),
                  errorText: _selectedDueDate == null && _formKey.currentState?.validate() == false
                      ? 'Tanggal jatuh tempo harus dipilih'
                      : null,
                ),
                child: Text(
                  _selectedDueDate != null
                      ? DateFormat('dd MMMM yyyy').format(_selectedDueDate!)
                      : 'Pilih tanggal jatuh tempo',
                  style: TextStyle(
                    color: _selectedDueDate != null ? Colors.black : Colors.grey[400],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
                helperText: 'Contoh: Tagihan bulan Januari 2025',
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                prefixIcon: Icon(Icons.note),
                alignLabelWithHint: true,
                helperText: 'Catatan tambahan (opsional)',
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
                  : Text(isEditMode ? 'Simpan Perubahan' : 'Buat Tagihan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal jatuh tempo harus dipilih'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      if (isEditMode) {
        await ref.read(invoiceControllerProvider.notifier).updateInvoice(
              id: widget.invoice!.id!,
              amount: amount,
              dueDate: _selectedDueDate,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tagihan berhasil diupdate')),
          );
          Navigator.pop(context, true);
        }
      } else {
        await ref.read(invoiceControllerProvider.notifier).createInvoice(
              customerId: _selectedCustomerId!,
              amount: amount,
              dueDate: _selectedDueDate!,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              notes: _notesController.text.isEmpty ? null : _notesController.text,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tagihan berhasil dibuat')),
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
