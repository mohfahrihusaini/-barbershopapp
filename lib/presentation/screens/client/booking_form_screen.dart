import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:barbershopapp/providers/auth_provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/providers/shop_provider.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';
import '../../../data/models/layanan_model.dart';
import '../../../data/models/barber_model.dart';
import '../../../data/models/reservasi_model.dart';
import 'payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final LayananModel? selectedService;
  const BookingFormScreen({super.key, this.selectedService});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class TimeSlot {
  final TimeOfDay time;
  final bool isAvailable;
  final String? bookedBy;
  final String? bookingId;
  
  TimeSlot({
    required this.time,
    required this.isAvailable,
    this.bookedBy,
    this.bookingId,
  });
  
  String get timeString => "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  LayananModel? _selectedLayanan;
  BarberModel? _selectedBarber;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<TimeSlot> _timeSlots = [];

  @override
  void initState() {
    super.initState();
    // Set selected service jika ada dari parameter
    if (widget.selectedService != null) {
      _selectedLayanan = widget.selectedService;
    }
    
    // Ambil data dan generate jam yang tersedia
    Future.microtask(() async {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      await bookingProvider.loadInitialData();
      await Provider.of<ShopProvider>(context, listen: false).loadShopStatus();
      
      // Update _selectedLayanan dengan instance dari provider list agar dropdown match
      if (_selectedLayanan != null) {
        try {
          final freshLayanan = bookingProvider.layananList.firstWhere(
            (l) => l.id == _selectedLayanan!.id,
          );
          setState(() => _selectedLayanan = freshLayanan);
        } catch (_) {
          // Layanan mungkin sudah dihapus atau tidak ditemukan
          setState(() => _selectedLayanan = null);
        }
      }
      
      _generateTimeSlots();
    });
  }

  bool _isLoadingSlots = false;

  // Fungsi untuk generate semua slot jam dengan status availability
  Future<void> _generateTimeSlots() async {
    setState(() => _isLoadingSlots = true);
    
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);
    
    List<TimeSlot> slots = [];

    // Jika tidak ada tanggal yang dipilih, return empty
    if (_selectedDate == null) {
      setState(() {
        _timeSlots = slots;
        _isLoadingSlots = false;
      });
      return;
    }

    // Jam operasional barbershop
    const int openHour = 10; // 10:00
    const int closeHour = 21; // 21:00
    const int slotDuration = 30; // durasi slot dalam menit

    // Generate semua slot jam dari openHour sampai closeHour
    List<TimeOfDay> allTimes = [];
    for (int hour = openHour; hour <= closeHour; hour++) {
      for (int minute = 0; minute < 60; minute += slotDuration) {
        allTimes.add(TimeOfDay(hour: hour, minute: minute));
      }
    }

    // Filter jam yang tidak overlap dengan waktu istirahat
    if (shopProvider.status.toLowerCase() == 'istirahat' && 
        shopProvider.breakStartTime != null && 
        shopProvider.breakEndTime != null) {
      
      final breakStart = TimeOfDay.fromDateTime(shopProvider.breakStartTime!);
      final breakEnd = TimeOfDay.fromDateTime(shopProvider.breakEndTime!);
      
      // Filter jam yang tidak overlap dengan waktu istirahat
      allTimes = allTimes.where((time) {
        final totalMinutes = time.hour * 60 + time.minute;
        final breakStartMinutes = breakStart.hour * 60 + breakStart.minute;
        final breakEndMinutes = breakEnd.hour * 60 + breakEnd.minute;
        
        // Jam tidak berada dalam rentang istirahat
        return totalMinutes < breakStartMinutes || totalMinutes >= breakEndMinutes;
      }).toList();
    }

    // Ambil booking yang sudah ada untuk filter
    List<ReservasiModel> existingBookings = [];
    if (_selectedBarber != null && _selectedLayanan != null) {
      existingBookings = await bookingProvider.getBookingsByBarberAndDate(
        _selectedBarber!.id,
        _selectedDate!,
      );
      // Filter status yang valid saja (bukan dibatalkan/ditolak)
      existingBookings = existingBookings.where((b) => 
        !['dibatalkan', 'ditolak'].contains(b.statusAntrian.toLowerCase())
      ).toList();
      
      print("Booking ditemukan untuk ${_selectedBarber!.namaBarber}: ${existingBookings.length}");
    }

    // Generate slot dengan status availability
    final DateTime now = DateTime.now();
    final bool isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;

    for (var time in allTimes) {
      bool isAvailable = true;
      String? bookedBy;
      String? bookingId;

      // Cek apakah jam sudah lewat jika memilih hari ini
      if (isToday) {
        final int nowMinutes = now.hour * 60 + now.minute;
        final int slotMinutes = time.hour * 60 + time.minute;
        
        if (slotMinutes <= nowMinutes) {
          isAvailable = false;
        }
      }

      // Jika masih available setelah cek waktu sekarang, cek overlap dengan booking lain
      if (isAvailable) {
        for (var booking in existingBookings) {
          final bookingTime = TimeOfDay.fromDateTime(booking.tanggal);
          
          final layananBooking = bookingProvider.layananList.firstWhere(
            (l) => l.id == booking.idLayanan,
            orElse: () => LayananModel(id: '', namaLayanan: '', harga: 0, durasiMenit: 30),
          );
          final bookingDuration = layananBooking.durasiMenit;
          final layananDuration = _selectedLayanan?.durasiMenit ?? 30;
          
          final bookingStartMinutes = bookingTime.hour * 60 + bookingTime.minute;
          final bookingEndMinutes = bookingStartMinutes + bookingDuration;
          final slotStartMinutes = time.hour * 60 + time.minute;
          final slotEndMinutes = slotStartMinutes + layananDuration;

          if (slotStartMinutes < bookingEndMinutes && slotEndMinutes > bookingStartMinutes) {
            isAvailable = false;
            bookedBy = booking.namaPemesan;
            bookingId = booking.id;
            break;
          }
        }
      }

      slots.add(TimeSlot(
        time: time,
        isAvailable: isAvailable,
        bookedBy: bookedBy,
        bookingId: bookingId,
      ));
    }

    setState(() {
      _timeSlots = slots;
      _isLoadingSlots = false;
    });
  }

  // Fungsi untuk memilih tanggal
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
      });
      _generateTimeSlots();
    }
  }

  // Widget untuk menampilkan slot jam dalam grid
  Widget _buildTimeSelector() {
    if (_isLoadingSlots) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Mengecek jadwal kapster..."),
            ],
          ),
        ),
      );
    }

    if (_selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              "Pilih tanggal terlebih dahulu",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_timeSlots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 48,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            Text(
              "Tidak ada jam tersedia",
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan pilih tanggal lain atau kapster berbeda",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info durasi layanan
        if (_selectedLayanan != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Durasi layanan: ${_selectedLayanan!.durasiMenit} menit",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Grid slot jam
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.8,
          ),
          itemCount: _timeSlots.length,
          itemBuilder: (context, index) {
            return _buildTimeSlotCard(_timeSlots[index]);
          },
        ),
        
        const SizedBox(height: 20),
        
        // Legenda
        _buildLegend(),
      ],
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final isSelected = _selectedTime == slot.time;
    
    return Tooltip(
      message: !slot.isAvailable 
          ? "Sudah dipesan${slot.bookedBy != null ? ' oleh ${slot.bookedBy}' : ''}"
          : "Klik untuk memilih",
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: slot.isAvailable
            ? () => setState(() => _selectedTime = slot.time)
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryDark
                : slot.isAvailable
                    ? Colors.white
                    : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryDark
                  : (!slot.isAvailable
                      ? Colors.grey[300]!
                      : AppColors.cyan.withOpacity(0.3)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryDark.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                slot.timeString,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: !slot.isAvailable
                      ? Colors.grey[400]
                      : (isSelected ? Colors.white : AppColors.primaryDark),
                ),
              ),
              if (!slot.isAvailable) ...[
                const SizedBox(height: 2),
                Icon(
                  Icons.lock_clock,
                  size: 12,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Legenda:",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.white, "Tersedia"),
              _buildLegendItem(Colors.grey[100]!, "Sudah dipesan"),
              _buildLegendItem(AppColors.primaryDark, "Dipilih"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: color == Colors.white 
                  ? AppColors.cyan.withOpacity(0.3) 
                  : (color == AppColors.primaryDark 
                      ? AppColors.primaryDark 
                      : Colors.grey[300]!),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // Fungsi Submit Booking
  void _submitBooking() async {
    // Validasi Input
    if (_selectedLayanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon pilih layanan!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedBarber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon pilih kapster!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon pilih tanggal!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon pilih jam!"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Cek apakah jam yang dipilih tersedia
    final selectedSlot = _timeSlots.firstWhere(
      (slot) => slot.time == _selectedTime,
      orElse: () => TimeSlot(time: _selectedTime!, isAvailable: false),
    );

    if (!selectedSlot.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Jam ${selectedSlot.timeString} sudah tidak tersedia"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final shopProvider = Provider.of<ShopProvider>(context, listen: false);

    // Cek apakah barbershop sedang tutup
    if (shopProvider.status.toLowerCase() == 'tutup') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Maaf, barbershop sedang tutup"),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Cek apakah sedang istirahat
    if (shopProvider.status.toLowerCase() == 'istirahat') {
      final slotTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      
      if (shopProvider.breakStartTime != null && 
          shopProvider.breakEndTime != null &&
          slotTime.isAfter(shopProvider.breakStartTime!) &&
          slotTime.isBefore(shopProvider.breakEndTime!)) {
        
        final endTime = DateFormat('HH:mm').format(shopProvider.breakEndTime!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Maaf, barbershop sedang istirahat sampai $endTime"),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    // Gabungkan Tanggal & Waktu
    final bookingDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Format jam
    final jamString = "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

    // PINDAH KE HALAMAN PEMBAYARAN (Tanpa Simpan DB dulu)
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            bookingData: {
              'idUser': user!.id,
              'namaPemesan': user.nama,
              'tanggal': bookingDateTime,
              'waktuMulai': jamString,
              'idBarber': _selectedBarber!.id,
              'idLayanan': _selectedLayanan!.id,
              'namaLayanan': _selectedLayanan!.namaLayanan,
              'harga': _selectedLayanan!.harga,
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);
    final shopProvider = Provider.of<ShopProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Reservasi"),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: provider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryDark,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Status Barbershop
                  if (shopProvider.status.toLowerCase() == 'istirahat' && 
                      shopProvider.breakEndTime != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.coffee_outlined,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Barbershop istirahat sampai ${DateFormat('HH:mm').format(shopProvider.breakEndTime!)}",
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // 1. PILIH LAYANAN
                  Text(
                    "Pilih Layanan",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<LayananModel>(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        isExpanded: true,
                        hint: Text(
                          "Pilih Service...",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: _selectedLayanan,
                        items: provider.layananList.map((layanan) {
                          return DropdownMenuItem(
                            value: layanan,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  layanan.namaLayanan,
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  "Rp ${NumberFormat('#,##0', 'id_ID').format(layanan.harga)} • ${layanan.durasiMenit} menit",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedLayanan = val;
                            _selectedTime = null;
                          });
                          _generateTimeSlots();
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // 2. PILIH BARBER
                  Text(
                    "Pilih Kapster",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BarberModel>(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        isExpanded: true,
                        hint: Text(
                          "Pilih Barber...",
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        value: _selectedBarber,
                        items: provider.barberList
                            .where((barber) => ['aktif', 'tersedia'].contains(barber.status.toLowerCase()))
                            .map((barber) {
                          return DropdownMenuItem(
                            value: barber,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  barber.namaBarber,
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  barber.spesialisasi,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedBarber = val;
                            _selectedTime = null;
                          });
                          _generateTimeSlots();
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. PILIH TANGGAL
                  Text(
                    "Pilih Tanggal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.primaryDark,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null 
                                ? "Pilih Tanggal" 
                                : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate!),
                              style: TextStyle(
                                color: _selectedDate == null 
                                  ? AppColors.textSecondary 
                                  : AppColors.primaryDark,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. PILIH JAM (slot yang tersedia)
                  Text(
                    "Pilih Jam",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildTimeSelector(),

                  const SizedBox(height: 32),

                  // Info tambahan sistem
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 18,
                              color: AppColors.cyan,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Sistem Jam Otomatis",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "• Slot jam otomatis menyesuaikan dengan jadwal kapster\n"
                          "• Slot yang sudah dipesan akan terkunci (berwarna abu-abu)\n"
                          "• Sistem mencegah tabrakan jadwal antar pelanggan\n"
                          "• Pemesanan diproses dengan sistem antrian FIFO",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TOMBOL SUBMIT
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "BOOKING SEKARANG",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}