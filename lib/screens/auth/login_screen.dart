import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/auth_service.dart';
import '../auth/welcome_screen.dart';
import '../home/main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin, CodeAutoFill {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // Cooldown timer for resend
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  /// Called by CodeAutoFill mixin when SMS code is detected
  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      setState(() {
        _otpController.text = code!;
      });
      // Auto-verify once OTP is filled
      _verifyOTP();
    }
  }

  void _startListeningForSms() {
    if (kIsWeb) return;
    listenForCode();
  }

  void _startCooldown() {
    _cooldownSeconds = 30;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    cancel(); // Stop SMS listener
    _cooldownTimer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showError('Please enter a valid phone number');
      return;
    }

    final fullPhone = phone.startsWith('+') ? phone : '+91$phone';

    if (!kIsWeb) {
      // Android: show reCAPTCHA WebView first, then use REST API
      _showRecaptchaAndSendOTP(fullPhone);
    } else {
      // Web: use SDK directly
      setState(() => _isLoading = true);
      await _sendOTPWithToken(fullPhone, null);
    }
  }

  void _showRecaptchaAndSendOTP(String fullPhone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (ctx) {
        return Container(
          height: 420,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Complete the check to receive your OTP',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _RecaptchaWebView(
                  onToken: (token) {
                    Navigator.of(ctx).pop();
                    setState(() => _isLoading = true);
                    _sendOTPWithToken(fullPhone, token);
                  },
                  onError: () {
                    Navigator.of(ctx).pop();
                    _showError('Verification failed. Please try again.');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendOTPWithToken(String fullPhone, String? recaptchaToken) async {
    await _authService.verifyPhone(
      phoneNumber: fullPhone,
      recaptchaToken: recaptchaToken,
      onCodeSent: (verificationId) {
        setState(() {
          _verificationId = verificationId;
          _otpSent = true;
          _isLoading = false;
        });
        _startCooldown();
        _startListeningForSms();
      },
      onError: (error) {
        setState(() => _isLoading = false);
        _showError(error);
      },
      onAutoVerified: (credential) async {
        setState(() => _isLoading = true);
        try {
          final userCred = await _authService.signInWithCredential(credential);
          await _handleSignIn(userCred);
        } catch (e) {
          setState(() => _isLoading = false);
          _showError('Auto verification failed');
        }
      },
    );
  }

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred = await _authService.signInWithOTP(
        verificationId: _verificationId!,
        otp: otp,
      );
      await _handleSignIn(userCred);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Invalid OTP. Please try again.');
    }
  }

  Future<void> _handleSignIn(UserCredential userCred) async {
    final existingUser = await _authService.getUserProfile(userCred.user!.uid);

    if (!mounted) return;

    if (existingUser != null) {
      // Existing user - go to main screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      // New user - go to welcome/onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WelcomeScreen(
            uid: userCred.user!.uid,
            phone: userCred.user!.phoneNumber ?? _phoneController.text,
          ),
        ),
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.tealGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  // Logo area
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.taglineHindi,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'LOCAL ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'SATHI',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.taglineEnglish,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otpSent ? 'Enter OTP' : 'Welcome!',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _otpSent
                              ? 'OTP will be detected automatically'
                              : 'Sign in with your phone number',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!_otpSent) ...[
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      '🇮🇳 +91',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 24,
                                      margin: const EdgeInsets.only(left: 8),
                                      color: AppColors.textMuted.withOpacity(0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(6),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                            ),
                            decoration: const InputDecoration(
                              hintText: '• • • • • •',
                              hintStyle: TextStyle(letterSpacing: 8),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : (_otpSent ? _verifyOTP : _sendOTP),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _otpSent ? 'Verify OTP' : 'Send OTP',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),

                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _otpSent = false;
                                    _otpController.clear();
                                    _cooldownTimer?.cancel();
                                    _cooldownSeconds = 0;
                                  });
                                },
                                child: const Text(
                                  'Change number',
                                  style: TextStyle(color: AppColors.teal),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _cooldownSeconds > 0 ? null : _sendOTP,
                                child: Text(
                                  _cooldownSeconds > 0
                                      ? 'Resend in ${_cooldownSeconds}s'
                                      : 'Resend OTP',
                                  style: TextStyle(
                                    color: _cooldownSeconds > 0
                                        ? AppColors.textMuted
                                        : AppColors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

/// WebView widget that loads reCAPTCHA and returns the token
class _RecaptchaWebView extends StatefulWidget {
  final Function(String token) onToken;
  final VoidCallback onError;

  const _RecaptchaWebView({required this.onToken, required this.onError});

  @override
  State<_RecaptchaWebView> createState() => _RecaptchaWebViewState();
}

class _RecaptchaWebViewState extends State<_RecaptchaWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  static const _recaptchaHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<title>Verify</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    min-height: 100vh;
    background: #f5f5f5;
    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
  }
  .container {
    background: white;
    border-radius: 16px;
    padding: 24px;
    box-shadow: 0 2px 12px rgba(0,0,0,0.1);
    text-align: center;
    max-width: 340px;
    width: 90%;
  }
  .g-recaptcha { display: inline-block; }
  .done { color: #00897B; font-size: 16px; font-weight: 600; margin-top: 16px; }
</style>
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
</head>
<body>
<div class="container">
  <div class="g-recaptcha"
       data-sitekey="6LcMZR0UAAAAALgPMcgHwga7gY5p8QMg1Hj-bmUv"
       data-callback="onSuccess"
       data-theme="light"
       data-size="normal"></div>
  <div class="done" id="done" style="display:none">Verified! Sending OTP...</div>
</div>
<script>
function onSuccess(token) {
  document.getElementById('done').style.display = 'block';
  document.querySelector('.g-recaptcha').style.display = 'none';
  if (window.RecaptchaChannel) {
    RecaptchaChannel.postMessage(token);
  }
}
</script>
</body>
</html>
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'RecaptchaChannel',
        onMessageReceived: (message) {
          widget.onToken(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            widget.onError();
          },
        ),
      )
      ..loadHtmlString(
        _recaptchaHtml,
        baseUrl: 'https://local-sathi-eced8.firebaseapp.com',
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          const Center(
            child: CircularProgressIndicator(color: AppColors.teal),
          ),
      ],
    );
  }
}
