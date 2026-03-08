import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
  String _statusText = '';
  String _appVersion = '';
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
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _appVersion = 'v${info.version}+${info.buildNumber}');
      }
    } catch (_) {}
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

  void _setStatus(String text) {
    if (mounted) setState(() => _statusText = text);
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
      _setStatus('Sending OTP...');
      _usedRestApi = false;
      await _authService.verifyPhoneViaSdk(
        phoneNumber: fullPhone,
        onCodeSent: _onCodeSent,
        onError: _onSdkError,
        onAutoVerified: _onAutoVerified,
      );
    } else {
      // Android: use hosted reCAPTCHA WebView + REST API.
      // The WebView loads from a real HTTPS URL to ensure proper origin
      // for reCAPTCHA validation (loadHtmlString doesn't set origin correctly).
      _usedRestApi = true;
      _showAuthWebView(fullPhone);
    }
  }

  /// Android: show hosted auth WebView that handles reCAPTCHA + sends OTP via REST
  void _showAuthWebView(String fullPhone) {
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
            body: _AuthWebView(
              phoneNumber: fullPhone,
              onSessionInfo: (sessionInfo) {
                Navigator.of(ctx).pop();
                if (!mounted) return;
                debugPrint('Login: OTP sent, sessionInfo received');
                _onCodeSent(sessionInfo);
              },
              onError: (String msg) {
                Navigator.of(ctx).pop();
                _showError(msg);
              },
              onStatus: (String status) {
                debugPrint('Login WebView: $status');
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
      _statusText = '';
    });
    _startCooldown();
    _startListeningForSms();
  }

  void _onSdkError(String error) {
    setState(() {
      _isLoading = false;
      _statusText = '';
    });
    _showError(error);
  }

  void _onAutoVerified(PhoneAuthCredential credential) async {
    setState(() => _isLoading = true);
    _setStatus('Auto-verifying...');
    try {
      final userCred = await _authService.signInWithCredential(credential);
      await _handleSignIn(userCred);
    } catch (e) {
      setState(() => _isLoading = false);
      _setStatus('');
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
    _setStatus('Verifying OTP...');

    try {
      UserCredential userCred;
      if (_usedRestApi) {
        userCred = await _authService.verifyOTPViaRest(
          sessionInfo: _verificationId!,
          otp: otp,
        );
      } else {
        userCred = await _authService.signInWithOTP(
          verificationId: _verificationId!,
          otp: otp,
        );
      }
      _setStatus('Signing in...');
      await _handleSignIn(userCred);
    } catch (e) {
      setState(() => _isLoading = false);
      _setStatus('');
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

                        // Status text
                        if (_statusText.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            _statusText,
                            style: const TextStyle(fontSize: 12, color: AppColors.teal),
                            textAlign: TextAlign.center,
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
                                    _statusText = '';
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

                  // Version display
                  if (_appVersion.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      _appVersion,
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Auth WebView: loads hosted auth.html from a real HTTPS URL.
/// The hosted page handles reCAPTCHA verification and sends OTP via REST API.
/// Returns the sessionInfo (verificationId) to Flutter via JavaScript channel.
class _AuthWebView extends StatefulWidget {
  final String phoneNumber;
  final Function(String sessionInfo) onSessionInfo;
  final Function(String message) onError;
  final Function(String status) onStatus;

  const _AuthWebView({
    required this.phoneNumber,
    required this.onSessionInfo,
    required this.onError,
    required this.onStatus,
  });

  @override
  State<_AuthWebView> createState() => _AuthWebViewState();
}

class _AuthWebViewState extends State<_AuthWebView> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _resultSent = false;
  String _currentStatus = 'Loading verification page...';

  // Hosted auth page URL - loaded from real HTTPS URL for proper origin/referrer
  static const _authBaseUrl = 'https://localsathitechnologies.in/auth.html';
  // Android API key for REST API calls
  static const _apiKey = 'AIzaSyDNOCIYHqUr-D3qX0Hk5on8dykkvrhB5tY';

  @override
  void initState() {
    super.initState();

    final url = '$_authBaseUrl?phone=${Uri.encodeComponent(widget.phoneNumber)}&key=$_apiKey';
    debugPrint('Auth WebView: loading $url');

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (message) {
          final msg = message.message;
          debugPrint('Auth WebView message: $msg');

          if (_resultSent) return;

          if (msg.startsWith('SESSION:')) {
            _resultSent = true;
            widget.onSessionInfo(msg.substring(8));
          } else if (msg.startsWith('ERROR:')) {
            _resultSent = true;
            widget.onError(msg.substring(6));
          } else if (msg.startsWith('STATUS:')) {
            if (mounted) {
              setState(() => _currentStatus = msg.substring(7));
            }
            widget.onStatus(msg.substring(7));
          } else if (msg == 'PAGE_LOADED') {
            debugPrint('Auth WebView: page loaded successfully');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            debugPrint('Auth WebView: page finished loading');
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            debugPrint('Auth WebView error: ${error.description} (${error.errorCode})');
            // Only report fatal errors (not sub-resource errors)
            if (error.isForMainFrame == true && !_resultSent) {
              _resultSent = true;
              widget.onError('Could not load verification page. Please check your internet connection.');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading)
          Container(
            color: const Color(0xFFF5F5F5),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.teal),
                  const SizedBox(height: 16),
                  Text(
                    _currentStatus,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
