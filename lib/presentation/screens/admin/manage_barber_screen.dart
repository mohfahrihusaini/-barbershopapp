import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/data/models/barber_model.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class ManageBarberScreen extends StatefulWidget {
  const ManageBarberScreen({super.key});

  @override
  State<ManageBarberScreen> createState() => _ManageBarberScreenState();
}

class _ManageBarberScreenState extends State<ManageBarberScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<BookingProvider>(context, listen: false).loadInitialData());
  }

  void _showAddEditBarberDialog([BarberModel? barber]) {
    final nameController = TextEditingController(text: barber?.namaBarber ?? '');
    final specController = TextEditingController(text: barber?.spesialisasi ?? '');
    
    // VALIDASI KETAT STATUS
    const validStatuses = ['Aktif', 'Cuti', 'Nonaktif'];
    String rawStatus = barber?.status ?? 'Aktif';
    
    // Jika status dari database tidak ada di list opsi valid, paksa jadi 'Aktif'
    String status = validStatuses.contains(rawStatus) ? rawStatus : 'Aktif';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          barber == null ? "Tambah Kapster" : "Edit Kapster",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nama Kapster",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: TextField(
                controller: specController,
                decoration: InputDecoration(
                  labelText: "Spesialisasi",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              value: status,
              items: ['Aktif', 'Cuti', 'Nonaktif']
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: (val) => status = val!,
              decoration: InputDecoration(
                labelText: "Status",
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              dropdownColor: Colors.white,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Batal",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || specController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Harap isi semua field"),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              Navigator.pop(context); // Tutup dialog dulu

              try {
                if (barber == null) {
                  await Provider.of<BookingProvider>(context, listen: false)
                      .addBarber(nameController.text, specController.text, status);
                } else {
                  await Provider.of<BookingProvider>(context, listen: false)
                      .updateBarber(barber.id, nameController.text, specController.text, status);
                }
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Berhasil menyimpan data kapster")),
                  );
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              "Simpan",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum Ada Kapster",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tambahkan kapster pertama Anda",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddEditBarberDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 20, color: Colors.white),
            label: const Text(
              "Tambah Kapster",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'aktif':
        return AppColors.success;
      case 'cuti':
        return AppColors.gold;
      case 'nonaktif':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Kapster"),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: bookingProvider.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryDark,
              ),
            )
          : bookingProvider.barberList.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Stats
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.primaryDark.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Total Kapster",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${bookingProvider.barberList.length}",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 32,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // List Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Daftar Kapster",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            "${bookingProvider.barberList.where((b) => b.status == 'Aktif').length} Aktif",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Kapster List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: bookingProvider.barberList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final barber = bookingProvider.barberList[index];
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
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.gold.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.gold.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    barber.namaBarber[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                barber.namaBarber,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    barber.spesialisasi,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(barber.status)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: _getStatusColor(barber.status)
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      barber.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _getStatusColor(barber.status),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: AppColors.cyan,
                                      ),
                                      onPressed: () => _showAddEditBarberDialog(barber),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: AppColors.error,
                                      ),
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            title: Text(
                                              "Hapus Kapster",
                                              style: TextStyle(
                                                color: AppColors.primaryDark,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            content: Text(
                                              "Apakah Anda yakin ingin menghapus ${barber.namaBarber}?",
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
                                                  bookingProvider.deleteBarber(barber.id);
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        "${barber.namaBarber} berhasil dihapus",
                                                      ),
                                                      backgroundColor: AppColors.success,
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.error,
                                                ),
                                                child: const Text(
                                                  "Hapus",
                                                  style: TextStyle(color: Colors.white),
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
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 80), // Padding untuk FAB
                    ],
                  ),
                ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton(
          onPressed: () => _showAddEditBarberDialog(),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }
}