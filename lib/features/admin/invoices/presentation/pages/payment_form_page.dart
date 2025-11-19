import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../data/models/invoice_model.dart';
import '../../../../../data/models/profile_model.dart';
import '../../../../../data/providers/invoice_provider.dart';
import '../../../../../data/providers/whatsapp_notification_provider.dart';

class PaymentFormPage extends ConsumerStatefulWidget {
  final InvoiceModel invoice;

  const PaymentFormPage({super.key, required this.invoice});

  @override
  ConsumerState<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends ConsumerState<PaymentFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedPaymentMethod;
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Cash',
    'Transfer Bank',
    'QRIS',
    'E-Wallet',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    // Set default amount to remaining amount
    _amountController.text = widget.invoice.remainingAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final remainingAmount = invoice.remainingAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proses Pembayaran'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Invoice Info Card
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Tagihan',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nomor Invoice', invoice.invoiceNumber ?? '-'),
                    _buildInfoRow('Pelanggan', invoice.customerName ?? '-'),
                    _buildInfoRow(
                      'Total Tagihan',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(invoice.amount),
                    ),
                    if (invoice.status == 'installment')
                      _buildInfoRow(
                        'Sudah Dibayar',
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(invoice.paidAmount ?? 0),
                      ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      'Sisa Tagihan',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(remainingAmount),
                      valueStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Amount
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Pembayaran *',
                prefixIcon: const Icon(Icons.attach_money),
                prefixText: 'Rp ',
                helperText: 'Maksimal: ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(remainingAmount)}',
                suffixIcon: TextButton(
                  onPressed: () {
                    _amountController.text = remainingAmount.toString();
                  },
                  child: const Text('Lunas'),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Jumlah harus diisi';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Jumlah harus lebih dari 0';
                }
                if (amount > remainingAmount) {
                  return 'Jumlah melebihi sisa tagihan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Method
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              decoration: const InputDecoration(
                labelText: 'Metode Pembayaran *',
                prefixIcon: Icon(Icons.payment),
              ),
              items: _paymentMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Metode pembayaran harus dipilih';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Date
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _paymentDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _paymentDate = date;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal Pembayaran',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('dd MMMM yyyy').format(_paymentDate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
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
                helperText: 'Catatan pembayaran (opsional)',
              ),
            ),
            const SizedBox(height: 32),

            // Payment Summary
            Card(
              color: AppColors.success.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Pembayaran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Jumlah Dibayar',
                      _amountController.text.isEmpty
                          ? 'Rp 0'
                          : NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(double.tryParse(_amountController.text) ?? 0),
                    ),
                    _buildSummaryRow(
                      'Sisa Setelah Bayar',
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: 'Rp ',
                        decimalDigits: 0,
                      ).format(
                        remainingAmount - (double.tryParse(_amountController.text) ?? 0),
                      ),
                    ),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Status Setelah Bayar',
                      _getNewStatus(),
                      valueColor: _getStatusColor(),
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
                backgroundColor: AppColors.success,
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
                  : const Text('Proses Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getNewStatus() {
    final paidAmount = double.tryParse(_amountController.text) ?? 0;
    final remaining = widget.invoice.remainingAmount - paidAmount;

    if (remaining <= 0) {
      return 'LUNAS';
    } else if (paidAmount > 0) {
      return 'CICILAN';
    } else {
      return 'BELUM BAYAR';
    }
  }

  Color _getStatusColor() {
    final status = _getNewStatus();
    switch (status) {
      case 'LUNAS':
        return AppColors.success;
      case 'CICILAN':
        return AppColors.secondary;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final paidAmount = double.parse(_amountController.text);

      // Process payment
      await ref.read(invoiceControllerProvider.notifier).processPayment(
            invoiceId: widget.invoice.id!,
            paidAmount: paidAmount,
            paymentMethod: _selectedPaymentMethod!,
            notes: _notesController.text.isEmpty ? null : _notesController.text,
          );

      // Get updated invoice data and send WhatsApp notification
      if (widget.invoice.customerId != null) {
        try {
          // Fetch updated invoice
          final updatedInvoice = await ref.read(invoiceByIdProvider(widget.invoice.id!).future);
          
          // Fetch customer profile
          final supabase = Supabase.instance.client;
          final profileData = await supabase
              .from('profiles')
              .select()
              .eq('id', widget.invoice.customerId!)
              .single();
          
          final customerProfile = ProfileModel.fromJson(profileData);
          
          // Send WhatsApp notification
          final paymentMethodKey = _selectedPaymentMethod!.toLowerCase().replaceAll(' ', '');
          final notificationResult = await ref.read(whatsappNotificationControllerProvider.notifier).sendPaymentNotification(
            customerData: customerProfile,
            invoiceData: updatedInvoice,
            paymentMethod: paymentMethodKey,
          );
          
          // Show notification result (optional, don't block success message)
          if (notificationResult['success'] == true) {
            print('WhatsApp notification sent successfully');
          } else {
            print('WhatsApp notification failed: ${notificationResult['message']}');
          }
        } catch (e) {
          print('Error sending WhatsApp notification: $e');
          // Don't fail the payment process if notification fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil diproses'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
