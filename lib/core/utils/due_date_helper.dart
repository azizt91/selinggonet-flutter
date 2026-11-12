/// Jatuh tempo pelanggan mengikuti tanggal pasang (installation date):
/// tanggal jatuh tempo = tanggal pasang, pada bulan periode tagihan.
///
/// Contoh: pelanggan dipasang tanggal 14 Maret 2021, tagihan periode
/// "November 2026" jatuh tempo 14 November 2026.
///
/// Ini menggantikan `invoices.due_date` dari database, yang diisi oleh
/// fungsi `create_monthly_invoices_v2()` dengan tanggal 10 bulan
/// berikutnya untuk semua pelanggan (bukan tanggal pasang).
DateTime? dueDateForInvoice({
  required DateTime? installationDate,
  required String? invoicePeriod,
  DateTime? fallbackDueDate,
}) {
  if (installationDate == null) return fallbackDueDate;
  if (invoicePeriod == null) return fallbackDueDate;

  final parts = invoicePeriod.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return fallbackDueDate;

  const months = {
    'Januari': 1,
    'Februari': 2,
    'Maret': 3,
    'April': 4,
    'Mei': 5,
    'Juni': 6,
    'Juli': 7,
    'Agustus': 8,
    'September': 9,
    'Oktober': 10,
    'November': 11,
    'Desember': 12,
  };
  final month = months[parts[0]];
  final year = int.tryParse(parts[1]);
  if (month == null || year == null) return fallbackDueDate;

  // Tanggal pasang 29-31 dijepit ke hari terakhir bulan itu.
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = installationDate.day > lastDay ? lastDay : installationDate.day;
  return DateTime(year, month, day);
}
