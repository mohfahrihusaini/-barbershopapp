import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:barbershopapp/providers/booking_provider.dart';
import 'package:barbershopapp/data/models/layanan_model.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class ManageServiceScreen extends StatefulWidget {
  const ManageServiceScreen({super.key});

  @override
  State<ManageServiceScreen> createState() => _ManageServiceScreenState();
}

class _ManageServiceScreenState extends State<ManageServiceScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<BookingProvider>(context, listen: false).loadInitialData());
  }

  void _showFormDialog({LayananModel? layanan}) {
    final nameController = TextEditingController(text: layanan?.namaLayanan ?? '');
    final priceController = TextEditingController(text: layanan?.harga.toString() ?? '');
    final durationController = TextEditingController(text: layanan?.durasiMenit.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          layanan == null ? "Tambah Layanan" : "Edit Layanan",
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
                  labelText: "Nama Layanan",
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
                controller: priceController,
                decoration: InputDecoration(
                  labelText: "Harga (Rp)",
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
                  prefixText: "Rp ",
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: "Durasi (Menit)",
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
                suffixText: "menit",
              ),
              keyboardType: TextInputType.number,
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
              if (nameController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  durationController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Harap isi semua field"),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              final provider = Provider.of<BookingProvider>(context, listen: false);
              
              try {
                if (layanan == null) {
                  // TAMBAH BARU
                  await provider.addLayanan(
                    nameController.text,
                    int.parse(priceController.text),
                    int.parse(durationController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${nameController.text} berhasil ditambahkan"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                } else {
                  // EDIT
                  await provider.updateLayanan(
                    layanan.id,
                    nameController.text,
                    int.parse(priceController.text),
                    int.parse(durationController.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${nameController.text} berhasil diperbarui"),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Gagal: $e"),
                    backgroundColor: AppColors.error,
                  ),
                );
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
            Icons.content_cut_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            "Belum Ada Layanan",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tambahkan layanan pertama Anda",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showFormDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 20, color: Colors.white),
            label: const Text(
              "Tambah Layanan",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(int price) {
    return "Rp ${price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        )}";
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelola Layanan"),
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
          : provider.layananList.isEmpty
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
                                  "Total Layanan",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${provider.layananList.length}",
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
                                color: AppColors.cyan.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.content_cut_outlined,
                                size: 32,
                                color: AppColors.cyan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Revenue Stats
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDark.withOpacity(0.8),
                              AppColors.primaryDark.withOpacity(0.6),
                            ],
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
                                  "Total Nilai Layanan",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrice(provider.layananList.fold(
                                    0,
                                    (sum, item) => sum + item.harga,
                                  )),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.attach_money_outlined,
                              size: 40,
                              color: AppColors.gold,
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
                            "Daftar Layanan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          Text(
                            "Rata-rata ${(provider.layananList.fold(0, (sum, item) => sum + item.durasiMenit) / provider.layananList.length).toStringAsFixed(0)} menit",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.cyan,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Layanan List
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.layananList.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = provider.layananList[index];
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
                                  color: AppColors.cyan.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.cyan.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.content_cut_outlined,
                                    color: AppColors.cyan,
                                    size: 24,
                                  ),
                                ),
                              ),
                              title: Text(
                                item.namaLayanan,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatPrice(item.harga),
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule_outlined,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "${item.durasiMenit} menit",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        size: 20,
                                        color: AppColors.gold,
                                      ),
                                      onPressed: () => _showFormDialog(layanan: item),
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
                                      onPressed: () async {
                                        final confirm = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            title: Text(
                                              "Hapus Layanan",
                                              style: TextStyle(
                                                color: AppColors.primaryDark,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            content: Text(
                                              "Apakah Anda yakin ingin menghapus ${item.namaLayanan}?",
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
                                                onPressed: () async {
                                                  try {
                                                    await provider.deleteLayanan(item.id);
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "${item.namaLayanan} berhasil dihapus",
                                                        ),
                                                        backgroundColor: AppColors.success,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text("Gagal menghapus: $e"),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                  }
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
          onPressed: () => _showFormDialog(),
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 4,
          child: const Icon(Icons.add, size: 24),
        ),
      ),
    );
  }
}