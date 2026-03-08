import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
  bool _usedRestApi = false;
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

  @override
  void codeUpdated() {
    if (code != null && code!.length == 6) {
      setState(() => _otpController.text = code!);
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
    cancel();
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

    if (kIsWeb) {
      // Web: use SDK directly (built-in reCAPTCHA handles everything)
      setState(() => _isLoading = true);
      _usedRestApi = false;
      await _authService.verifyPhoneViaSdk(
        phoneNumber: fullPhone,
        onCodeSent: _onCodeSent,
        onError: _onSdkError,
        onAutoVerified: _onAutoVerified,
      );
    } else {
      // Android: skip SDK entirely (Play Integrity is broken).
      // Go directly to reCAPTCHA + REST API for sending OTP.
      _usedRestApi = true;
      _showRecaptchaAndSendOTP(fullPhone);
    }
  }

  /// Android: show reCAPTCHA verification, then send OTP via REST API
  void _showRecaptchaAndSendOTP(String fullPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog.fullscreen(
          child: Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const Text('Verify Identity', style: TextStyle(fontWeight: FontWeight.w600)),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            body: _RecaptchaWebView(
              onToken: (token) async {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                setState(() => _isLoading = true);
                try {
                  debugPrint('Login: sending OTP via REST API...');
                  final sessionInfo = await _authService.sendOTPViaRest(
                    phoneNumber: fullPhone,
                    recaptchaToken: token,
                  );
                  debugPrint('Login: OTP sent, sessionInfo received');
                  _onCodeSent(sessionInfo);
                } catch (e) {
                  debugPrint('Login: REST API sendOTP failed: $e');
                  if (mounted) {
                    setState(() => _isLoading = false);
                    _showError(e.toString());
                  }
                }
              },
              onError: (String msg) {
                Navigator.of(ctx).pop();
                _showError(msg);
              },
            ),
          ),
        );
      },
    );
  }

  void _onCodeSent(String verificationId) {
    setState(() {
      _verificationId = verificationId;
      _otpSent = true;
      _isLoading = false;
    });
    _startCooldown();
    _startListeningForSms();
  }

  void _onSdkError(String error) {
    setState(() => _isLoading = false);
    _showError(error);
  }

  void _onAutoVerified(PhoneAuthCredential credential) async {
    setState(() => _isLoading = true);
    try {
      final userCred = await _authService.signInWithCredential(credential);
      await _handleSignIn(userCred);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Auto verification failed');
    }
  }

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showError('Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCred;
      if (_usedRestApi) {
        // Android path: verify via SDK signInWithCredential (preferred)
        // Falls back to REST API internally if SDK fails
        userCred = await _authService.verifyOTPViaRest(
          sessionInfo: _verificationId!,
          otp: otp,
        );
      } else {
        // Web path: verify via SDK
        userCred = await _authService.signInWithOTP(
          verificationId: _verificationId!,
          otp: otp,
        );
      }
      await _handleSignIn(userCred);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<void> _handleSignIn(UserCredential userCred) async {
    final existingUser = await _authService.getUserProfile(userCred.user!.uid);

    if (!mounted) return;

    if (existingUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(Icons.location_on, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.taglineHindi,
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'LOCAL ',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        TextSpan(
                          text: 'SATHI',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.orange),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConstants.taglineEnglish,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.7), letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 60),

                  // Login card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 32, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otpSent ? 'Enter OTP' : 'Welcome!',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.text),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _otpSent ? 'OTP will be detected automatically' : 'Sign in with your phone number',
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
                                    const Text('\u{1F1EE}\u{1F1F3} +91',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                    Container(
                                      width: 1, height: 24,
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
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 8),
                            decoration: const InputDecoration(
                              hintText: '\u2022 \u2022 \u2022 \u2022 \u2022 \u2022',
                              hintStyle: TextStyle(letterSpacing: 8),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : (_otpSent ? _verifyOTP : _sendOTP),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20, width: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    _otpSent ? 'Verify OTP' : 'Send OTP',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
                                child: const Text('Change number', style: TextStyle(color: AppColors.teal)),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _cooldownSeconds > 0 ? null : _sendOTP,
                                child: Text(
                                  _cooldownSeconds > 0 ? 'Resend in ${_cooldownSeconds}s' : 'Resend OTP',
                                  style: TextStyle(
                                    color: _cooldownSeconds > 0 ? AppColors.textMuted : AppColors.orange,
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

/// reCAPTCHA WebView: tries invisible mode first, falls back to visible checkbox.
class _RecaptchaWebView extends StatefulWidget {
  final Function(String token) onToken;
  final Function(String message) onError;

  const _RecaptchaWebView({required this.onToken, required this.onError});

  @override
  State<_RecaptchaWebView> createState() => _RecaptchaWebViewState();
}

class _RecaptchaWebViewState extends State<_RecaptchaWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  // HTML that tries invisible reCAPTCHA first, falls back to visible checkbox
  static const _recaptchaHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
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
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  }
  .loader {
    text-align: center;
    padding: 40px 24px;
  }
  .spinner {
    width: 44px; height: 44px;
    border: 4px solid #e0e0e0;
    border-top: 4px solid #00897B;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
    margin: 0 auto 20px;
  }
  @keyframes spin { to { transform: rotate(360deg); } }
  .loader h3 { color: #333; font-size: 17px; font-weight: 600; margin-bottom: 6px; }
  .loader p { color: #999; font-size: 13px; }
  .checkbox-section {
    display: none;
    text-align: center;
    padding: 40px 24px;
  }
  .checkbox-section h3 { color: #333; font-size: 18px; font-weight: 600; margin-bottom: 8px; }
  .checkbox-section p { color: #777; font-size: 14px; margin-bottom: 28px; }
  .recaptcha-wrap { display: inline-block; }
  .done-msg {
    display: none;
    text-align: center;
    padding: 40px 24px;
  }
  .done-msg .check {
    width: 56px; height: 56px;
    background: #00897B;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 16px;
    color: white;
    font-size: 28px;
  }
  .done-msg h3 { color: #00897B; font-size: 17px; font-weight: 600; }
</style>
<script src="https://www.google.com/recaptcha/api.js?onload=onRecaptchaLoad&render=explicit" async defer></script>
<script>
var tokenSent = false;
var invisibleWidget = null;

function onRecaptchaLoad() {
  // Try invisible reCAPTCHA first
  try {
    invisibleWidget = grecaptcha.render('invisible-box', {
      sitekey: '6LcMZR0UAAAAALgPMcgHwga7gY5p8QMg1Hj-bmUv',
      callback: onToken,
      'error-callback': showVisibleMode,
      'expired-callback': showVisibleMode,
      size: 'invisible'
    });
    grecaptcha.execute(invisibleWidget);
  } catch (e) {
    showVisibleMode();
  }

  // Timeout: if invisible doesn't resolve in 6 seconds, show visible checkbox
  setTimeout(function() {
    if (!tokenSent) showVisibleMode();
  }, 6000);
}

function showVisibleMode() {
  if (tokenSent) return;
  document.getElementById('loader').style.display = 'none';
  document.getElementById('checkbox-section').style.display = 'block';

  // Reset invisible widget if it exists
  try { if (invisibleWidget !== null) grecaptcha.reset(invisibleWidget); } catch(e) {}

  // Render visible checkbox
  try {
    grecaptcha.render('visible-box', {
      sitekey: '6LcMZR0UAAAAALgPMcgHwga7gY5p8QMg1Hj-bmUv',
      callback: onToken,
      theme: 'light',
      size: 'normal'
    });
  } catch(e) {
    // If rendering fails, report error
    if (window.RecaptchaChannel) {
      RecaptchaChannel.postMessage('ERROR:Verification setup failed');
    }
  }
}

function onToken(token) {
  if (tokenSent) return;
  tokenSent = true;
  document.getElementById('loader').style.display = 'none';
  document.getElementById('checkbox-section').style.display = 'none';
  document.getElementById('done-msg').style.display = 'block';
  if (window.RecaptchaChannel) {
    RecaptchaChannel.postMessage(token);
  }
}
</script>
</head>
<body>
  <div id="loader" class="loader">
    <div class="spinner"></div>
    <h3>Verifying your identity</h3>
    <p>This will only take a moment...</p>
  </div>

  <div id="checkbox-section" class="checkbox-section">
    <h3>Quick Security Check</h3>
    <p>Complete the verification below to continue</p>
    <div class="recaptcha-wrap"><div id="visible-box"></div></div>
  </div>

  <div id="invisible-box"></div>

  <div id="done-msg" class="done-msg">
    <div class="check">&check;</div>
    <h3>Verified! Sending OTP...</h3>
  </div>
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
          final msg = message.message;
          if (msg.startsWith('ERROR:')) {
            widget.onError(msg.substring(6));
          } else {
            widget.onToken(msg);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            debugPrint('reCAPTCHA WebView error: ${error.description}');
            widget.onError('Could not load verification. Please check your internet connection.');
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
          Container(
            color: const Color(0xFFF5F5F5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.teal),
                  SizedBox(height: 16),
                  Text('Loading verification...', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
