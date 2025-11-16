import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/firebase_service.dart';
import '../services/university_service.dart';
import '../services/chat_service.dart';
import '../services/trade_service.dart';
import '../services/notification_service.dart';
import '../services/nessie_api_service.dart';
import '../services/transaction_service.dart';

/// Initial bindings for the app - registers all controllers and services
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Register services
    Get.put(FirebaseService(), permanent: true);
    Get.put(UniversityService(), permanent: true);
    Get.put(NotificationService(), permanent: true);
    Get.put(ChatService(), permanent: true);
    Get.put(TradeService(), permanent: true);
    Get.put(NessieAPIService(), permanent: true);
    Get.put(TransactionService(), permanent: true);
    
    // Register controllers
    Get.put(AuthController(), permanent: true);
  }
}

