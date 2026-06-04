import 'package:flutter/material.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Reservasi Diterima',
        'message': 'Reservasi Anda untuk hari ini jam 14:00 telah dikonfirmasi',
        'time': '10 menit lalu',
        'isRead': false,
      },
      {
        'title': 'Promo Spesial',
        'message': 'Diskon 20% untuk potong rambut hari ini',
        'time': '1 jam lalu',
        'isRead': false,
      },
      {
        'title': 'Barbershop Tutup',
        'message': 'Barbershop tutup pada tanggal 25 Desember 2024',
        'time': '2 hari lalu',
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifikasi"),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification['isRead'] == false
                  ? AppColors.cyan.withOpacity(0.1)
                  : Colors.white,
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
                    color: AppColors.cyan.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'] as String,
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
                      notification['time'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withOpacity(0.6),
                      ),
                    ),
                    if (notification['isRead'] == false)
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
        },
      ),
    );
  }
}