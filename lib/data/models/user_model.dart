class UserModel {
  final String id;
  final String nama;
  final String email;
  final String telepon;
  final String role; // 'admin' atau 'pelanggan'

  UserModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.telepon,
    required this.role,
  });

  // Mengubah JSON dari Appwrite menjadi Object Dart
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id, // ID diambil dari $id dokumen Appwrite
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      telepon: json['telepon'] ?? '',
      role: json['role'] ?? 'pelanggan',
    );
  }

  // Mengubah Object Dart menjadi JSON untuk dikirim ke Appwrite
  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'email': email,
      'telepon': telepon,
      'role': role,
    };
  }
}