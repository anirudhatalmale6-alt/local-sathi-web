import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Singleton service for managing AdMob ads.
/// Checks Firestore for user subscription status to decide whether to show ads.
class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  bool _initialized = false;
  bool _isPremium = false;
  DateTime? _premiumExpiry;

  // Live Ad Unit IDs
  static const _bannerId = 'ca-app-pub-5100154126119051/9358083092';
  static const _interstitialId = 'ca-app-pub-5100154126119051/9218279031';

  String get bannerAdUnitId => _bannerId;
  String get interstitialAdUnitId => _interstitialId;

  bool get isPremium => _isPremium;
  bool get shouldShowAds => !_isPremium && !kIsWeb;
  DateTime? get premiumExpiry => _premiumExpiry;

  InterstitialAd? _interstitialAd;
  int _actionCount = 0;
  static const _interstitialInterval = 3; // Show interstitial every N actions

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('AdService: MobileAds initialized');
      await checkSubscriptionStatus();
      if (shouldShowAds) {
        _loadInterstitial();
      }
    } catch (e) {
      debugPrint('AdService: init error: $e');
    }
  }

  /// Check if current user has an active subscription
  Future<void> checkSubscriptionStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _isPremium = false;
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final expiry = (data['expiresAt'] as Timestamp?)?.toDate();
        final isActive = data['isActive'] == true;

        if (isActive && expiry != null && expiry.isAfter(DateTime.now())) {
          _isPremium = true;
          _premiumExpiry = expiry;
        } else {
          _isPremium = false;
          _premiumExpiry = null;
        }
      } else {
        _isPremium = false;
      }
    } catch (e) {
      debugPrint('AdService: subscription check error: $e');
      _isPremium = false;
    }
  }

  /// Create a banner ad widget
  BannerAd createBannerAd({Function? onLoaded, Function? onFailed}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner loaded');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner failed: ${error.message}');
          ad.dispose();
          onFailed?.call();
        },
      ),
    );
  }

  void _loadInterstitial() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('AdService: Interstitial loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdService: Interstitial failed: ${error.message}');
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Call this when user performs an action (view provider, open screen, etc.)
  /// Shows interstitial every [_interstitialInterval] actions.
  void onUserAction() {
    if (!shouldShowAds) return;
    _actionCount++;
    if (_actionCount >= _interstitialInterval) {
      _actionCount = 0;
      showInterstitial();
    }
  }

  void showInterstitial() {
    if (!shouldShowAds || _interstitialAd == null) return;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
