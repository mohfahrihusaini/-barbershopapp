import 'dart:io';
import 'package:flutter/foundation.dart'; // Untuk kIsWeb
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/booking_provider.dart';
import 'home_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String idReservasi;
  final int totalBayar;
  final String namaLayanan;

  const PaymentScreen({
    super.key,
    required this.idReservasi,
    required this.totalBayar,
    required this.namaLayanan,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PlatformFile? _selectedImage;
  String _paymentMethod = 'Bayar Ditempat'; // Default
  String _selectedBank = 'BCA';

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, 
    );

    if (result != null) {
      setState(() {
        _selectedImage = result.files.first;
      });
    }
  }

  void _submitPayment() async {
    // Validasi untuk QRIS wajib upload
    if (_paymentMethod == 'QRIS' && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon upload bukti transfer untuk pembayaran QRIS!")),
      );
      return;
    }

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
      String metodeFinal = _paymentMethod;
      if (_paymentMethod == 'QRIS') {
        metodeFinal = "QRIS - $_selectedBank";
      }

      await bookingProvider.submitPembayaran(
        idReservasi: widget.idReservasi,
        jumlahBayar: widget.totalBayar,
        fileGambar: _selectedImage, // Bisa null jika Bayar Ditempat
        metode: metodeFinal,
      );

      if (mounted) {
        String message = _paymentMethod == 'QRIS' 
            ? "Terima kasih. Admin akan memverifikasi bukti pembayaran Anda."
            : "Terima kasih. Silakan lakukan pembayaran saat tiba di lokasi.";

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text("Pesanan Dikonfirmasi!"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memproses: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<BookingProvider>(context).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Pembayaran")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. INFO TAGIHAN
            Card(
              elevation: 0,
              color: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text("Total Tagihan", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 5),
                    Text(
                      "Rp ${widget.totalBayar}", 
                      style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Layanan:"),
                        Text(widget.namaLayanan, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 25),

            // 2. PILIH METODE PEMBAYARAN
            const Text("Pilih Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            
            _buildPaymentMethodOption(
              value: 'Bayar Ditempat',
              title: "Bayar Ditempat (Cash)",
              subtitle: "Bayar langsung di kasir barbershop",
              icon: Icons.storefront,
            ),
            const SizedBox(height: 10),
            _buildPaymentMethodOption(
              value: 'QRIS',
              title: "QRIS / Transfer",
              subtitle: "Scan QR atau transfer bank",
              icon: Icons.qr_code_2,
            ),

            const SizedBox(height: 25),

            // 3. KONTEN BERDASARKAN PILIHAN
            if (_paymentMethod == 'QRIS') ...[
              const Text("Scan QRIS atau Transfer:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Placeholder QR Code
                    Container(
                      height: 200,
                      width: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_scanner, size: 80, color: Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("NAMA MERCHANT: BARBERSHOP APP", style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text("NMID: ID1234567890", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const Divider(height: 24),
                    // Dropdown Bank
                    DropdownButtonFormField<String>(
                      value: _selectedBank,
                      decoration: const InputDecoration(
                        labelText: "Atau Transfer Bank",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['BCA', 'BRI', 'Mandiri'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedBank = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // Upload Bukti
              const Text("Upload Bukti Pembayaran", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(
                      color: _selectedImage != null ? Colors.green : Colors.grey[400]!,
                      style: BorderStyle.solid,
                      width: _selectedImage != null ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text("Ketuk untuk upload bukti", style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb 
                              ? Image.memory(
                                  _selectedImage!.bytes!, 
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_selectedImage!.path!), 
                                  fit: BoxFit.cover,
                                ),
                        ),
                ),
              ),
            ] else ...[
              // Info Bayar Ditempat
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pastikan Anda datang tepat waktu. Pembayaran dilakukan di kasir setelah layanan selesai.",
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // 4. TOMBOL KIRIM
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _paymentMethod == 'Bayar Ditempat' ? Colors.blue : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        _paymentMethod == 'Bayar Ditempat' 
                            ? "KONFIRMASI PESANAN" 
                            : "KIRIM BUKTI PEMBAYARAN",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == value;
    
    return InkWell(
      onTap: () => setState(() {
        _paymentMethod = value;
        _selectedImage = null; // Reset image jika ganti metode
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.blue[900] : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}