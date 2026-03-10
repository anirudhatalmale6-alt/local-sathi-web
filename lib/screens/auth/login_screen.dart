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

/// Auth WebView: navigates to Firebase's own domain (authorized for reCAPTCHA),
/// then injects Firebase Web SDK to handle phone auth.
/// Firebase Web SDK manages reCAPTCHA internally with correct keys/domain.
/// Returns the verificationId to Flutter via JavaScript channel.
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
  String _currentStatus = 'Preparing verification...';

  @override
  void initState() {
    super.initState();

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
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint('Auth WebView: page finished: $url');
            // Page loaded on Firebase domain. Now inject our auth script.
            _injectAuthScript();
          },
          onWebResourceError: (error) {
            debugPrint('Auth WebView error: ${error.description} (${error.errorCode})');
            if (error.isForMainFrame == true && !_resultSent) {
              _resultSent = true;
              widget.onError('Could not load verification. Please check your internet connection.');
            }
          },
        ),
      )
      // Load Firebase's own domain - always in authorized domains list
      ..loadRequest(Uri.parse('https://local-sathi-eced8.web.app'));
  }

  void _injectAuthScript() {
    final phone = widget.phoneNumber.replaceAll("'", "\\'");

    // This script:
    // 1. Clears the page and sets up UI
    // 2. Loads Firebase JS SDK (compat mode)
    // 3. Initializes Firebase with web config
    // 4. Creates RecaptchaVerifier (visible checkbox)
    // 5. Calls signInWithPhoneNumber
    // 6. Returns verificationId via FlutterChannel
    final script = '''
(function() {
  // Clear page and set up UI
  document.documentElement.innerHTML = '';
  document.write('<!DOCTYPE html><html><head>' +
    '<meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1">' +
    '<style>' +
    '* { margin:0; padding:0; box-sizing:border-box; }' +
    'body { display:flex; flex-direction:column; align-items:center; justify-content:center; min-height:100vh; background:#f5f5f5; font-family:-apple-system,BlinkMacSystemFont,sans-serif; padding:20px; }' +
    '.card { background:white; border-radius:16px; padding:32px 24px; max-width:400px; width:100%; box-shadow:0 2px 12px rgba(0,0,0,0.08); text-align:center; }' +
    'h3 { color:#333; font-size:17px; font-weight:600; margin-bottom:8px; }' +
    'p { color:#777; font-size:13px; margin-bottom:20px; }' +
    '.spinner { width:40px; height:40px; border:4px solid #e0e0e0; border-top:4px solid #00897B; border-radius:50%; animation:spin 0.8s linear infinite; margin:0 auto 16px; }' +
    '@keyframes spin { to { transform:rotate(360deg); } }' +
    '.recaptcha-wrap { display:inline-block; margin-top:12px; }' +
    '.success { color:#00897B; }' +
    '.error { color:#E53935; }' +
    '</style></head><body>' +
    '<div class="card">' +
    '<div id="loading"><div class="spinner"></div><h3>Loading security check...</h3><p>Please wait</p></div>' +
    '<div id="captcha-ui" style="display:none"><h3>Quick Security Check</h3><p>Complete the verification below</p><div class="recaptcha-wrap"><div id="recaptcha-container"></div></div></div>' +
    '<div id="sending-ui" style="display:none"><div class="spinner"></div><h3>Sending OTP...</h3><p>Please wait</p></div>' +
    '<div id="done-ui" style="display:none"><h3 class="success">OTP Sent!</h3><p>Returning to app...</p></div>' +
    '<div id="error-ui" style="display:none"><h3 class="error">Error</h3><p id="error-msg" class="error"></p></div>' +
    '</div></body></html>');
  document.close();

  function showPhase(id) {
    ['loading','captcha-ui','sending-ui','done-ui','error-ui'].forEach(function(p) {
      var el = document.getElementById(p);
      if (el) el.style.display = (p === id) ? 'block' : 'none';
    });
  }

  function reportError(msg) {
    showPhase('error-ui');
    var el = document.getElementById('error-msg');
    if (el) el.textContent = msg;
    try { FlutterChannel.postMessage('ERROR:' + msg); } catch(e) {}
  }

  function loadScript(src) {
    return new Promise(function(resolve, reject) {
      var s = document.createElement('script');
      s.src = src;
      s.onload = resolve;
      s.onerror = function() { reject(new Error('Failed to load: ' + src)); };
      document.head.appendChild(s);
    });
  }

  try { FlutterChannel.postMessage('STATUS:Loading Firebase SDK...'); } catch(e) {}

  // Load Firebase JS SDK (compat mode for simpler API)
  loadScript('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js')
  .then(function() {
    return loadScript('https://www.gstatic.com/firebasejs/10.12.0/firebase-auth-compat.js');
  })
  .then(function() {
    try { FlutterChannel.postMessage('STATUS:Initializing...'); } catch(e) {}

    // Initialize Firebase with web config
    if (!firebase.apps.length) {
      firebase.initializeApp({
        apiKey: "AIzaSyB8rbRBZodVqfGT3OeiXsIjsB5BOUtKG_4",
        authDomain: "local-sathi-eced8.firebaseapp.com",
        projectId: "local-sathi-eced8",
        appId: "1:342397239071:web:05ecc60d93da1966883a2a"
      });
    }

    // Show captcha UI
    showPhase('captcha-ui');

    // Create RecaptchaVerifier (visible checkbox - most reliable in WebViews)
    var recaptchaVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-container', {
      size: 'normal',
      callback: function(token) {
        showPhase('sending-ui');
        try { FlutterChannel.postMessage('STATUS:Verified! Sending OTP...'); } catch(e) {}
      },
      'expired-callback': function() {
        try { FlutterChannel.postMessage('STATUS:Verification expired. Please try again.'); } catch(e) {}
      }
    });

    // Render the reCAPTCHA first
    recaptchaVerifier.render().then(function() {
      try { FlutterChannel.postMessage('STATUS:Complete the security check'); } catch(e) {}
    });

    // Send OTP using Firebase Web SDK
    firebase.auth().signInWithPhoneNumber('$phone', recaptchaVerifier)
    .then(function(confirmationResult) {
      showPhase('done-ui');
      // confirmationResult.verificationId is compatible with native SDK
      try {
        FlutterChannel.postMessage('SESSION:' + confirmationResult.verificationId);
      } catch(e) {
        reportError('Could not communicate with app');
      }
    })
    .catch(function(error) {
      var msg = error.message || 'Verification failed';
      if (msg.indexOf('too-many-requests') >= 0) msg = 'Too many attempts. Please wait before trying again.';
      else if (msg.indexOf('invalid-phone') >= 0) msg = 'Invalid phone number.';
      else if (msg.indexOf('quota') >= 0) msg = 'SMS quota exceeded. Try later.';
      reportError(msg);
    });
  })
  .catch(function(err) {
    reportError('Failed to load verification system: ' + err.message);
  });
})();
''';

    _controller.runJavaScript(script).then((_) {
      debugPrint('Auth WebView: script injected');
      if (mounted) setState(() => _loading = false);
    }).catchError((e) {
      debugPrint('Auth WebView: script injection failed: $e');
      if (!_resultSent) {
        _resultSent = true;
        widget.onError('Failed to initialize verification');
      }
    });
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
