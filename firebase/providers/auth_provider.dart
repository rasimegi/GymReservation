import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_reservation/firebase/models/user_model.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  String? get errorMessage => _errorMessage;
  
  // Başlangıçta kullanıcı durumunu kontrol et
  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _firebaseUser = _firebaseService.currentUser;
      
      if (_firebaseUser != null) {
        // Kullanıcı giriş yapmışsa profilini yükle
        await _loadUserData();
      }
    } catch (e) {
      _errorMessage = 'Kullanıcı durumu kontrol edilirken hata: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Kullanıcı verisini Firestore'dan yükle
  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;
    
    try {
      final userData = await _firebaseService.getUserProfile(_firebaseUser!.uid);
      
      if (userData != null) {
        _userModel = UserModel.fromFirestore(userData, _firebaseUser!.uid);
      } else {
        // Kullanıcı verisi yoksa yeni oluştur
        _userModel = UserModel(
          uid: _firebaseUser!.uid,
          email: _firebaseUser!.email ?? '',
          username: _firebaseUser!.displayName ?? '',
        );
        
        // Firestore'a kaydet
        await _firebaseService.saveUserProfile(
          userId: _firebaseUser!.uid,
          userData: _userModel!.toFirestore(),
        );
      }
    } catch (e) {
      _errorMessage = 'Kullanıcı verisi yüklenirken hata: $e';
      print(_errorMessage);
    }
  }
  
  // Giriş yapma
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _firebaseService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _firebaseUser = result.user;
      
      if (_firebaseUser != null) {
        await _loadUserData();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Kaydolma
  Future<bool> signUp(String email, String password, String username) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final result = await _firebaseService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _firebaseUser = result.user;
      
      if (_firebaseUser != null) {
        // Kullanıcı modelini oluştur
        _userModel = UserModel(
          uid: _firebaseUser!.uid,
          email: email,
          username: username,
        );
        
        // Firestore'a kaydet
        await _firebaseService.saveUserProfile(
          userId: _firebaseUser!.uid,
          userData: _userModel!.toFirestore(),
        );
        
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Çıkış yapma
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _firebaseService.signOut();
      _firebaseUser = null;
      _userModel = null;
    } catch (e) {
      _errorMessage = 'Çıkış yapılırken hata: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Şifre sıfırlama
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await _firebaseService.resetPassword(email);
      return true;
    } catch (e) {
      _errorMessage = _handleAuthError(e);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Kullanıcı profili güncelleme
  Future<bool> updateUserProfile(Map<String, dynamic> updatedData) async {
    if (_firebaseUser == null || _userModel == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      // Firestore'da güncelle
      await _firebaseService.updateUserProfile(
        userId: _firebaseUser!.uid,
        userData: updatedData,
      );
      
      // Kullanıcı modelini güncelle
      final updatedUserData = 
          await _firebaseService.getUserProfile(_firebaseUser!.uid);
      
      if (updatedUserData != null) {
        _userModel = UserModel.fromFirestore(updatedUserData, _firebaseUser!.uid);
      }
      
      return true;
    } catch (e) {
      _errorMessage = 'Profil güncellenirken hata: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Firebase auth hatalarını işleme
  String _handleAuthError(dynamic error) {
    String errorMessage = 'Bilinmeyen bir hata oluştu';
    
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          errorMessage = 'Bu e-posta ile kayıtlı kullanıcı bulunamadı';
          break;
        case 'wrong-password':
          errorMessage = 'Yanlış şifre';
          break;
        case 'email-already-in-use':
          errorMessage = 'Bu e-posta adresi zaten kullanımda';
          break;
        case 'weak-password':
          errorMessage = 'Şifre çok zayıf';
          break;
        case 'invalid-email':
          errorMessage = 'Geçersiz e-posta adresi';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Bu işlem şu anda izin verilmiyor';
          break;
        case 'too-many-requests':
          errorMessage = 'Çok fazla istek. Lütfen daha sonra tekrar deneyin';
          break;
        default:
          errorMessage = 'Hata: ${error.message}';
      }
    }
    
    return errorMessage;
  }
} 