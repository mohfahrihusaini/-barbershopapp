import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/queue_provider.dart';
import '../../theme/app_colors.dart';

class QueueStatusScreen extends StatelessWidget {
  const QueueStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<QueueProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    // 1. Ambil semua antrian hari ini (GLOBAL)
    final allToday = queueProvider.currentQueue;
    
    // 2. Filter Active Only & Sort (Logic sama dengan Admin)
    final activeGlobalList = allToday.where((r) => 
      ['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(r.statusAntrian)
    ).toList();
    activeGlobalList.sort((a, b) {
      int timeComparison = a.startDateTime.compareTo(b.startDateTime);
      if (timeComparison == 0) return a.waktuBooking.compareTo(b.waktuBooking);
      return timeComparison;
    });

    // 3. Filter antrian milik USER ini saja
    final myQueues = activeGlobalList.where((q) => q.idUser == user?.id).toList();
    final userQueueCount = myQueues.length;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primaryDark.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Antrian Aktif",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userQueueCount.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Posisi Anda dalam antrian",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.queue_outlined,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Detail Antrian",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          if (userQueueCount == 0) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.queue_outlined,
                    size: 60,
                    color: AppColors.textSecondary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Tidak ada antrian aktif",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Silakan buat reservasi terlebih dahulu",
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Tampilkan LIST antrian pengguna secara dinamis
            ...myQueues.map((reservation) {
              // HITUNG POSISI REAL-TIME
              final myPosition = activeGlobalList.indexWhere((r) => r.id == reservation.id) + 1;
              
              // Ambil Detail Nama
              final barberName = bookingProvider.getNamaBarber(reservation.idBarber);
              final serviceName = bookingProvider.getNamaLayanan(reservation.idLayanan);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              "#$myPosition",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Urutan ke-$myPosition",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tiket #${reservation.nomorAntrian} • ${DateFormat('HH:mm').format(reservation.startDateTime)}",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
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
                            color: reservation.getStatusColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: reservation.getStatusColor().withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            reservation.statusAntrian.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: reservation.getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            Icons.calendar_today_outlined, 
                            "Tanggal", 
                            DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(reservation.tanggal)
                          ),
                          const Divider(height: 12),
                          _buildDetailRow(
                            Icons.person_outline, 
                            "Kapster", 
                            barberName
                          ),
                          const Divider(height: 12),
                          _buildDetailRow(
                            Icons.content_cut_outlined, 
                            "Layanan", 
                            serviceName
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Estimasi Waktu",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reservation.estimasiWaktuSelesai != null
                                  ? DateFormat('HH:mm').format(reservation.estimasiWaktuSelesai!)
                                  : "30-45 menit",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        if (reservation.statusAntrian == 'Menunggu')
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Fitur batalkan segera hadir")),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error.withOpacity(0.1),
                              foregroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text("Batalkan"),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.w600, 
            color: AppColors.primaryDark
          ),
        ),
      ],
    );
  }
}
