import 'package:flutter/material.dart';
import 'dart:async'; // Added for Timer
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barbershopapp/providers/auth_provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/providers/shop_provider.dart';
import 'package:barbershopapp/providers/queue_provider.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';
import 'booking_form_screen.dart';
import 'booking_history_screen.dart';
import '../auth/login_screen.dart';
import 'client_chat_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';
import 'queue_status_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _queueTimer; // Timer untuk auto-refresh
  bool _hasNotifiedTurn = false; // Mencegah notifikasi berulang

  @override
  void initState() {
    super.initState();
    // Memuat data saat halaman dibuka
    Future.microtask(() {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      final queueProvider = Provider.of<QueueProvider>(context, listen: false);
      
      bookingProvider.loadInitialData();
      shopProvider.loadShopStatus();
      queueProvider.loadQueue(); // Load data antrian terbaru
      
      // Setup Auto-Refresh & Notification Check setiap 60 detik
      _queueTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
        await queueProvider.loadQueue();
        _checkQueueNotification();
      });
    });
  }

  @override
  void dispose() {
    _queueTimer?.cancel();
    super.dispose();
  }

  void _checkQueueNotification() {
    if (!mounted) return;
    final queueProvider = Provider.of<QueueProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;

    if (user != null) {
      // Cek apakah giliran sudah dekat
      final isTurnNear = queueProvider.checkUserTurn(user.id);
      
      // Jika dekat dan belum dinotifikasi
      if (isTurnNear && !_hasNotifiedTurn) {
        setState(() => _hasNotifiedTurn = true);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Giliran Anda sebentar lagi! Mohon bersiap di lokasi.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primaryDark,
            duration: const Duration(seconds: 10), // Tampil cukup lama
            action: SnackBarAction(
              label: "LIHAT",
              textColor: AppColors.gold,
              onPressed: () {
                setState(() => _currentIndex = 2); // Pindah ke tab Antrian
              },
            ),
          ),
        );
      } 
      // Reset flag jika sudah tidak dekat (misal sudah selesai atau batal)
      else if (!isTurnNear) {
        setState(() => _hasNotifiedTurn = false);
      }
    }
  }

  Widget _buildShopStatus(BuildContext context) {
    final shopProvider = Provider.of<ShopProvider>(context);
    
    if (shopProvider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              "Memuat status...",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String? additionalInfo;

    switch (shopProvider.status.toLowerCase()) {
      case 'buka':
        statusColor = AppColors.success;
        statusIcon = Icons.storefront;
        statusText = "BARBERSHOP BUKA";
        break;
      case 'istirahat':
        statusColor = AppColors.warning;
        statusIcon = Icons.coffee;
        statusText = "SEDANG ISTIRAHAT";
        if (shopProvider.breakEndTime != null) {
          final endTime = DateFormat('HH:mm').format(shopProvider.breakEndTime!);
          additionalInfo = "Istirahat selesai pukul $endTime";
        }
        break;
      case 'tutup':
        statusColor = AppColors.error;
        statusIcon = Icons.storefront_outlined;
        statusText = "BARBERSHOP TUTUP";
        if (shopProvider.openTime != null) {
          final openTime = DateFormat('HH:mm').format(shopProvider.openTime!);
          additionalInfo = "Buka lagi besok pukul $openTime";
        }
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = "STATUS TIDAK DIKETAHUI";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (additionalInfo != null) ...[
                const SizedBox(height: 2),
                Text(
                  additionalInfo,
                  style: TextStyle(
                    color: statusColor.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBanner(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final shopProvider = Provider.of<ShopProvider>(context);
    
    return Container(
      width: double.infinity,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, ${user?.nama ?? 'Pelanggan'}! 👋",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Rambut sudah gondrong? Yuk booking sekarang biar tetap kece.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.emoji_events_outlined,
                size: 50,
                color: AppColors.gold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildShopStatus(context),
        ],
      ),
    );
  }

  Widget _buildServicesList(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);

    if (bookingProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (bookingProvider.layananList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(
                Icons.content_cut_outlined,
                size: 60,
                color: AppColors.textSecondary.withOpacity(0.3),
              ),
              const SizedBox(height: 12),
              Text(
                "Belum ada layanan tersedia",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: bookingProvider.layananList.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final layanan = bookingProvider.layananList[index];
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.cyan.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.content_cut_outlined,
                    color: AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layanan.namaLayanan,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Rp ${NumberFormat('#,##0', 'id_ID').format(layanan.harga)}",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${layanan.durasiMenit} menit",
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Cek apakah barbershop sedang tutup
                    if (shopProvider.status.toLowerCase() == 'tutup') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Maaf, barbershop sedang tutup"),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    
                    // Cek apakah sedang istirahat
                    if (shopProvider.status.toLowerCase() == 'istirahat') {
                      if (shopProvider.breakEndTime != null) {
                        final endTime = DateFormat('HH:mm').format(shopProvider.breakEndTime!);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Barbershop sedang istirahat sampai $endTime"),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Barbershop sedang istirahat"),
                            backgroundColor: AppColors.warning,
                          ),
                        );
                      }
                      return;
                    }
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingFormScreen(selectedService: layanan),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text("Pesan"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final isShopClosed = shopProvider.status.toLowerCase() == 'tutup';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BANNER SAMBUTAN DENGAN STATUS
          _buildWelcomeBanner(context),

          const SizedBox(height: 24),

          // 2. TOMBOL BUAT RESERVASI
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isShopClosed
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BookingFormScreen(),
                        ),
                      );
                    },
              icon: const Icon(Icons.calendar_today),
              label: const Text("BUAT RESERVASI BARU"),
              style: ElevatedButton.styleFrom(
                backgroundColor: isShopClosed
                    ? Colors.grey[400]
                    : AppColors.primaryDark,
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 3. INFO ANTRIAN FIFO
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cyan.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.queue,
                    color: AppColors.cyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sistem Antrian FIFO",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Pemesanan diproses berdasarkan urutan kedatangan",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. DAFTAR LAYANAN TERSEDIA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Layanan Tersedia",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                "${bookingProvider.layananList.length} Layanan",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildServicesList(context),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.person_outline, size: 24),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Column(
          children: [
            Text(
              "Kece Barbershop",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            ),
            Text(
              "Pelanggan",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          // Notification Button
          Consumer<BookingProvider>(
            builder: (context, bookingProvider, _) {
              // Filter notifikasi: Booking hari ini yang statusnya sudah diproses (Confirmed/Dibatalkan/Selesai)
              // atau Booking masa depan yang Confirmed.
              final myNotifications = bookingProvider.historyList.where((item) {
                final isToday = item.tanggal.day == DateTime.now().day && 
                                item.tanggal.month == DateTime.now().month &&
                                item.tanggal.year == DateTime.now().year;
                // Tampilkan notifikasi jika statusnya BUKAN Menunggu (artinya sudah ada respon admin)
                // dan BUKAN Selesai (kecuali baru saja selesai hari ini)
                return item.statusAntrian != 'Menunggu'; 
              }).toList();

              // Sort by terbaru
              myNotifications.sort((a, b) => b.tanggal.compareTo(a.tanggal));

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, size: 24),
                    onPressed: () {
                      _showNotifications(context, myNotifications);
                    },
                  ),
                  if (myNotifications.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          "${myNotifications.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _getBody(_currentIndex, context),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ClientChatScreen()),
          );
        },
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.chat, size: 24),
      ),
    );
  }

  void _showNotifications(BuildContext context, List<dynamic> notifications) {
    final queueProvider = Provider.of<QueueProvider>(context, listen: false); // Tambahkan akses QueueProvider

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Notifikasi",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text(
                              "Belum ada notifikasi baru",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];
                          
                          // --- LOGIKA REAL-TIME POSITION ---
                          // Cek posisi di antrian global saat ini
                          final activeGlobalList = queueProvider.currentQueue.where((r) => 
                            ['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(r.statusAntrian)
                          ).toList();
                          activeGlobalList.sort((a, b) {
                            int timeComparison = a.startDateTime.compareTo(b.startDateTime);
                            if (timeComparison == 0) return a.waktuBooking.compareTo(b.waktuBooking);
                            return timeComparison;
                          });
                          
                          final myPosition = activeGlobalList.indexWhere((r) => r.id == item.id) + 1;
                          // ---------------------------------

                          // Tentukan pesan berdasarkan status & posisi
                          String title = "Update Status";
                          String message = "Status pesanan Anda telah diperbarui.";
                          IconData icon = Icons.info_outline;
                          Color color = Colors.grey;

                          if (item.statusAntrian == 'Confirmed') {
                            if (myPosition == 2) {
                              title = "Bersiap! Urutan ke-2 ⚠️";
                              message = "Satu orang lagi sebelum giliran Anda. Mohon segera ke lokasi.";
                              icon = Icons.priority_high;
                              color = Colors.orange;
                            } else {
                              title = "Booking Dikonfirmasi! ✅";
                              message = "Pembayaran diterima. Silakan datang pukul ${item.waktuMulai}.";
                              icon = Icons.check_circle_outline;
                              color = AppColors.success;
                            }
                          } else if (item.statusAntrian == 'Dibatalkan') {
                            title = "Booking Ditolak ❌";
                            message = "Maaf, pembayaran Anda ditolak atau slot penuh.";
                            icon = Icons.cancel_outlined;
                            color = AppColors.error;
                          } else if (item.statusAntrian == 'Sedang Dilayani') {
                            title = "Giliran Anda! ✂️";
                            message = "Silakan duduk, kapster siap melayani Anda.";
                            icon = Icons.content_cut;
                            color = AppColors.primaryDark;
                          } else if (item.statusAntrian == 'Selesai') {
                            title = "Layanan Selesai ✨";
                            message = "Terima kasih telah menggunakan jasa kami!";
                            icon = Icons.star_outline;
                            color = AppColors.gold;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        DateFormat('dd MMM HH:mm', 'id_ID').format(item.waktuBooking),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    return Drawer(
      backgroundColor: AppColors.backgroundLight,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header Drawer
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primaryDark.withOpacity(0.9),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.gold,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.nama ?? 'Pelanggan',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? 'pelanggan@email.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menu Items
          _buildDrawerItem(
            context,
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 0);
            },
            isSelected: _currentIndex == 0,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.history_outlined,
            title: "Riwayat Pesanan",
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 1);
            },
            isSelected: _currentIndex == 1,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.queue_outlined,
            title: "Antrian Saya",
            onTap: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
            },
            isSelected: _currentIndex == 2,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: "Pengaturan",
            onTap: () {
              Navigator.pop(context); // Tutup drawer dulu
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const Divider(thickness: 1),
          _buildDrawerItem(
            context,
            icon: Icons.logout_outlined,
            title: "Keluar",
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: color ??
            (isSelected ? AppColors.primaryDark : AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: color ?? (isSelected ? AppColors.primaryDark : AppColors.textPrimary),
        ),
      ),
      tileColor: isSelected
          ? AppColors.primaryDark.withOpacity(0.1)
          : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: onTap,
    );
  }

  Widget _getBody(int index, BuildContext context) {
    switch (index) {
      case 0:
        return _buildDashboardContent(context);
      case 1:
        return const BookingHistoryScreen();
      case 2:
        return const QueueStatusScreen();
      default:
        return _buildDashboardContent(context);
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() => _currentIndex = index);
      },
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primaryDark,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_outlined),
          activeIcon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.queue_outlined),
          activeIcon: Icon(Icons.queue),
          label: 'Antrian',
        ),
      ],
    );
  }
}