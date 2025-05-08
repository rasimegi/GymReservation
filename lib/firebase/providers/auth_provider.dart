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
  Future<bool> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _firebaseUser = _firebaseService.currentUser;

      if (_firebaseUser != null) {
        // Kullanıcı giriş yapmışsa profilini yükle
        print(
          "AuthProvider: Kullanıcı oturumu bulundu, ID: ${_firebaseUser!.uid}",
        );
        await _loadUserData();
        print(
          "AuthProvider: Kullanıcı verileri yüklendi: ${_userModel?.username}",
        );
      } else {
        print("AuthProvider: Kullanıcı oturumu bulunamadı");
      }
    } catch (e) {
      _errorMessage = 'Kullanıcı durumu kontrol edilirken hata: $e';
      print("AuthProvider: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return _firebaseUser != null; // Oturum açık ise true, değilse false döndür
  }

  // Kullanıcı verisini Firestore'dan yükle
  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;

    try {
      final userData = await _firebaseService.getUserProfile(
        _firebaseUser!.uid,
      );

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
      print("AuthProvider: signUp başlatılıyor");
      print("Email: $email, Username: $username");

      // Parametreleri kontrol et
      if (email.isEmpty || password.isEmpty || username.isEmpty) {
        _errorMessage = "Email, şifre ve kullanıcı adı boş olamaz";
        print("AuthProvider: $_errorMessage");
        return false;
      }

      // 1. Adım: Firebase Authentication ile kullanıcı oluştur
      print("AuthProvider: Firebase Authentication kaydı başlatılıyor");
      final userCredential = await _firebaseService
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      // Kullanıcı oluşturma başarısız mı?
      if (user == null) {
        _errorMessage = "Kullanıcı oluşturulamadı";
        print("AuthProvider: $_errorMessage");
        return false;
      }

      print("AuthProvider: Firebase kullanıcı oluşturuldu: ${user.uid}");

      // 2. Adım: Firestore'a kullanıcı profili kaydet
      try {
        print("AuthProvider: Firestore'a kullanıcı profili kaydediliyor...");

        // Kullanıcı verilerini hazırla
        final userData = {
          "email": email,
          "username": username,
          "uid": user.uid,
          // Boş alanları başlangıç değerleri ile ekleyelim
          "name": "",
          "surname": "",
          "createdAt":
              DateTime.now().millisecondsSinceEpoch, // Oluşturma zamanını ekle
        };

        // Firestore'a kaydet
        await _firebaseService.saveUserProfile(
          userId: user.uid,
          userData: userData,
        );

        // UserModel'i güncelle
        _firebaseUser = user;
        _userModel = UserModel(uid: user.uid, email: email, username: username);

        print("AuthProvider: Firestore'a kullanıcı profili kaydedildi.");
        return true;
      } catch (firestoreError) {
        print("AuthProvider: Firestore hata: $firestoreError");

        // Firestore hatası durumunda, oluşturulan Firebase auth kullanıcısını sil
        try {
          print("AuthProvider: Oluşturulan kullanıcı siliniyor...");
          await user.delete();
          print("AuthProvider: Kullanıcı silindi.");
        } catch (deleteError) {
          print("AuthProvider: Kullanıcı silinemedi: $deleteError");
        }

        _errorMessage = "Kullanıcı profili oluşturulamadı: $firestoreError";
        return false;
      }
    } catch (e) {
      print("AuthProvider: Hata: $e");
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
    if (_firebaseUser == null || _userModel == null) {
      _errorMessage = "Oturum açık değil, profil güncellenemiyor";
      print("AuthProvider: $_errorMessage");
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("AuthProvider: updateUserProfile başlatılıyor");
      print("Güncellenecek veri: $updatedData");

      // Boş veri kontrolü
      if (updatedData.isEmpty) {
        _errorMessage = "Güncellenecek veri boş olamaz";
        print("AuthProvider: $_errorMessage");
        return false;
      }

      // Firestore'da güncelle
      await _firebaseService.updateUserProfile(
        userId: _firebaseUser!.uid,
        userData: updatedData,
      );

      print("AuthProvider: Profil başarıyla güncellendi");

      // Kullanıcı modelini güncelle
      final updatedUserData = await _firebaseService.getUserProfile(
        _firebaseUser!.uid,
      );

      if (updatedUserData != null) {
        _userModel = UserModel.fromFirestore(
          updatedUserData,
          _firebaseUser!.uid,
        );
        print("AuthProvider: Kullanıcı modeli güncellendi");
      } else {
        print(
          "AuthProvider: Uyarı - Kullanıcı profili yüklenemedi, yerel model güncellendi",
        );
        // Firestore'dan veri çekemediyesek, yerel modeli güncelle
        _userModel = _userModel!.copyWith(
          name: updatedData['name'] ?? _userModel!.name,
          surname: updatedData['surname'] ?? _userModel!.surname,
          username: updatedData['username'] ?? _userModel!.username,
        );
      }

      return true;
    } on FirebaseException catch (e) {
      _errorMessage = "Profil güncellenirken Firebase hatası: ${e.message}";
      print("AuthProvider: $_errorMessage");
      return false;
    } catch (e) {
      _errorMessage = 'Profil güncellenirken hata: $e';
      print("AuthProvider: $_errorMessage");
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
