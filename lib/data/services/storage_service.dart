import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart'; // PENTING: Untuk cek kIsWeb
import '../../config/app_constants.dart';
import 'appwrite_client.dart';

class StorageService {
  final AppwriteClient _appwrite = AppwriteClient();

  // 1. FUNGSI MEMILIH FILE
  Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    return result?.files.first;
  }

  // 2. FUNGSI UPLOAD FILE (REVISI: Support Web & Mobile)
  Future<String> uploadBuktiBayar(PlatformFile file) async {
    try {
      InputFile inputFile;

      // CEK: Apakah sedang berjalan di Web?
      if (kIsWeb) {
        // JIKA WEB: Gunakan 'bytes' (karena path tidak tersedia)
        inputFile = InputFile.fromBytes(
          bytes: file.bytes!, 
          filename: file.name,
        );
      } else {
        // JIKA MOBILE (Android/iOS): Gunakan 'path'
        inputFile = InputFile.fromPath(
          path: file.path!,
          filename: file.name,
        );
      }

      final result = await _appwrite.storage.createFile(
        bucketId: AppConstants.bucketBuktiBayar,
        fileId: ID.unique(),
        file: inputFile,
      );
      
      return result.$id; 
    } catch (e) {
      throw Exception("Gagal upload gambar: $e");
    }
  }

  // 3. GET URL VIEW
  String getFileViewUrl(String fileId) {
    return "${AppConstants.endpoint}/storage/buckets/${AppConstants.bucketBuktiBayar}/files/$fileId/view?project=${AppConstants.projectId}";
  }
}