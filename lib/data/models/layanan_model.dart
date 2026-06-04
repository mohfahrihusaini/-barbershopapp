class LayananModel {
  final String id;
  final String namaLayanan;
  final int harga;
  final int durasiMenit;

  LayananModel({
    required this.id,
    required this.namaLayanan,
    required this.harga,
    required this.durasiMenit,
  });

  factory LayananModel.fromJson(Map<String, dynamic> json) {
    return LayananModel(
      id: json['\$id'] ?? '',
      namaLayanan: json['nama_layanan'] ?? '',
      harga: json['harga'] ?? 0,
      durasiMenit: json['durasi_menit'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_layanan': namaLayanan,
      'harga': harga,
      'durasi_menit': durasiMenit,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayananModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}