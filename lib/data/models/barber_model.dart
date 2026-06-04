class BarberModel {
  final String id;
  final String namaBarber;
  final String spesialisasi;
  final String status; // 'Tersedia' atau 'Tidak Tersedia'

  BarberModel({
    required this.id,
    required this.namaBarber,
    required this.spesialisasi,
    required this.status,
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(
      id: json['\$id'] ?? '', // Mengambil ID bawaan Appwrite
      namaBarber: json['nama_barber'] ?? '',
      spesialisasi: json['spesialisasi'] ?? '',
      status: json['status'] ?? 'Tersedia',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_barber': namaBarber,
      'spesialisasi': spesialisasi,
      'status': status,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BarberModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}