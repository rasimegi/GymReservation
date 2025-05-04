import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Kullanıcı kimlik doğrulama metodları
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  User? get currentUser => _auth.currentUser;

  // Firestore ile veri işlemleri
  // Kullanıcı profil bilgilerini kaydetme
  Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update(userData);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Vücut ölçülerini kaydetme
  Future<void> saveBodyMeasurements({
    required String userId,
    required Map<String, dynamic> measurements,
    required String date,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('measurements')
          .doc(date)
          .set(measurements);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBodyMeasurementsHistory(
    String userId,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('measurements')
              .orderBy('date', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Rezervasyon işlemleri
  Future<void> createReservation({
    required String userId,
    required Map<String, dynamic> reservationData,
  }) async {
    try {
      // Rezervasyon ID'si: tarih_saat
      final String reservationId =
          '${reservationData['date']}_${reservationData['timeSlot']}';

      // Rezervasyonu kullanıcı koleksiyonuna kaydet
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reservations')
          .doc(reservationId)
          .set(reservationData);

      // Aynı zamanda genel rezervasyonlar koleksiyonuna da kaydet
      await _firestore.collection('reservations').doc(reservationId).set({
        ...reservationData,
        'userId': userId,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelReservation({
    required String userId,
    required String reservationId,
  }) async {
    try {
      // Kullanıcı koleksiyonundan rezervasyonu sil
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reservations')
          .doc(reservationId)
          .delete();

      // Genel rezervasyonlar koleksiyonundan da sil
      await _firestore.collection('reservations').doc(reservationId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserReservations(String userId) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('reservations')
              .orderBy('date')
              .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getReservedTimeSlots(String date) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('reservations')
              .where('date', isEqualTo: date)
              .get();

      return snapshot.docs
          .map(
            (doc) => (doc.data() as Map<String, dynamic>)['timeSlot'] as String,
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // Firebase Storage ile profil resmi yükleme
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final Reference ref = _storage.ref().child('profile_images/$userId');
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot taskSnapshot = await uploadTask;

      // Resmin URL'sini al
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Profil bilgilerinde güncelle
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
}
