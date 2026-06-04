import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Import dart:io
import 'package:excel/excel.dart' hide Border; // Hide Border to avoid conflict with Flutter
import 'package:path_provider/path_provider.dart'; // Import path_provider
import 'package:share_plus/share_plus.dart'; // Import share_plus
import 'package:barbershopapp/presentation/theme/app_colors.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/data/models/pembayaran_model.dart';

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  String _selectedPeriod = 'Bulan Ini'; // Default ke bulan ini
  String _selectedFilter = 'Semua Layanan';

  @override
  void initState() {
    super.initState();
    // Load data terbaru saat halaman dibuka
    Future.microtask(() => 
      Provider.of<BookingProvider>(context, listen: false).loadPembayaranList()
    );
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    
    // Hitung ringkasan berdasarkan periode yang dipilih
    int currentRevenue = 0;
    List<PembayaranModel> filteredTransactions = [];
    
    if (_selectedPeriod == 'Hari Ini') {
      currentRevenue = provider.todayRevenue;
      filteredTransactions = provider.pembayaranList.where((p) => 
        p.status.toLowerCase() == 'lunas' && 
        p.createdAt.year == DateTime.now().year &&
        p.createdAt.month == DateTime.now().month &&
        p.createdAt.day == DateTime.now().day
      ).toList();
    } else if (_selectedPeriod == 'Bulan Ini') {
      currentRevenue = provider.monthRevenue;
      filteredTransactions = provider.pembayaranList.where((p) => 
        p.status.toLowerCase() == 'lunas' && 
        p.createdAt.year == DateTime.now().year &&
        p.createdAt.month == DateTime.now().month
      ).toList();
    } else {
      // Default (Semua/Total) jika periode lain belum diimplementasi spesifik
      currentRevenue = provider.totalRevenue;
      filteredTransactions = provider.pembayaranList.where((p) => 
        p.status.toLowerCase() == 'lunas'
      ).toList();
    }

    // Urutkan transaksi dari yang terbaru
    filteredTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text("Laporan Keuangan"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: _exportReport,
            tooltip: "Export Laporan",
          ),
        ],
      ),
      body: provider.isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await Provider.of<BookingProvider>(context, listen: false).loadPembayaranList();
            },
            child: Column(
              children: [
                // Filter Section
                _buildFilterSection(),
                
                // Summary Cards
                _buildSummaryCards(currentRevenue, filteredTransactions.length),
                
                // Expanded untuk konten scrollable
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Agar bisa di-refresh meski konten sedikit
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Revenue Chart
                        _buildRevenueChart(provider.getDailyRevenueData()),
                        
                        const SizedBox(height: 24),
                        
                        // Transaction List
                        _buildTransactionList(filteredTransactions),
                        
                        const SizedBox(height: 24),
                        
                        // Barber Performance
                        // _buildBarberPerformance(), // Sementara hide dummy
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSummaryDialog(currentRevenue, filteredTransactions.length),
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.summarize, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Period Filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.mediumGray),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedPeriod,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  items: const [
                    DropdownMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                    DropdownMenuItem(value: 'Minggu Ini', child: Text('Minggu Ini')), // Fallback ke total
                    DropdownMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedPeriod = value!);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(int revenue, int count) {
    final avg = count > 0 ? revenue ~/ count : 0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              title: "Total Pendapatan",
              value: _formatCurrency(revenue),
              color: AppColors.success,
              icon: Icons.attach_money_outlined,
              trend: "Real",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: "Total Transaksi",
              value: "$count",
              color: AppColors.cyan,
              icon: Icons.receipt_outlined,
              trend: "Order",
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              title: "Rata-rata/Transaksi",
              value: _formatCurrency(avg),
              color: AppColors.gold,
              icon: Icons.analytics_outlined,
              trend: "Avg",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.mediumGray.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(Map<DateTime, int> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tren Pendapatan (7 Hari Terakhir)",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 250, // Increased height to prevent overflow
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: data.entries.map((entry) {
                // Simple Bar Chart Logic
                final maxRevenue = data.values.reduce((a, b) => a > b ? a : b);
                final heightFactor = maxRevenue > 0 ? entry.value / maxRevenue : 0.0;
                
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.value > 0)
                      Text(
                        NumberFormat.compact(locale: 'id_ID').format(entry.value),
                        style: const TextStyle(fontSize: 10),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      width: 20,
                      height: 150 * heightFactor + 10, // Min height 10
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('dd/MM').format(entry.key),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(List<PembayaranModel> transactions) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Transaksi Terbaru",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                "${transactions.length} Item",
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text("Belum ada transaksi")),
            )
          else
            ...transactions.take(10).map((t) => _buildTransactionItem(t)),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(PembayaranModel transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 20,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ID: ...${transaction.id.substring(transaction.id.length - 6)}",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  transaction.metode,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  DateFormat('dd MMM HH:mm', 'id_ID').format(transaction.createdAt),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(transaction.jumlahBayar),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportReport() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    
    // 1. Filter Data (Sama seperti di build)
    List<PembayaranModel> dataToExport = [];
    if (_selectedPeriod == 'Hari Ini') {
      dataToExport = provider.pembayaranList.where((p) => 
        p.status.toLowerCase() == 'lunas' && 
        p.createdAt.year == DateTime.now().year &&
        p.createdAt.month == DateTime.now().month &&
        p.createdAt.day == DateTime.now().day
      ).toList();
    } else if (_selectedPeriod == 'Bulan Ini') {
      dataToExport = provider.pembayaranList.where((p) => 
        p.status.toLowerCase() == 'lunas' && 
        p.createdAt.year == DateTime.now().year &&
        p.createdAt.month == DateTime.now().month
      ).toList();
    } else {
      dataToExport = provider.pembayaranList.where((p) => 
        p.status.toLowerCase() == 'lunas'
      ).toList();
    }
    
    // Sort
    dataToExport.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (dataToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada data untuk diexport")),
      );
      return;
    }

    try {
      // 2. Buat Excel
      var excel = Excel.createExcel();
      
      // Rename default sheet dengan aman
      String defaultSheet = excel.sheets.keys.first;
      String sheetName = 'Laporan Keuangan';
      excel.rename(defaultSheet, sheetName);
      
      Sheet sheet = excel[sheetName];

      // 3. Buat Header Style
      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        backgroundColorHex: ExcelColor.fromHexString("#CCCCCC"),
      );

      // 4. Tulis Header
      List<CellValue> headers = [
        TextCellValue('Tanggal & Waktu'),
        TextCellValue('ID Transaksi'),
        TextCellValue('Metode Pembayaran'),
        TextCellValue('Status'),
        TextCellValue('Jumlah (Rp)'),
      ];
      
      sheet.appendRow(headers);

      // 5. Tulis Data
      for (var item in dataToExport) {
        sheet.appendRow([
          TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt)),
          TextCellValue(item.id),
          TextCellValue(item.metode),
          TextCellValue(item.status),
          IntCellValue(item.jumlahBayar),
        ]);
      }

      // 6. Simpan File ke Temporary Directory
      var fileBytes = excel.save();
      
      if (fileBytes != null) {
        final directory = await getTemporaryDirectory();
        final fileName = "Laporan_Keuangan_${_selectedPeriod.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx";
        final path = "${directory.path}/$fileName";
        
        File(path)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        // 7. Share File
        if (mounted) {
          await Share.shareXFiles(
            [XFile(path)],
            text: 'Export Laporan Keuangan ($_selectedPeriod)',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal export: $e"), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showSummaryDialog(int revenue, int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Ringkasan ${_selectedPeriod}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryItem("Total Pendapatan", _formatCurrency(revenue)),
            _buildSummaryItem("Total Transaksi", "$count transaksi"),
            _buildSummaryItem("Rata-rata", _formatCurrency(count > 0 ? revenue ~/ count : 0)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}