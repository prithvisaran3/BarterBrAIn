import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'bindings/app_bindings.dart';
import 'controllers/auth_controller.dart';
import 'core/constants.dart';
import 'core/firebase_options.dart';
import 'core/theme.dart';
import 'views/auth/login_view.dart';
import 'views/auth/otp_verify_view.dart';
import 'views/auth/profile_setup_view.dart';
import 'views/auth/signup_university_view.dart';
import 'views/main/main_navigation_view.dart';
import 'views/main/settings_view.dart';
import 'views/main/edit_profile_view.dart';
import 'views/products/edit_product_view.dart';
import 'views/profile/transaction_history_view.dart';
import 'views/profile/my_products_view.dart';
import 'views/products/all_products_view.dart';
import 'views/trade/trade_detail_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('✅ Firebase initialized successfully');

  // Initialize GetStorage
  await GetStorage.init();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BarterBrainApp());
}

class BarterBrainApp extends StatelessWidget {
  const BarterBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTheme(
      data: const CupertinoThemeData(
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: AppConstants.primaryColor,
        ),
      ),
      child: GetMaterialApp(
        title: 'BarterBrAIn',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialBinding: AppBindings(),
        initialRoute: '/splash',
        getPages: [
          GetPage(name: '/splash', page: () => const SplashScreen()),
          GetPage(
            name: '/login',
            page: () => const LoginView(),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: '/signup',
            page: () => SignupUniversityView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/otp-verify',
            page: () => OtpVerifyView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/profile-setup',
            page: () => ProfileSetupView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/main',
            page: () => const MainNavigationView(),
            transition: Transition.fadeIn,
          ),
          GetPage(
            name: '/settings',
            page: () => SettingsView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/edit-profile',
            page: () => const EditProfileView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/edit-product',
            page: () {
              final product = Get.arguments;
              return EditProductView(product: product);
            },
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/my-products',
            page: () => const MyProductsView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/all-products',
            page: () => const AllProductsView(),
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/trade-detail',
            page: () {
              final trade = Get.arguments;
              return TradeDetailView(trade: trade);
            },
            transition: Transition.rightToLeft,
          ),
          GetPage(
            name: '/transaction-history',
            page: () => const TransactionHistoryView(),
            transition: Transition.rightToLeft,
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _indicatorController;

  @override
  void initState() {
    super.initState();
    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    // Use WidgetsBinding to ensure navigation happens after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    // Wait for the splash screen to be visible
    await Future.delayed(const Duration(seconds: 2));

    // Ensure navigation happens after the current frame is complete
    if (!mounted) return;

    final authController = Get.find<AuthController>();

    if (authController.isAuthenticated) {
      Get.offAllNamed('/main');
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with glass effect
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppConstants.primaryColor,
                    Color(0xFFD65A2A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.4),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                    spreadRadius: -5,
                  ),
                  BoxShadow(
                    color: AppConstants.primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Image.asset(
                  'assets/logo/BarterBrAIn-icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if logo doesn't load
                    return const Icon(
                      Icons.swap_horizontal_circle,
                      size: 70,
                      color: Colors.white,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),
            // App name
            const Text(
              'BarterBrAIn',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            // Tagline with gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.secondaryColor,
                ],
              ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
              child: const Text(
                'Barter better with BarterBrAIn',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Custom progress indicator
            AnimatedBuilder(
              animation: _indicatorController,
              builder: (context, child) {
                final progress =
                    0.2 + (0.8 * Curves.easeInOut.transform(_indicatorController.value));
                return Container(
                  width: 200,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppConstants.systemGray6,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: progress,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppConstants.primaryColor,
                            AppConstants.secondaryColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: AppConstants.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }
}
