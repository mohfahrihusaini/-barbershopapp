import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbershopapp/providers/auth_provider.dart';
import 'package:barbershopapp/providers/queue_provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart'; // Import ini
import 'package:barbershopapp/providers/shop_provider.dart';
import 'package:barbershopapp/data/models/user_model.dart';
import 'package:barbershopapp/data/models/pembayaran_model.dart'; // Import ini
import 'package:barbershopapp/data/models/reservasi_model.dart';   // Import ini
import 'package:intl/intl.dart'; // Import intl untuk format uang
import 'package:barbershopapp/presentation/theme/app_colors.dart';
import 'manage_service_screen.dart';
import 'manage_barber_screen.dart';
import 'validation_list_screen.dart';
import '../auth/login_screen.dart';

// Import screen baru
import 'financial_report_screen.dart';
import 'queue_management_screen.dart';
import 'shop_setting_screen.dart';
import 'admin_chat_list_screen.dart';
import 'package:barbershopapp/providers/chat_provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // bool _shopOpen = true; // HAPUS variabel lokal ini, ganti dengan provider

  // Sample data for notifications
  int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    // Load status toko dan data keuangan saat dashboard dibuka
    Future.microtask(() {
      final contextRef = context; 
      if (!mounted) return;
      Provider.of<ShopProvider>(contextRef, listen: false).loadShopStatus();
      Provider.of<BookingProvider>(contextRef, listen: false).loadPembayaranList();
      Provider.of<QueueProvider>(contextRef, listen: false).loadQueue();
      Provider.of<ChatProvider>(contextRef, listen: false).loadAdminRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    final queueProvider = Provider.of<QueueProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final isShopOpen = shopProvider.isShopOpen();

    // Hitung Notifikasi Real-time
    final bookingProvider = Provider.of<BookingProvider>(context); // Listen to booking
    final pendingPayments = bookingProvider.pembayaranList.where((p) => p.status == 'Pending').toList();
    final newQueues = queueProvider.currentQueue.where((q) => q.statusAntrian == 'Menunggu').toList();
    final int notificationCount = pendingPayments.length + newQueues.length;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.person_outline, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              "Panel Admin",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          // Shop Status Indicator
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isShopOpen
                  ? AppColors.success.withOpacity(0.2)
                  : AppColors.error.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isShopOpen ? AppColors.success : AppColors.error,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isShopOpen ? Icons.storefront : Icons.storefront_outlined,
                  size: 14,
                  color: isShopOpen ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 4),
                Text(
                  isShopOpen ? "BUKA" : "TUTUP",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isShopOpen ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          // Notification Button
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 26),
                onPressed: () {
                  _showNotifications(context, pendingPayments, newQueues);
                },
              ),
              if (notificationCount > 0)
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
                      notificationCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          // Chat Button (BARU)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, size: 24),
                tooltip: 'Chat Pelanggan',
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminChatListScreen()),
                  );
                },
              ),
              if (chatProvider.totalUnreadCount > 0)
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
                      chatProvider.totalUnreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildDrawer(context, user),
      body: _getBody(_currentIndex, context, queueProvider),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0 ? _buildQuickActions(context) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // Drawer/Side Menu
  Widget _buildDrawer(BuildContext context, UserModel? user) {
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
                    user?.nama ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    user?.email ?? 'admin@kecebarbershop.com',
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
            title: "Dashboard Utama",
            onTap: () {
              setState(() => _currentIndex = 0);
              Navigator.pop(context);
            },
            isSelected: _currentIndex == 0,
          ),
          _buildDrawerItem(
            context,
            icon: Icons.leaderboard_outlined,
            title: "Laporan Keuangan",
            onTap: () {
              Navigator.pop(context); // Tutup drawer dulu
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinancialReportScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.settings_outlined,
            title: "Pengaturan Toko",
            onTap: () {
              Navigator.pop(context); // Tutup drawer dulu
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShopSettingsScreen(),
                ),
              );
            },
          ),
          _buildDrawerItem(
            context,
            icon: Icons.security_outlined,
            title: "Keamanan Akun",
            onTap: () {
              Navigator.pop(context); // Tutup drawer dulu
              _showSecuritySettings(context);
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

  // Body berdasarkan selected index
  Widget _getBody(int index, BuildContext context, QueueProvider queueProvider) {
    switch (index) {
      case 0:
        return _buildDashboardBody(context, queueProvider);
      case 1:
        return const QueueManagementScreen();
      case 2:
        return const ValidationListScreen();
      default:
        return _buildDashboardBody(context, queueProvider);
    }
  }

  // Dashboard Main Body
  Widget _buildDashboardBody(BuildContext context, QueueProvider queueProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Card
          _buildWelcomeCard(context),
          
          const SizedBox(height: 24),
          
          // Stats Row
          _buildStatsRow(context, queueProvider),
          
          const SizedBox(height: 32),
          
          // Quick Actions Title
          Text(
            "Menu Cepat",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick Actions Grid
          _buildQuickActionsGrid(context),
          
          const SizedBox(height: 32),
          
          // Recent Activity
          _buildRecentActivity(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).currentUser;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDark.withOpacity(0.9),
          ],
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Selamat Datang,",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.nama ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Kelola semua operasional barbershop dari sini",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.emoji_events_outlined,
            size: 60,
            color: AppColors.gold,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, QueueProvider queueProvider) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final todayRevenue = bookingProvider.todayRevenue;
    final formattedRevenue = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(todayRevenue);

    // Hitung antrian aktif (yang belum selesai)
    final activeQueue = queueProvider.currentQueue.where((q) => 
      ['Menunggu', 'Confirmed', 'Sedang Dilayani'].contains(q.statusAntrian)
    ).toList();
    
    final waitingCount = activeQueue.where((q) => q.statusAntrian == 'Menunggu').length;

    return Row(
      children: [
        // Today's Revenue
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money_outlined,
            title: "Pemasukan Hari Ini",
            value: formattedRevenue,
            color: AppColors.success,
            trend: "Real-time",
          ),
        ),
        const SizedBox(width: 16),
        // Queue Count
        Expanded(
          child: _buildStatCard(
            icon: Icons.people_outline,
            title: "Antrian Aktif",
            value: "${activeQueue.length}",
            color: AppColors.cyan,
            trend: "$waitingCount menunggu",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? trend,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              if (trend != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    final List<Map<String, dynamic>> quickActions = [
      {
        'icon': Icons.content_cut,
        'label': 'Kelola Layanan',
        'color': AppColors.cyan,
        'screen': const ManageServiceScreen(),
      },
      {
        'icon': Icons.person_search,
        'label': 'Kelola Kapster',
        'color': AppColors.gold,
        'screen': const ManageBarberScreen(),
      },
      {
        'icon': Icons.analytics,
        'label': 'Laporan',
        'color': AppColors.success,
        'screen': const FinancialReportScreen(),
      },
      {
        'icon': Icons.schedule_outlined,
        'label': 'Jadwal',
        'color': AppColors.info,
        'screen': const ShopSettingsScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: quickActions.length,
      itemBuilder: (context, index) {
        final action = quickActions[index];
        return GestureDetector(
          onTap: () {
            if (action['screen'] is Widget) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => action['screen'] as Widget),
              );
            }
          },
          child: Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: action['color'].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    action['icon'],
                    size: 28,
                    color: action['color'],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  action['label'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final queueProvider = Provider.of<QueueProvider>(context);

    // 1. Ambil Data Pembayaran (Max 5)
    final paymentActivities = bookingProvider.pembayaranList.take(5).map((p) {
      final isCOD = p.metode.contains('Ditempat') || p.metode.contains('Cash');
      return {
        'icon': isCOD ? Icons.money : Icons.payment_outlined,
        'title': isCOD ? 'Pesanan COD' : 'Pembayaran Baru',
        'subtitle': 'Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(p.jumlahBayar)} - ${p.status}',
        'time': p.createdAt,
        'color': isCOD ? AppColors.info : AppColors.success,
      };
    }).toList();

    // 2. Ambil Data Antrian Hari Ini (Max 5)
    final queueActivities = queueProvider.currentQueue.take(5).map((q) {
      return {
        'icon': Icons.person_add_outlined,
        'title': 'Antrian Baru',
        'subtitle': '${q.namaPemesan} - ${q.waktuMulai}',
        'time': q.waktuBooking,
        'color': AppColors.cyan,
      };
    }).toList();

    // 3. Gabung & Urutkan berdasarkan Waktu (Terbaru diatas)
    final List<Map<String, dynamic>> combinedActivities = [...paymentActivities, ...queueActivities];
    combinedActivities.sort((a, b) {
      DateTime timeA = a['time'] as DateTime;
      DateTime timeB = b['time'] as DateTime;
      return timeB.compareTo(timeA);
    });

    // 4. Ambil 5 Teratas
    final recentActivities = combinedActivities.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Aktivitas Terbaru",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            // TextButton(
            //   onPressed: () {},
            //   child: Text(
            //     "Lihat Semua",
            //     style: TextStyle(
            //       color: AppColors.cyan,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            // ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentActivities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Belum ada aktivitas hari ini",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...recentActivities.map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (activity['color'] as Color).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'] as String,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                Text(
                  activity['subtitle'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            _getTimeAgo(activity['time'] as DateTime),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 0) {
      return "${difference.inDays} hari lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit lalu";
    } else {
      return "Baru saja";
    }
  }

  // Bottom Navigation Bar
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
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.queue_outlined),
          activeIcon: Icon(Icons.queue),
          label: 'Antrian',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.verified_outlined),
          activeIcon: Icon(Icons.verified),
          label: 'Validasi',
        ),
      ],
    );
  }

  // Quick Actions FAB
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16, right: 8), // Sesuaikan margin agar pas di pojok kanan bawah
      child: FloatingActionButton(
        onPressed: () {
          _showQuickActionsMenu(context);
        },
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  // Show Quick Actions Menu
  void _showQuickActionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
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
                  "Tindakan Cepat",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _quickActionButton(
                      icon: Icons.add_circle_outline,
                      label: "Tambah Layanan",
                      color: AppColors.cyan,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageServiceScreen(),
                          ),
                        );
                      },
                    ),
                    _quickActionButton(
                      icon: Icons.person_add_outlined,
                      label: "Tambah Kapster",
                      color: AppColors.gold,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ManageBarberScreen(),
                          ),
                        );
                      },
                    ),
                    _quickActionButton(
                      icon: Icons.receipt_outlined,
                      label: "Buat Laporan",
                      color: AppColors.success,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FinancialReportScreen(),
                          ),
                        );
                      },
                    ),
                    _quickActionButton(
                      icon: Icons.notifications_active_outlined,
                      label: "Broadcast",
                      color: AppColors.info,
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement broadcast feature
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Tutup"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 2),
            ),
            child: IconButton(
              onPressed: onTap,
              icon: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Show Notifications
  void _showNotifications(BuildContext context, List<PembayaranModel> pendingPayments, List<ReservasiModel> newQueues) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                      "Notifikasi (${pendingPayments.length + newQueues.length})",
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    if (pendingPayments.isEmpty && newQueues.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(child: Text("Tidak ada notifikasi baru")),
                      ),
                    
                    // Render Pending Payments
                    ...pendingPayments.map((p) {
                      final isCOD = p.metode.contains('Ditempat') || p.metode.contains('Cash');
                      return _notificationItem(
                        icon: isCOD ? Icons.money : Icons.payment_outlined,
                        title: isCOD ? "Pesanan Baru (COD)" : "Pembayaran Baru",
                        subtitle: isCOD 
                            ? "${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(p.jumlahBayar)} - Bayar Ditempat"
                            : "Pembayaran ${NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(p.jumlahBayar)} menunggu validasi",
                        time: DateFormat('HH:mm').format(p.createdAt),
                        isUnread: true,
                      );
                    }),

                    // Render New Queues
                    ...newQueues.map((q) => _notificationItem(
                      icon: Icons.people_outline,
                      title: "Antrian Baru",
                      subtitle: "${q.namaPemesan} memesan untuk ${q.waktuMulai}",
                      time: "Baru saja", // Or use q.waktuBooking if available
                      isUnread: true,
                    )),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // Logic to mark all as read or just clear
                    // Since it's realtime, we can't just "clear" them without processing data.
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Tutup"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _notificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread
            ? AppColors.cyan.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? AppColors.cyan.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withOpacity(0.6),
                ),
              ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.cyan,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Show Security Settings
  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Keamanan Akun",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person_outline, color: AppColors.primaryDark),
                title: const Text("Ubah Nama Pengguna"),
                onTap: () {
                  // TODO: Implement change username
                },
              ),
              ListTile(
                leading: Icon(Icons.lock_outline, color: AppColors.primaryDark),
                title: const Text("Ubah Password"),
                onTap: () {
                  // TODO: Implement change password
                },
              ),
              ListTile(
                leading: Icon(Icons.email_outlined, color: AppColors.primaryDark),
                title: const Text("Ubah Email"),
                onTap: () {
                  // TODO: Implement change email
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
    );
  }
}