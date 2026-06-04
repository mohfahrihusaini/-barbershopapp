import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- IMPORT PROVIDERS ---
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/queue_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/shop_provider.dart';

// --- IMPORT SCREENS ---
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/client/home_screen.dart';
import 'presentation/screens/admin/admin_dashboard_screen.dart';

void main() async {
  // Memastikan binding Flutter siap sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal untuk Lokale Indonesia
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider digunakan agar kita bisa menggunakan banyak Provider sekaligus
    return MultiProvider(
      providers: [
        // 1. Provider untuk Autentikasi (Login/Register/Logout)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // 2. Provider untuk Booking (Layanan, Barber, Transaksi, History)
        ChangeNotifierProvider(create: (_) => BookingProvider()),

        // 3. Provider untuk Antrian (Admin)
        ChangeNotifierProvider(create: (_) => QueueProvider()),
        
        // 4. Provider untuk Chat (Realtime)
        ChangeNotifierProvider(create: (_) => ChatProvider()),

        // 5. Provider untuk Status Toko
        ChangeNotifierProvider(create: (_) => ShopProvider()),
      ],
      child: MaterialApp(
        // Menghilangkan banner "DEBUG" di pojok kanan atas
        debugShowCheckedModeBanner: false,
        
        // Judul Aplikasi
        title: 'Kece Barbershop',
        
        // Tema Aplikasi (Warna Dominan: Biru)
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true, // Menggunakan desain Material 3 (Modern)
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white, // Warna teks AppBar putih
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Halaman Pertama yang dibuka adalah Wrapper untuk cek sesi
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Cek sesi saat aplikasi dibuka
    Future.microtask(() =>
        Provider.of<AuthProvider>(context, listen: false).checkSession());
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // 1. Tampilkan Loading saat cek sesi
    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 2. Jika sudah login, arahkan berdasarkan role
    if (authProvider.isLoggedIn) {
      final user = authProvider.currentUser;
      if (user?.role == 'admin') {
        return const AdminDashboardScreen();
      }
      return const HomeScreen();
    }

    // 3. Jika belum login, tampilkan Login Screen
    return const LoginScreen();
  }
}