import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barbershopapp/providers/auth_provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Menunggu', 'Diproses', 'Selesai', 'Dibatalkan'

  @override
  void initState() {
    super.initState();
    // Ambil data history saat halaman dibuka
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user != null) {
      Future.microtask(() => Provider.of<BookingProvider>(context, listen: false)
          .loadUserHistory(user.id));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return AppColors.success;
      case 'menunggu':
      case 'pending':
        return AppColors.gold;
      case 'diproses':
        return AppColors.cyan;
      case 'dibatalkan':
      case 'ditolak':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
      case 'lunas':
        return Icons.check_circle_outline;
      case 'menunggu':
      case 'pending':
        return Icons.schedule_outlined;
      case 'diproses':
        return Icons.play_circle_outline;
      case 'dibatalkan':
      case 'ditolak':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Menunggu', 'Diproses', 'Selesai', 'Dibatalkan'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter : 'Semua';
                });
              },
              selectedColor: AppColors.primaryDark.withOpacity(0.1),
              backgroundColor: AppColors.backgroundLight,
              checkmarkColor: AppColors.primaryDark,
              labelStyle: TextStyle(
                color: _selectedFilter == filter ? AppColors.primaryDark : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedFilter == filter ? AppColors.primaryDark : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<dynamic> _getFilteredHistory(List<dynamic> history) {
    if (_selectedFilter == 'Semua') return history;
    
    String statusFilter = '';
    switch (_selectedFilter.toLowerCase()) {
      case 'menunggu':
        statusFilter = 'menunggu';
        break;
      case 'diproses':
        statusFilter = 'diproses';
        break;
      case 'selesai':
        statusFilter = 'selesai';
        break;
      case 'dibatalkan':
        statusFilter = 'dibatalkan';
        break;
    }
    
    return history.where((item) => 
      item.statusAntrian?.toLowerCase() == statusFilter
    ).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum Ada Riwayat Pesanan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Semua pesanan Anda akan muncul di sini",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final filteredHistory = _getFilteredHistory(provider.historyList);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Pesanan"),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: provider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryDark,
              ),
            )
          : provider.historyList.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    // Stats Cards
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primaryDark.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Total Pesanan",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${provider.historyList.length}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Selesai",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${provider.historyList.where((item) => item.statusAntrian?.toLowerCase() == 'selesai').length}",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Filter Chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildFilterChips(),
                    ),
                    const SizedBox(height: 16),
                    // History List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredHistory.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredHistory[index];
                          final formattedDate = DateFormat('dd MMM yyyy', 'id_ID').format(item.tanggal);
                          final formattedDay = DateFormat('EEEE', 'id_ID').format(item.tanggal);
                          final namaLayanan = provider.getNamaLayanan(item.idLayanan);
                          final namaBarber = provider.getNamaBarber(item.idBarber);
                          final hargaLayanan = provider.getHargaLayanan(item.idLayanan);
                          final status = item.statusAntrian;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              namaLayanan,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "$formattedDay, $formattedDate",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _getStatusColor(status).withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getStatusIcon(status),
                                              size: 14,
                                              color: _getStatusColor(status),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              status.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: _getStatusColor(status),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Details Row
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.cyan.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.access_time_outlined,
                                          size: 16,
                                          color: AppColors.cyan,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Jam Booking",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              item.waktuMulai,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 16,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Kapster",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              namaBarber,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Price and Actions
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Total Biaya",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          Text(
                                            _formatPrice(hargaLayanan),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.success,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (status.toLowerCase() == 'menunggu' || 
                                          status.toLowerCase() == 'pending')
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () {
                                                // TODO: Implement edit booking
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.textSecondary,
                                                side: BorderSide(
                                                  color: Colors.grey.withOpacity(0.3),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                              ),
                                              child: const Text("Ubah"),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () {
                                                // TODO: Implement cancel booking
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    title: Text(
                                                      "Batalkan Pesanan",
                                                      style: TextStyle(
                                                        color: AppColors.primaryDark,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                    content: Text(
                                                      "Apakah Anda yakin ingin membatalkan pesanan ini?",
                                                      style: TextStyle(
                                                        color: AppColors.textSecondary,
                                                      ),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: Text(
                                                          "Batal",
                                                          style: TextStyle(
                                                            color: AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          // TODO: Implement cancel logic
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            const SnackBar(
                                                              content: Text("Pesanan berhasil dibatalkan"),
                                                              backgroundColor: AppColors.success,
                                                            ),
                                                          );
                                                        },
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppColors.error,
                                                        ),
                                                        child: const Text(
                                                          "Ya, Batalkan",
                                                          style: TextStyle(color: Colors.white),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: AppColors.error,
                                                side: BorderSide(
                                                  color: AppColors.error.withOpacity(0.3),
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 8,
                                                ),
                                              ),
                                              child: const Text("Batalkan"),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}