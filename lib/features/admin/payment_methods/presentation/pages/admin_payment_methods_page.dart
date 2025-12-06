import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../data/providers/auth_provider.dart';

// Payment Method Model
class PaymentMethodModel {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountHolder;
  final int sortOrder;
  final bool isActive;

  PaymentMethodModel({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountHolder,
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id']?.toString() ?? '',
      bankName: json['bank_name']?.toString() ?? '',
      accountNumber: json['account_number']?.toString() ?? '',
      accountHolder: json['account_holder']?.toString() ?? '',
      sortOrder: (json['sort_order'] is int) ? json['sort_order'] : int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] == true,
    );
  }
}

// Provider
final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethodModel>>((ref) async {
  final supabase = ref.read(supabaseClientProvider);
  final response = await supabase.from('payment_methods').select('*').order('sort_order', ascending: true);
  return (response as List).map((e) => PaymentMethodModel.fromJson(e)).toList();
});

class AdminPaymentMethodsPage extends ConsumerStatefulWidget {
  const AdminPaymentMethodsPage({super.key});
  @override
  ConsumerState<AdminPaymentMethodsPage> createState() => _AdminPaymentMethodsPageState();
}

class _AdminPaymentMethodsPageState extends ConsumerState<AdminPaymentMethodsPage> {
  @override
  Widget build(BuildContext context) {
    final methods = ref.watch(paymentMethodsProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F8FB),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: methods.when(
                data: (data) => _buildList(data),
                loading: () => _buildLoading(),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showForm(context),
          backgroundColor: const Color(0xFF683FE4),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back, color: Color(0xFF110E1B))),
              const Expanded(child: Text('Metode Pembayaran', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF110E1B)))),
              const SizedBox(width: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<PaymentMethodModel> data) {
    if (data.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Belum ada metode pembayaran', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
            const SizedBox(height: 8),
            const Text('Klik + untuk menambahkan', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(paymentMethodsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (_, i) => _buildItem(data[i]),
      ),
    );
  }

  Widget _buildItem(PaymentMethodModel method) {
    return GestureDetector(
      onTap: () => _showForm(context, method),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: method.isActive ? Colors.white : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: method.isActive ? const Color(0xFFE5E7EB) : Colors.grey[300]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(0xFFF0F2F4), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.account_balance, color: Color(0xFF110E1B), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(child: Text(method.bankName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF110E1B)), overflow: TextOverflow.ellipsis)),
                      if (!method.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                          child: const Text('Nonaktif', style: TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(method.accountNumber, style: const TextStyle(fontSize: 13, color: Color(0xFF110E1B)), overflow: TextOverflow.ellipsis),
                  Text(method.accountHolder, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, [PaymentMethodModel? method]) async {
    final result = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => _PaymentMethodFormPage(method: method)));
    if (result == true) ref.invalidate(paymentMethodsProvider);
  }
}

// Form Page
class _PaymentMethodFormPage extends ConsumerStatefulWidget {
  final PaymentMethodModel? method;
  const _PaymentMethodFormPage({this.method});
  @override
  ConsumerState<_PaymentMethodFormPage> createState() => _PaymentMethodFormPageState();
}

class _PaymentMethodFormPageState extends ConsumerState<_PaymentMethodFormPage> {
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _sortOrderController = TextEditingController();
  bool _isActive = true;
  bool _isSaving = false;

  bool get isEdit => widget.method != null;

  @override
  void initState() {
    super.initState();
    if (widget.method != null) {
      _bankNameController.text = widget.method!.bankName;
      _accountNumberController.text = widget.method!.accountNumber;
      _accountHolderController.text = widget.method!.accountHolder;
      _sortOrderController.text = widget.method!.sortOrder.toString();
      _isActive = widget.method!.isActive;
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF110E1B)), onPressed: () => Navigator.pop(context)),
        title: Text(isEdit ? 'Edit Bank' : 'Tambah Bank Baru', style: const TextStyle(color: Color(0xFF110E1B), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildField('Nama Bank/E-Wallet *', _bankNameController, 'BCA, BNI, DANA, GoPay, dll'),
                  _buildField('Nomor Rekening *', _accountNumberController, '1234567890', keyboardType: TextInputType.number),
                  _buildField('Nama Pemilik *', _accountHolderController, 'NAMA PEMILIK'),
                  _buildField('Urutan Tampilan', _sortOrderController, '1', keyboardType: TextInputType.number, hint: 'Urutan tampilan (1 = paling atas)'),
                  SwitchListTile(
                    title: const Text('Aktif', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Tampilkan di halaman customer', style: TextStyle(fontSize: 12)),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeColor: const Color(0xFF683FE4),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(backgroundColor: const Color(0xFFEAE8F3), side: BorderSide.none, padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('BATAL', style: TextStyle(color: Color(0xFF110E1B), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF501EE6), padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isSaving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('SIMPAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            if (isEdit) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _delete,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('HAPUS BANK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, String placeholder, {String? hint, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF110E1B))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD6D0E7))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD6D0E7))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          if (hint != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(hint, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_bankNameController.text.trim().isEmpty || _accountNumberController.text.trim().isEmpty || _accountHolderController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi semua field yang diperlukan')));
      return;
    }

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final supabase = ref.read(supabaseClientProvider);
      final data = {
        'bank_name': _bankNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'account_holder': _accountHolderController.text.trim(),
        'sort_order': int.tryParse(_sortOrderController.text) ?? 0,
        'is_active': _isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (isEdit) {
        await supabase.from('payment_methods').update(data).eq('id', widget.method!.id);
      } else {
        await supabase.from('payment_methods').insert(data);
      }

      scaffoldMessenger.showSnackBar(SnackBar(content: Text(isEdit ? 'Bank berhasil diupdate' : 'Bank berhasil ditambahkan'), backgroundColor: const Color(0xFF22C55E)));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: const Color(0xFFDC2626)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bank'),
        content: Text('Yakin ingin menghapus ${widget.method!.bankName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(supabaseClientProvider).from('payment_methods').delete().eq('id', widget.method!.id);
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Bank berhasil dihapus'), backgroundColor: Color(0xFF22C55E)));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e'), backgroundColor: const Color(0xFFDC2626)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
