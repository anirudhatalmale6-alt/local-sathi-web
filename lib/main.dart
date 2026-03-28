import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'config/theme.dart';
import 'providers/app_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_shell.dart';
import 'services/auth_service.dart';
import 'services/update_service.dart';
import 'services/ad_service.dart';
import 'services/payment_service.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase init failed - app will still launch
    debugPrint('Firebase init error: $e');
  }

  // Initialize AdMob (non-blocking)
  AdService().initialize();

  // Initialize Razorpay payment service
  PaymentService().initialize();

  runApp(const LocalSathiApp());
}

class LocalSathiApp extends StatelessWidget {
  const LocalSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Local Sathi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          if (kIsWeb) {
            final width = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            // Mobile: full width. Tablet (600-1024): centered 540px. Desktop (1024+): centered 480px with side branding.
            if (width > 1024) {
              return Container(
                color: const Color(0xFFF0F4F3),
                child: Row(
                  children: [
                    // Left branding panel
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0097A7), Color(0xFF00BCD4)],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.15),
                                ),
                                child: const Icon(Icons.location_on, size: 40, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              const Text('LOCAL SATHI',
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2, decoration: TextDecoration.none),
                              ),
                              const SizedBox(height: 6),
                              Text('your community companion',
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7), letterSpacing: 1.5, decoration: TextDecoration.none, fontWeight: FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // App content in phone-like frame
                    Container(
                      width: 480,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 32)],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(size: Size(480, screenHeight)),
                        child: child!,
                      ),
                    ),
                  ],
                ),
              );
            } else if (width > 600) {
              // Tablet: centered with shadow
              return Container(
                color: const Color(0xFFF0F4F3),
                child: Center(
                  child: Container(
                    width: 540,
                    decoration: BoxDecoration(
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 24)],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(size: Size(540, screenHeight)),
                      child: child!,
                    ),
                  ),
                ),
              );
            }
          }
          return child!;
        },
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check for app updates (skip on web)
    if (!kIsWeb) {
      try {
        final updateService = UpdateService();
        final result = await updateService.checkForUpdate();
        if (mounted && result.type != UpdateType.none && result.info != null) {
          await showDialog(
            context: context,
            barrierDismissible: result.type != UpdateType.forced,
            builder: (_) => UpdateDialog(
              updateType: result.type,
              versionInfo: result.info!,
            ),
          );
          // If forced update, don't proceed
          if (result.type == UpdateType.forced) return;
        }
      } catch (_) {
        // Update check failed, continue normally
      }
    }

    if (!mounted) return;

    final authService = AuthService();
    final isLoggedIn = authService.currentUser != null;

    Widget destination;
    if (isLoggedIn) {
      destination = const MainShell();
    } else {
      destination = const LoginScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0097A7),
              Color(0xFF00BCD4),
              Color(0xFF00E5FF),
              Color(0xFFB2EBF2),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 32,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white.withOpacity(0.15),
                          child: const Icon(Icons.location_on, size: 60, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '\u0905\u092A\u0928\u093E \u0936\u0939\u0930 \u0915\u093E \u0905\u092A\u0928\u093E \u0928\u0947\u091F\u0935\u0930\u094D\u0915',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'LOCAL ',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                        TextSpan(
                          text: 'SATHI',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'your community companion',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
