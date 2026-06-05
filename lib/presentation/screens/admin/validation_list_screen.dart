import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/providers/queue_provider.dart';
import 'package:barbershopapp/data/models/pembayaran_model.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ValidationListScreen extends StatefulWidget {
  const ValidationListScreen({super.key});

  @override
  State<ValidationListScreen> createState() => _ValidationListScreenState();
}

class _ValidationListScreenState extends State<ValidationListScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Pending', 'Lunas', 'Ditolak'
  
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<BookingProvider>(context, listen: false).loadPembayaranList());
  }

  // Fungsi untuk menampilkan gambar bukti transfer di popup
  void _showBuktiDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Bukti Pembayaran",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryDark,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 60,
                          color: AppColors.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Gagal memuat gambar",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Tutup",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
        return AppColors.success;
      case 'pending':
        return AppColors.gold;
      case 'ditolak':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.payment_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum Ada Pembayaran",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tidak ada pembayaran yang perlu divalidasi",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Pending', 'Lunas', 'Ditolak'];
    
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

  List<PembayaranModel> _getFilteredPayments(List<PembayaranModel> payments) {
    if (_selectedFilter == 'Semua') return payments;
    return payments.where((payment) => payment.status.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final filteredPayments = _getFilteredPayments(provider.pembayaranList);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Validasi Pembayaran"),
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
          : provider.pembayaranList.isEmpty
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
                                    "Menunggu Validasi",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${provider.pembayaranList.where((p) => p.status == 'Pending').length}",
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
                                    "Total Lunas",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${provider.pembayaranList.where((p) => p.status == 'Lunas').length}",
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
                    // Payment List
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredPayments.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(filteredPayments[index], provider);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // Helper untuk fetch detail lengkap (Reservasi + User)
  Future<Map<String, dynamic>> _fetchDetails(BookingProvider provider, String reservationId) async {
    try {
      final reservasi = await provider.getReservasiById(reservationId);
      // Fetch User (bisa gagal jika user dihapus, jadi try-catch nested)
      try {
        final user = await provider.getUserById(reservasi.idUser);
        return {'reservasi': reservasi, 'user': user};
      } catch (_) {
        return {'reservasi': reservasi, 'user': null};
      }
    } catch (_) {
      return {};
    }
  }

  Widget _buildPaymentCard(PembayaranModel item, BookingProvider provider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDetails(provider, item.idReservasi),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final reservasi = data?['reservasi']; // Bisa null jika loading/error
        final user = data?['user']; // Bisa null

        String layananName = "Memuat...";
        String barberName = "Memuat...";
        String customerName = "Memuat...";
        String customerEmail = "-";
        String customerPhone = "-";
        String bookingTime = "-";

        if (reservasi != null) {
          customerName = reservasi.namaPemesan;
          layananName = provider.getNamaLayanan(reservasi.idLayanan);
          barberName = provider.getNamaBarber(reservasi.idBarber);
          
          // Format Tanggal & Jam
          bookingTime = "${DateFormat('EEE, d MMM', 'id_ID').format(reservasi.tanggal)} • ${reservasi.waktuMulai} WIB";
        }
        
        if (user != null) {
          customerEmail = user.email;
          customerPhone = user.telepon;
        }

        // --- LOGIKA PENGUNCIAN VALIDASI (BARU) ---
        bool isCOD = item.metode.contains('Ditempat') || item.metode.contains('Cash');
        bool isQueueFinished = reservasi?.statusAntrian == 'Selesai';
        bool isValidationLocked = isCOD && !isQueueFinished;

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
              color: isValidationLocked ? AppColors.gold.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
              width: isValidationLocked ? 2 : 1,
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
                    Text(
                      _formatPrice(item.jumlahBayar),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(item.status).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _getStatusColor(item.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // DETAIL LENGKAP
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                else ...[
                  // ID Pesanan & Jam Booking
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tag, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item.idReservasi.substring(item.idReservasi.length - 6),
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isValidationLocked ? AppColors.gold.withOpacity(0.1) : AppColors.primaryDark.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isValidationLocked ? AppColors.gold.withOpacity(0.3) : AppColors.primaryDark.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isValidationLocked ? Icons.lock_clock : Icons.access_time_filled, 
                                size: 12, 
                                color: isValidationLocked ? AppColors.gold : AppColors.primaryDark
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isValidationLocked ? "Menunggu Kapster Selesai" : bookingTime,
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: isValidationLocked ? AppColors.gold : AppColors.primaryDark, 
                                    fontWeight: FontWeight.bold
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  _buildDetailRow(Icons.person, "Pemesan", customerName),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.content_cut, "Layanan", layananName),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.face, "Kapster", barberName),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.email_outlined, "Email", customerEmail),
                  const SizedBox(height: 4),
                  _buildDetailRow(Icons.phone_outlined, "Telepon", customerPhone),
                  
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                ],

                // Payment Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.payment_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.metode,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (isCOD)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          "COD",
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isValidationLocked)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 14, color: AppColors.gold),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Menunggu kapster menyelesaikan antrian",
                                  style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showBuktiDialog(item.buktiBayarUrl),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyan,
                        side: BorderSide(
                          color: AppColors.cyan.withOpacity(0.3),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.image_outlined, size: 18),
                      label: const Text("Bukti"),
                    ),
                    if (item.status == 'Pending') ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isValidationLocked ? null : () async {
                          try {
                            await provider.verifyPembayaran(item.id, true);
                            
                            // Refresh Queue agar reservasi masuk ke antrian aktif (Confirmed)
                            if (context.mounted) {
                              Provider.of<QueueProvider>(context, listen: false).loadQueue();
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Pembayaran ${_formatPrice(item.jumlahBayar)} diterima",
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Gagal: $e"),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isValidationLocked ? Colors.grey[300] : AppColors.success,
                          foregroundColor: isValidationLocked ? Colors.grey[600] : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text("Terima"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await provider.verifyPembayaran(item.id, false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Pembayaran ${_formatPrice(item.jumlahBayar)} ditolak",
                                  ),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Gagal: $e"),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text("Tolak"),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Text(": ", style: TextStyle(color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}