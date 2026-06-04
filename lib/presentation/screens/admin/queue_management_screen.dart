import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';
import 'package:barbershopapp/providers/queue_provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/data/models/reservasi_model.dart';
import 'package:barbershopapp/data/models/barber_model.dart';
import 'package:barbershopapp/data/models/layanan_model.dart'; // Import ini

class QueueManagementScreen extends StatefulWidget {
  const QueueManagementScreen({super.key});

  @override
  State<QueueManagementScreen> createState() => _QueueManagementScreenState();
}

class _QueueManagementScreenState extends State<QueueManagementScreen> {
  String _selectedBarber = 'Semua Kapster';
  String _selectedStatus = 'Semua Status';
  bool _showCompleted = false;
  bool _isStatsExpanded = false;
  bool _isOptionsExpanded = false;
  bool _isFiltersExpanded = false;

  @override
  void initState() {
    super.initState();
    // Load queue data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      queueProvider.loadQueue();
      bookingProvider.loadPembayaranList();
      
      // Load barber data if empty
      if (bookingProvider.barberList.isEmpty) {
        bookingProvider.loadInitialData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<QueueProvider>(context);
    final currentQueue = queueProvider.currentQueue;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text("Kelola Antrian"),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh queue
              final queueProvider = Provider.of<QueueProvider>(context, listen: false);
              queueProvider.loadQueue();
            },
            tooltip: "Refresh Antrian",
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          
          // Queue Stats Header & Content
          InkWell(
            onTap: () {
              setState(() {
                _isStatsExpanded = !_isStatsExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.mediumGray.withOpacity(0.5)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart_rounded, 
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Informasi Antrian", 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: AppColors.primaryDark,
                          fontSize: 14,
                        ),
                      ),
                      if (!_isStatsExpanded) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.waiting.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${currentQueue.where((q) => q.statusAntrian == 'Menunggu').length} Menunggu",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.waiting,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.inProgress.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${currentQueue.where((q) => q.statusAntrian == 'Sedang Dilayani').length} Dilayani",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.inProgress,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Icon(
                    _isStatsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedCrossFade(
            firstChild: Container(), // Tampilan saat tertutup (sudah dihandle header)
            secondChild: _buildQueueStats(currentQueue),
            crossFadeState: _isStatsExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
          
          // Queue List
          Expanded(
            child: _buildQueueList(currentQueue, queueProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQueueActions(context, queueProvider);
        },
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.play_arrow, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterSection() {
    final queueProvider = Provider.of<QueueProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);
    
    // Siapkan list barber untuk dropdown
    List<String> barberNames = ['Semua Kapster'];
    barberNames.addAll(bookingProvider.barberList.map((b) => b.namaBarber));

    // Pastikan _selectedBarber valid (ada di list), jika tidak reset ke 'Semua Kapster'
    if (!barberNames.contains(_selectedBarber)) {
      _selectedBarber = 'Semua Kapster';
    }
    
    return Container(
      color: AppColors.backgroundLight,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Collapsible Main Filter Header
          InkWell(
            onTap: () {
              setState(() {
                _isFiltersExpanded = !_isFiltersExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _isFiltersExpanded ? Colors.transparent : AppColors.mediumGray.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 20, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Filter & Tanggal",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      if (!_isFiltersExpanded)
                        Text(
                          "${DateFormat('d MMM', 'id_ID').format(queueProvider.selectedDate)} • $_selectedBarber • $_selectedStatus",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Icon(
                    _isFiltersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          if (_isFiltersExpanded) ...[
            const SizedBox(height: 12),
            // DATE PICKER
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: queueProvider.selectedDate,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2030),
                );
                if (picked != null && picked != queueProvider.selectedDate) {
                  queueProvider.updateDate(picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryDark.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, color: AppColors.primaryDark, size: 20),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tanggal Antrian",
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(queueProvider.selectedDate),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            
            Row(
              children: [
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
                        value: _selectedBarber,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        items: barberNames.map((name) {
                          return DropdownMenuItem(
                            value: name, 
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedBarber = value!);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                        value: _selectedStatus,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                        items: const [
                          DropdownMenuItem(value: 'Semua Status', child: Text('Semua Status')),
                          DropdownMenuItem(value: 'Menunggu', child: Text('Menunggu')),
                          DropdownMenuItem(value: 'Sedang Dilayani', child: Text('Sedang Dilayani')),
                          DropdownMenuItem(value: 'Selesai', child: Text('Selesai')),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value!);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 12),
          
          // Collapsible Options Header
          InkWell(
            onTap: () {
              setState(() {
                _isOptionsExpanded = !_isOptionsExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.tune, size: 16, color: AppColors.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    "Opsi Tambahan",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  // Tampilkan indikator status jika tertutup
                  if (!_isOptionsExpanded && _showCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "Riwayat Aktif",
                        style: TextStyle(fontSize: 10, color: AppColors.primaryDark),
                      ),
                    ),
                  Icon(
                    _isOptionsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          if (_isOptionsExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.mediumGray.withOpacity(0.5)),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        dense: true,
                        title: Text(
                          "Lihat Riwayat",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        value: _showCompleted,
                        onChanged: (value) {
                          setState(() => _showCompleted = value);
                        },
                        activeColor: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddToQueueDialog(context);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Manual"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQueueStats(List<ReservasiModel> queue) {
    final waiting = queue.where((q) => q.statusAntrian == 'Menunggu').length;
    final inProgress = queue.where((q) => q.statusAntrian == 'Sedang Dilayani').length;
    final completed = queue.where((q) => q.statusAntrian == 'Selesai').length;
    final estimatedTime = _calculateTotalWaitTime(queue);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatItem(
            value: waiting.toString(),
            label: "Menunggu",
            color: AppColors.waiting,
          ),
          _buildDivider(),
          _buildStatItem(
            value: inProgress.toString(),
            label: "Dilayani",
            color: AppColors.inProgress,
          ),
          _buildDivider(),
          _buildStatItem(
            value: completed.toString(),
            label: "Selesai",
            color: AppColors.completed,
          ),
          _buildDivider(),
          _buildStatItem(
            value: "${estimatedTime.inMinutes}m",
            label: "Estimasi Total",
            color: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label, required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: AppColors.mediumGray.withOpacity(0.5),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildQueueList(List<ReservasiModel> queue, QueueProvider queueProvider) {
    // Filter queue based on selections
    List<ReservasiModel> filteredQueue = queue;
    
    // Filter Kapster
    if (_selectedBarber != 'Semua Kapster') {
      try {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        final selectedBarberData = bookingProvider.barberList.firstWhere(
          (b) => b.namaBarber == _selectedBarber
        );
        filteredQueue = filteredQueue.where((q) => q.idBarber == selectedBarberData.id).toList();
      } catch (_) {
        // Jika nama barber tidak ditemukan (misal dihapus), kita abaikan filter ini
      }
    }

    if (_selectedStatus != 'Semua Status') {
      filteredQueue = filteredQueue.where((q) => q.statusAntrian == _selectedStatus).toList();
    }
    
    if (!_showCompleted) {
      filteredQueue = filteredQueue.where((q) => q.statusAntrian != 'Selesai').toList();
    }
    
    // Sort by Schedule Time (Waktu Pelayanan)
    // Agar yang jadwalnya pagi (09:00) muncul duluan dibanding yang siang (14:00)
    // meskipun yang siang booking duluan.
    filteredQueue.sort((a, b) {
      // Bandingkan waktu mulai pelayanan
      int timeComparison = a.startDateTime.compareTo(b.startDateTime);
      
      // Jika jamnya sama persis (jarang terjadi), baru lihat siapa yang booking duluan
      if (timeComparison == 0) {
        return a.waktuBooking.compareTo(b.waktuBooking);
      }
      
      return timeComparison;
    });

    if (filteredQueue.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.queue_outlined,
                size: 80,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                "Tidak ada antrian",
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Hitung nomor urut visual (Posisi Antrian Saat Ini)
    // 1. Ambil semua antrian hari ini
    final allToday = List<ReservasiModel>.from(queueProvider.currentQueue);
    // 2. Filter hanya yang AKTIF (Menunggu / Sedang Dilayani) dan urutkan waktu
    final activeList = allToday.where((r) => 
      ['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(r.statusAntrian)
    ).toList();
    
    // Urutkan berdasarkan waktu (FIFO Jadwal)
    activeList.sort((a, b) {
      int timeComparison = a.startDateTime.compareTo(b.startDateTime);
      if (timeComparison == 0) return a.waktuBooking.compareTo(b.waktuBooking);
      return timeComparison;
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredQueue.length,
      itemBuilder: (context, index) {
        final reservation = filteredQueue[index];
        
        // Cari posisi dia di antrian AKTIF
        // Jika statusnya 'Selesai', dia tidak punya nomor antrian (tampilkan -)
        // Jika statusnya 'Menunggu/Sedang Dilayani', nomornya adalah Index + 1
        int displayQueueNumber = 0;
        
        if (['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(reservation.statusAntrian)) {
          // +1 karena index mulai dari 0
          displayQueueNumber = activeList.indexWhere((r) => r.id == reservation.id) + 1;
        }

        return _buildQueueItem(reservation, queueProvider, displayQueueNumber);
      },
    );
  }

  Widget _buildQueueItem(ReservasiModel reservation, QueueProvider queueProvider, int displayNumber) {
    // Get barber info
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    String barberName = "Unknown";
    String serviceName = "Layanan Tidak Dikenal"; // Variabel layanan

    try {
      if (bookingProvider.barberList.isNotEmpty) {
        final barber = bookingProvider.barberList.firstWhere(
          (b) => b.id == reservation.idBarber,
        );
        barberName = barber.namaBarber;
      } else {
        barberName = "Loading...";
      }
      
      // Ambil nama layanan
      if (bookingProvider.layananList.isNotEmpty) {
        final service = bookingProvider.layananList.firstWhere(
          (s) => s.id == reservation.idLayanan,
          orElse: () => LayananModel(id: '', namaLayanan: 'Layanan dihapus', harga: 0, durasiMenit: 0),
        );
        serviceName = service.namaLayanan;
      }
    } catch (_) {
      barberName = "Kapster #${reservation.idBarber.substring(0, 4)}";
    }

    // Cek metode pembayaran
    String? paymentMethod;
    try {
      final payment = bookingProvider.pembayaranList.firstWhere(
        (p) => p.idReservasi == reservation.id,
      );
      paymentMethod = payment.metode;
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Queue Number
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: reservation.getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: reservation.getStatusColor(),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  displayNumber > 0 ? "#$displayNumber" : "✓",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: reservation.getStatusColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Customer Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.namaPemesan.isNotEmpty 
                        ? reservation.namaPemesan 
                        : "Pelanggan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Indikator Bayar Ditempat
                  if (paymentMethod != null && 
                      (paymentMethod.contains('Ditempat') || paymentMethod.contains('Cash')))
                    Container(
                      margin: const EdgeInsets.only(top: 4, bottom: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.money, size: 12, color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            "Bayar Ditempat",
                            style: TextStyle(fontSize: 10, color: Colors.green[800], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 4),
                  
                  // TAMPILKAN LAYANAN (BARU)
                  Row(
                    children: [
                      Icon(Icons.spa_outlined, size: 12, color: AppColors.primaryDark),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          serviceName,
                          style: TextStyle(
                            fontSize: 13, 
                            color: AppColors.primaryDark, 
                            fontWeight: FontWeight.bold // Ditebalkan agar menonjol
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  // Barber Info & Ticket Number
                  Row(
                    children: [
                      Icon(Icons.content_cut, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        "Kapster: $barberName",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Container(width: 1, height: 10, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        "Tiket #${reservation.nomorAntrian}",
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Jadwal: ${DateFormat('dd MMM yyyy', 'id_ID').format(reservation.tanggal)}",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Jam: ${reservation.waktuMulai} WIB",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 12,
                        color: AppColors.textSecondary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "Dibuat: ${_formatTime(reservation.waktuBooking)}",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  if (reservation.estimasiWaktuSelesai != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Estimasi: ${_formatTime(reservation.estimasiWaktuSelesai!)}",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            // Status and Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: reservation.getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: reservation.getStatusColor().withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    reservation.statusAntrian,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: reservation.getStatusColor(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (reservation.statusAntrian == 'Menunggu')
                  ElevatedButton(
                    onPressed: () async {
                      final success = await queueProvider.updateReservationStatus(reservation.id, 'Sedang Dilayani');
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(queueProvider.error ?? "Gagal mengubah status"),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      "Mulai",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (reservation.statusAntrian == 'Sedang Dilayani')
                  ElevatedButton(
                    onPressed: () async {
                      final success = await queueProvider.updateReservationStatus(reservation.id, 'Selesai');
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(queueProvider.error ?? "Gagal mengubah status: Unknown Error"),
                            backgroundColor: AppColors.error,
                            duration: const Duration(seconds: 4), // Tampil lebih lama
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      minimumSize: const Size(0, 0),
                    ),
                    child: const Text(
                      "Selesai",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                if (reservation.statusAntrian == 'Selesai')
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Hapus Riwayat?"),
                          content: const Text(
                              "Data antrian ini akan dihapus permanen. Lanjutkan?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Batal"),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                queueProvider.deleteQueueItem(reservation.id);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text("Hapus"),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: "Hapus dari daftar",
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Duration _calculateTotalWaitTime(List<ReservasiModel> queue) {
    int totalMinutes = 0;
    for (final reservation in queue) {
      if (reservation.statusAntrian == 'Menunggu') {
        totalMinutes += 30; // Default service time
      }
    }
    return Duration(minutes: totalMinutes);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showQueueActions(BuildContext context, QueueProvider queueProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // Allow custom height
      builder: (context) {
        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom, // Handle keyboard
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Aksi Antrian",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.skip_next, color: AppColors.primaryDark),
                    title: const Text("Layani Berikutnya"),
                    subtitle: const Text("Pindah ke antrian berikutnya"),
                    onTap: () {
                      Navigator.pop(context);
                      queueProvider.serveNextCustomer();
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.restart_alt, color: AppColors.primaryDark),
                    title: const Text("Reset Antrian"),
                    subtitle: const Text("Kosongkan semua antrian"),
                    onTap: () {
                      Navigator.pop(context);
                      _showResetQueueDialog(context, queueProvider);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.notifications_active, color: AppColors.primaryDark),
                    title: const Text("Broadcast Status"),
                    subtitle: const Text("Kirim notifikasi ke pelanggan"),
                    onTap: () {
                      Navigator.pop(context);
                      _showBroadcastDialog(context);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Tutup"),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAddToQueueDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Tambah Antrian Manual"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Nama Pelanggan",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Layanan",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: "Nomor Telepon",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement manual queue addition
              Navigator.pop(context);
            },
            child: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  void _showResetQueueDialog(BuildContext context, QueueProvider queueProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Antrian"),
        content: const Text("Apakah Anda yakin ingin mereset semua antrian? Tindakan ini tidak dapat dibatalkan."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement queue reset
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Broadcast Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Kirim pesan broadcast ke semua pelanggan:"),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Misal: 'Antrian sedang padat, estimasi tunggu 45 menit'",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement broadcast
              Navigator.pop(context);
            },
            child: const Text("Kirim"),
          ),
        ],
      ),
    );
  }
}