import 'package:appwrite/appwrite.dart';
import '../../config/app_constants.dart';

class AppwriteClient {
  static final AppwriteClient _instance = AppwriteClient._internal();
  
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;
  late Realtime realtime;

  factory AppwriteClient() {
    return _instance;
  }

  AppwriteClient._internal() {
    client = Client();
    _init();
  }

  void _init() {
    // 1. Inisialisasi Client
    client
        .setEndpoint(AppConstants.endpoint)
        .setProject(AppConstants.projectId)
        .setSelfSigned(status: true); 

    // 2. Inisialisasi Service
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);
    realtime = Realtime(client);
  }
}