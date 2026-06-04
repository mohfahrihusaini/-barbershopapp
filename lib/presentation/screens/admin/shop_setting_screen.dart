import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbershopapp/providers/shop_provider.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class ShopSettingsScreen extends StatefulWidget {
  final Function(bool)? onShopStatusChanged;
  
  const ShopSettingsScreen({super.key, this.onShopStatusChanged});

  @override
  State<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends State<ShopSettingsScreen> {
  // Local state initialized with default, will be overwritten by provider
  bool _shopOpen = true;
  TimeOfDay _openTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 21, minute: 0);
  List<String> _offDays = ['Senin'];
  String _notificationMessage = "Kece Barbershop sedang tutup. Reservasi dapat dilakukan untuk hari berikutnya.";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load current status from provider
    Future.microtask(() async {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      await shopProvider.loadShopStatus();
      if (mounted) {
        setState(() {
          _shopOpen = shopProvider.status.toLowerCase() == 'buka';
        });
      }
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final shopProvider = Provider.of<ShopProvider>(context, listen: false);
      
      // Update status to Appwrite
      await shopProvider.updateShopStatus(
        status: _shopOpen ? 'buka' : 'tutup',
        // Note: openTime, closeTime, offDays, notificationMessage belum disimpan ke DB
        // karena butuh field tambahan. Sementara fokus ke status Buka/Tutup.
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Pengaturan toko berhasil disimpan"),
            backgroundColor: AppColors.success,
          ),
        );
        
        // Notify parent
        widget.onShopStatusChanged?.call(_shopOpen);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan: $e"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: const Text("Pengaturan Toko"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            onPressed: _isLoading ? null : _saveSettings,
            tooltip: "Simpan Pengaturan",
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildShopStatusCard(),
                const SizedBox(height: 24),
                _buildOperatingHours(),
                const SizedBox(height: 24),
                _buildOffDays(),
                const SizedBox(height: 24),
                _buildNotificationSettings(),
                const SizedBox(height: 24),
                _buildAdvancedSettings(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
    );
  }

  Widget _buildShopStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _shopOpen
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _shopOpen ? AppColors.success : AppColors.error,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _shopOpen ? Icons.storefront : Icons.storefront_outlined,
                size: 40,
                color: _shopOpen ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shopOpen ? "TOKO SEDANG BUKA" : "TOKO SEDANG TUTUP",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _shopOpen ? AppColors.success : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _shopOpen
                          ? "Pelanggan dapat melakukan reservasi online"
                          : "Reservasi online dinonaktifkan untuk sementara",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              _shopOpen ? "Buka Toko" : "Tutup Toko",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            subtitle: Text(
              _shopOpen
                  ? "Nonaktifkan untuk menutup toko sementara"
                  : "Aktifkan untuk membuka toko",
            ),
            value: _shopOpen,
            onChanged: (value) {
              setState(() => _shopOpen = value);
              widget.onShopStatusChanged?.call(value);
            },
            activeColor: AppColors.success,
            inactiveThumbColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHours() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Jam Operasional",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Buka Pukul",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectOpenTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.mediumGray),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimeOfDay(_openTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                            Icon(
                              Icons.access_time,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tutup Pukul",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectCloseTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.mediumGray),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimeOfDay(_closeTime),
                              style: const TextStyle(fontSize: 16),
                            ),
                            Icon(
                              Icons.access_time,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Durasi Operasional: ${_calculateDuration()} jam",
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffDays() {
    final List<String> days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hari Libur Tetap",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Pilih hari dimana toko tetap tutup setiap minggunya",
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              bool isSelected = _offDays.contains(day);
              return ChoiceChip(
                label: Text(day),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _offDays.add(day);
                    } else {
                      _offDays.remove(day);
                    }
                  });
                },
                selectedColor: AppColors.primaryDark,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
                backgroundColor: AppColors.backgroundLight,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.primaryDark),
              const SizedBox(width: 8),
              Text(
                "Notifikasi Toko Tutup",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Pesan yang akan ditampilkan ketika toko tutup:",
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: _notificationMessage),
            maxLines: 3,
            onChanged: (value) => _notificationMessage = value,
            decoration: InputDecoration(
              hintText: "Masukkan pesan notifikasi...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.cyan),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                "Pesan ini akan muncul di aplikasi pelanggan",
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pengaturan Lanjutan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text("Auto-Close ketika libur"),
            subtitle: const Text("Otomatis tutup toko di hari libur tetap"),
            value: true,
            onChanged: (value) {},
            activeColor: AppColors.primaryDark,
          ),
          SwitchListTile(
            title: const Text("Notifikasi ke Admin"),
            subtitle: const Text("Kirim notifikasi ketika ada perubahan status"),
            value: true,
            onChanged: (value) {},
            activeColor: AppColors.primaryDark,
          ),
          SwitchListTile(
            title: const Text("Izinkan Reservasi Mendadak"),
            subtitle: const Text("Pelanggan bisa reservasi meski toko akan tutup"),
            value: false,
            onChanged: (value) {},
            activeColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Text(
                "SIMPAN PENGATURAN",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  // Helper methods
  Future<void> _selectOpenTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _openTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _openTime = picked);
    }
  }

  Future<void> _selectCloseTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _closeTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _closeTime = picked);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _calculateDuration() {
    final openMinutes = _openTime.hour * 60 + _openTime.minute;
    final closeMinutes = _closeTime.hour * 60 + _closeTime.minute;
    final durationMinutes = closeMinutes - openMinutes;
    final hours = durationMinutes ~/ 60;
    return hours.toString();
  }
}