import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String _city = '';
  String _state = '';
  double? _latitude;
  double? _longitude;
  bool _isLoading = false;
  int _currentTabIndex = 0;

  UserModel? get currentUser => _currentUser;
  String get city => _city;
  String get state => _state;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isLoading => _isLoading;
  int get currentTabIndex => _currentTabIndex;
  bool get isLoggedIn => _authService.currentUser != null;

  void setTabIndex(int index) {
    _currentTabIndex = index;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  String? _loadError;
  String? get loadError => _loadError;

  Future<void> loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        _isLoading = true;
        _loadError = null;
        notifyListeners();

        _currentUser = await _authService.getUserProfile(user.uid);

        // Set online status
        try {
          await FirestoreService().setOnlineStatus(user.uid, true);
        } catch (_) {}

        // Auto-upgrade first user (LS-100001) to admin if not already
        if (_currentUser != null &&
            _currentUser!.localSathiId == 'LS-100001' &&
            !_currentUser!.isAdmin) {
          await _authService.updateUserProfile(user.uid, {'role': 'admin'});
          _currentUser = await _authService.getUserProfile(user.uid);
        }
      } catch (e) {
        debugPrint('Failed to load user profile: $e');
        _loadError = e.toString();
        _currentUser = null;
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (address != null) {
          _city = address['city'] ?? '';
          _state = address['state'] ?? '';
        }
      }
      // If location detection returned null or city is still empty, use user's profile location
      if (_city.isEmpty) {
        _city = _currentUser?.city ?? 'India';
        _state = _currentUser?.state ?? '';
      }
    } catch (e) {
      // Location failed, use profile location or default
      _city = _currentUser?.city ?? 'India';
      _state = _currentUser?.state ?? '';
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    // Set offline before signing out
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      try {
        await FirestoreService().setOnlineStatus(uid, false);
      } catch (_) {}
    }
    await _authService.signOut();
    _currentUser = null;
    _currentTabIndex = 0;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }
}
