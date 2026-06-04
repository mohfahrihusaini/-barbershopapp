class PembayaranModel {
  final String id;
  final String idReservasi;
  final int jumlahBayar;
  final String buktiBayarUrl;
  final String status;
  final String metode;
  final DateTime createdAt;

  PembayaranModel({
    required this.id,
    required this.idReservasi,
    required this.jumlahBayar,
    required this.buktiBayarUrl,
    required this.status,
    required this.metode,
    required this.createdAt,
  });

  factory PembayaranModel.fromJson(Map<String, dynamic> json) {
    return PembayaranModel(
      id: json['\$id'] ?? '',
      idReservasi: json['id_reservasi'] ?? '',
      jumlahBayar: json['jumlah_bayar'] ?? 0,
      buktiBayarUrl: json['bukti_bayar'] ?? '',
      status: json['status_verifikasi'] ?? 'Pending',
      metode: json['metode_pembayaran'] ?? '',
      createdAt: json['\$createdAt'] != null 
          ? DateTime.parse(json['\$createdAt']) 
          : DateTime.now(),
    );
  }
}