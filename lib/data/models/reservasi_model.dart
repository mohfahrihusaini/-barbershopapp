import 'package:flutter/material.dart';
import 'package:barbershopapp/presentation/theme/app_colors.dart';

class ReservasiModel {
  final String id;
  final DateTime tanggal; // Untuk sorting FIFO
  final String waktuMulai; // Untuk sorting FIFO
  final String statusAntrian; // 'Menunggu', 'Sedang Dilayani', 'Selesai'
  final String idUser;
  final String idBarber;
  final String idLayanan;
  final String namaPemesan; // Tambahan untuk kemudahan display
  
  // Property baru untuk sistem antrian
  final int nomorAntrian;
  final DateTime waktuBooking;
  final DateTime? estimasiWaktuSelesai;

  ReservasiModel({
    required this.id,
    required this.tanggal,
    required this.waktuMulai,
    required this.statusAntrian,
    required this.idUser,
    required this.idBarber,
    required this.idLayanan,
    required this.namaPemesan,
    required this.nomorAntrian,
    required this.waktuBooking,
    this.estimasiWaktuSelesai,
  });

  factory ReservasiModel.fromJson(Map<String, dynamic> json) {
    return ReservasiModel(
      id: json['\$id'] ?? '',
      // Konversi string ISO8601 ke DateTime
      tanggal: DateTime.parse(json['tanggal']),
      waktuMulai: json['waktu_mulai'] ?? '',
      statusAntrian: json['status_antrian'] ?? 'Menunggu',
      idUser: json['id_user'] ?? '',
      idBarber: json['id_barber'] ?? '',
      idLayanan: json['id_layanan'] ?? '',
      namaPemesan: json['nama_pemesan'] ?? '',
      nomorAntrian: json['nomor_antrian'] ?? 0,
      waktuBooking: json['waktu_booking'] != null 
          ? DateTime.parse(json['waktu_booking']) 
          : DateTime.now(),
      estimasiWaktuSelesai: json['estimasi_waktu_selesai'] != null 
          ? DateTime.parse(json['estimasi_waktu_selesai']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tanggal': tanggal.toIso8601String(),
      'waktu_mulai': waktuMulai,
      'status_antrian': statusAntrian,
      'id_user': idUser,
      'id_barber': idBarber,
      'id_layanan': idLayanan,
      'nama_pemesan': namaPemesan,
      'nomor_antrian': nomorAntrian,
      'waktu_booking': waktuBooking.toIso8601String(),
      'estimasi_waktu_selesai': estimasiWaktuSelesai?.toIso8601String(),
    };
  }

  Color getStatusColor() {
    switch (statusAntrian) {
      case 'Menunggu':
        return AppColors.waiting;
      case 'Sedang Dilayani':
        return AppColors.inProgress;
      case 'Selesai':
        return AppColors.completed;
      default:
        return Colors.grey;
    }
  }

  // Helper untuk mendapatkan waktu mulai lengkap (Tanggal + Jam)
  DateTime get startDateTime {
    try {
      final parts = waktuMulai.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(tanggal.year, tanggal.month, tanggal.day, hour, minute);
    } catch (e) {
      return tanggal; // Fallback jika format jam salah
    }
  }
}