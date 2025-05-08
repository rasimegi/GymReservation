import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:gym_reservation/firebase/models/announcement_model.dart';
import 'package:gym_reservation/firebase/models/training_program_model.dart';

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
      print("FirebaseService: createUserWithEmailAndPassword başlatılıyor");
      print("Email: $email");

      // Önce email geçerliliğini basit bir şekilde kontrol et
      if (!email.contains('@') || !email.contains('.')) {
        throw FirebaseAuthException(
          code: 'invalid-email',
          message: 'Email format geçerli değil: $email',
        );
      }

      // Önce şifre uzunluğunu basit bir şekilde kontrol et
      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password',
          message: 'Şifre en az 6 karakter olmalıdır',
        );
      }

      // Firebase Authentication ile kullanıcı oluştur
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      print("FirebaseService: Kullanıcı başarıyla oluşturuldu: ${user?.uid}");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print("FirebaseService: Firebase Auth Hatası: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print("FirebaseService: Beklenmeyen Hata: $e");
      throw FirebaseAuthException(
        code: 'unknown',
        message: 'Beklenmeyen bir hata oluştu: $e',
      );
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

  User? get currentUser {
    User? user = _auth.currentUser;
    if (user != null) {
      print("Aktif kullanıcı: ${user.uid} (${user.email})");
    } else {
      print("Aktif kullanıcı bulunamadı! Lütfen giriş yapın.");
    }
    return user;
  }

  // Firestore ile veri işlemleri
  // Kullanıcı profil bilgilerini kaydetme
  Future<void> saveUserProfile({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      print("FirebaseService: saveUserProfile başlatılıyor");
      print("UserId: $userId");
      print("UserData: $userData");

      // UserId boş olmamalı
      if (userId.isEmpty) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'invalid-argument',
          message: 'Kullanıcı ID boş olamaz',
        );
      }

      // UserData boş olmamalı
      if (userData.isEmpty) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'invalid-argument',
          message: 'Kullanıcı verileri boş olamaz',
        );
      }

      // Email kontrol et
      if (!userData.containsKey('email') ||
          userData['email'] == null ||
          userData['email'].toString().isEmpty) {
        print("FirebaseService: Email verisi eksik veya boş");
        throw FirebaseException(
          plugin: 'firestore',
          code: 'invalid-argument',
          message: 'Email verisi eksik veya boş',
        );
      }

      // Firestore'a kaydet - await ile beklet
      await _firestore.collection('users').doc(userId).set(userData);

      print("FirebaseService: Kullanıcı profili başarıyla kaydedildi");
    } on FirebaseException catch (e) {
      print("FirebaseService: Firestore Hatası: ${e.code} - ${e.message}");
      rethrow;
    } catch (e) {
      print(
        "FirebaseService: Kullanıcı profili kaydetme beklenmeyen hatası: $e",
      );
      throw FirebaseException(
        plugin: 'firestore',
        code: 'unknown',
        message: 'Beklenmeyen bir hata oluştu: $e',
      );
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
      print("saveBodyMeasurements başlatılıyor...");
      print("userId: $userId");
      print("measurements: $measurements");
      print("date: $date");

      // Önce 'measurements' koleksiyonu var mı kontrol et, yoksa oluştur
      try {
        // Ana measurements koleksiyonuna kaydet (kullanıcıdan bağımsız)
        await _firestore
            .collection('measurements')
            .doc(measurements['measurementId'])
            .set({...measurements, 'userId': userId});
        print("Genel measurements koleksiyonuna başarıyla kaydedildi");
      } catch (e) {
        print("Genel measurements koleksiyonuna kaydetme hatası: $e");
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }
      }

      // Kullanıcıya özel measurements koleksiyonuna kaydet
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('measurements')
            .doc(measurements['measurementId'])
            .set(measurements);
        print("Kullanıcı measurements koleksiyonuna başarıyla kaydedildi");
      } catch (e) {
        print("Kullanıcı measurements koleksiyonuna kaydetme hatası: $e");
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }
        throw e;
      }

      print("Vücut ölçüleri başarıyla kaydedildi");
    } catch (e) {
      print("Vücut ölçüleri kaydedilirken hata: $e");
      print("Hata detayı: ${e.toString()}");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBodyMeasurementsHistory(
    String userId,
  ) async {
    try {
      print("getBodyMeasurementsHistory başlatılıyor...");
      print("userId: $userId");
      List<Map<String, dynamic>> result = [];

      // Ağ bağlantısını etkinleştir
      try {
        await _firestore.enableNetwork();
        print("Firestore ağ bağlantısı etkinleştirildi");
      } catch (e) {
        print("Firestore ağ bağlantısı etkinleştirilirken hata: $e");
      }

      // Öncelikli olarak genel measurements koleksiyonundan veri almayı dene
      try {
        print(
          "Öncelikle genel measurements koleksiyonundan veri almaya çalışılıyor...",
        );
        final QuerySnapshot generalSnapshot =
            await _firestore
                .collection('measurements')
                .where('userId', isEqualTo: userId)
                .get(); // indeks hatasını önlemek için sıralama kaldırıldı

        if (generalSnapshot.docs.isNotEmpty) {
          print(
            "Genel measurements koleksiyonundan ${generalSnapshot.docs.length} ölçüm bulundu",
          );

          result =
              generalSnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

          // Verileri burada, uygulama içinde sırala
          result.sort((a, b) {
            // Önce updatedAt alanına göre sırala
            final String updatedAtA = a['updatedAt'] ?? '';
            final String updatedAtB = b['updatedAt'] ?? '';

            if (updatedAtA.isNotEmpty && updatedAtB.isNotEmpty) {
              return updatedAtB.compareTo(
                updatedAtA,
              ); // en son güncellenen en üstte
            }

            // Eğer updatedAt yoksa, mDate alanına göre sırala
            final String mDateA = a['mDate'] ?? '';
            final String mDateB = b['mDate'] ?? '';
            return mDateB.compareTo(mDateA); // en son tarih en üstte
          });

          // Debug: en son kayıt bilgilerini logla
          if (result.isNotEmpty) {
            print("Measurements koleksiyonundan en son kayıt bilgileri:");
            print("ID: ${result.first['measurementId']}");
            print("Tarih: ${result.first['mDate']}");
            print("Güncelleme: ${result.first['updatedAt']}");
            print("Kilo: ${result.first['weight']}");
            print("Boy: ${result.first['height']}");
          }

          return result;
        } else {
          print(
            "Genel measurements koleksiyonunda ölçüm bulunamadı. Kullanıcı koleksiyonuna bakılıyor...",
          );
        }
      } catch (e) {
        print("Genel measurements koleksiyonundan ölçümleri alma hatası: $e");
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }
      }

      // Sonra kullanıcı koleksiyonundan veri almayı dene
      try {
        final QuerySnapshot userSnapshot =
            await _firestore
                .collection('users')
                .doc(userId)
                .collection('measurements')
                .get(); // indeks hatasını önlemek için sıralama kaldırıldı

        if (userSnapshot.docs.isNotEmpty) {
          print(
            "Kullanıcı koleksiyonundan ${userSnapshot.docs.length} ölçüm bulundu",
          );

          result =
              userSnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

          // Verileri burada, uygulama içinde sırala
          result.sort((a, b) {
            // Önce updatedAt alanına göre sırala
            final String updatedAtA = a['updatedAt'] ?? '';
            final String updatedAtB = b['updatedAt'] ?? '';

            if (updatedAtA.isNotEmpty && updatedAtB.isNotEmpty) {
              return updatedAtB.compareTo(
                updatedAtA,
              ); // en son güncellenen en üstte
            }

            // Eğer updatedAt yoksa, mDate alanına göre sırala
            final String mDateA = a['mDate'] ?? '';
            final String mDateB = b['mDate'] ?? '';
            return mDateB.compareTo(mDateA); // en son tarih en üstte
          });

          // Debug: en son kayıt bilgilerini logla
          if (result.isNotEmpty) {
            print("Kullanıcı koleksiyonundan en son kayıt bilgileri:");
            print("ID: ${result.first['measurementId']}");
            print("Tarih: ${result.first['mDate']}");
            print("Güncelleme: ${result.first['updatedAt']}");
            print("Kilo: ${result.first['weight']}");
            print("Boy: ${result.first['height']}");
          }

          return result;
        } else {
          print(
            "Kullanıcı koleksiyonunda ölçüm bulunamadı. Alternatif koleksiyona bakılıyor...",
          );
        }
      } catch (e) {
        print("Kullanıcı koleksiyonundan ölçümleri alma hatası: $e");
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }
      }

      // Son olarak alternatif measurements_direct koleksiyonundan veri almayı dene
      try {
        final QuerySnapshot directSnapshot =
            await _firestore
                .collection('measurements_direct')
                .where('userId', isEqualTo: userId)
                .get(); // indeks hatasını önlemek için sıralama kaldırıldı

        print(
          "Alternatif measurements_direct koleksiyonundan ${directSnapshot.docs.length} ölçüm bulundu",
        );

        if (directSnapshot.docs.isNotEmpty) {
          // Eğer alternatif koleksiyondan veri bulunabildiyse sonucu güncelle
          List<Map<String, dynamic>> directResult =
              directSnapshot.docs
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

          // Verileri burada, uygulama içinde sırala
          directResult.sort((a, b) {
            // Önce updatedAt alanına göre sırala
            final String updatedAtA = a['updatedAt'] ?? '';
            final String updatedAtB = b['updatedAt'] ?? '';

            if (updatedAtA.isNotEmpty && updatedAtB.isNotEmpty) {
              return updatedAtB.compareTo(
                updatedAtA,
              ); // en son güncellenen en üstte
            }

            // Eğer updatedAt yoksa, mDate alanına göre sırala
            final String mDateA = a['mDate'] ?? '';
            final String mDateB = b['mDate'] ?? '';
            return mDateB.compareTo(mDateA); // en son tarih en üstte
          });

          // Alternatif koleksiyondan gelen verileri sonuca ekle
          result.addAll(directResult);

          // Sonuçları tekrar sırala
          result.sort((a, b) {
            // Önce updatedAt alanına göre sırala
            final String updatedAtA = a['updatedAt'] ?? '';
            final String updatedAtB = b['updatedAt'] ?? '';

            if (updatedAtA.isNotEmpty && updatedAtB.isNotEmpty) {
              return updatedAtB.compareTo(
                updatedAtA,
              ); // en son güncellenen en üstte
            }

            // Eğer updatedAt yoksa, mDate alanına göre sırala
            final String mDateA = a['mDate'] ?? '';
            final String mDateB = b['mDate'] ?? '';
            return mDateB.compareTo(mDateA); // en son tarih en üstte
          });
        }
      } catch (e) {
        print(
          "Alternatif measurements_direct koleksiyonundan ölçümleri alma hatası: $e",
        );
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }

        // Eğer burada da hata alındıysa ve sonuç hala boşsa, hatayı ilet
        if (result.isEmpty) {
          throw e;
        }
      }

      return result;
    } catch (e) {
      print("Ölçüm geçmişi alınırken hata: $e");
      print("Hata detayı: ${e.toString()}");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  // Rezervasyon işlemleri
  Future<void> createReservation({
    required String userId,
    required Map<String, dynamic> reservationData,
  }) async {
    try {
      print("createReservation başlatılıyor...");
      print("userId: $userId");
      print("reservationData: $reservationData");

      // Eğer reservationId değeri verilmişse onu kullan, yoksa tarih_saat formatını kullan
      final String reservationId =
          reservationData['reservationId'] ??
          '${reservationData['date']}_${reservationData['timeSlot']}';

      print("Kullanılan reservationId: $reservationId");

      // Rezervasyonu kullanıcı koleksiyonuna kaydet
      print("Kullanıcı koleksiyonuna kaydetme işlemi başlatılıyor...");
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('reservations')
            .doc(reservationId)
            .set(reservationData);
        print("Kullanıcı koleksiyonuna başarıyla kaydedildi");
      } catch (e) {
        print("Kullanıcı koleksiyonuna kaydetme hatası: $e");
        throw e;
      }

      // Aynı zamanda genel rezervasyonlar koleksiyonuna da kaydet
      print(
        "Genel rezervasyonlar koleksiyonuna kaydetme işlemi başlatılıyor...",
      );
      try {
        await _firestore.collection('reservations').doc(reservationId).set({
          ...reservationData,
          'userId': userId,
        });
        print("Genel rezervasyonlar koleksiyonuna başarıyla kaydedildi");
      } catch (e) {
        print("Genel rezervasyonlar koleksiyonuna kaydetme hatası: $e");
        throw e;
      }

      print("Rezervasyon başarıyla oluşturuldu: $reservationId");
      print("Rezervasyon verileri: $reservationData");
    } catch (e) {
      print("Rezervasyon oluşturulurken hata: $e");
      print("Hata detayı: ${e.toString()}");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
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
      print("getUserReservations başlatılıyor... userId: $userId");
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('reservations')
              .orderBy('date')
              .get();

      print("Rezervasyon sayısı: ${snapshot.docs.length}");

      final result =
          snapshot.docs.map((doc) {
            print("Rezervasyon dokümanı: ${doc.id}");
            print("Rezervasyon verisi: ${doc.data()}");
            return doc.data() as Map<String, dynamic>;
          }).toList();

      print("Döndürülen rezervasyon sayısı: ${result.length}");
      return result;
    } catch (e) {
      print("Rezervasyonları getirirken hata: $e");
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

      // Her zaman diliminin kaç kez rezerve edildiğini say
      Map<String, int> timeSlotCounts = {};

      // Tüm belgeler üzerinde dönerek her zaman diliminin kullanım sayısını hesapla
      for (var doc in snapshot.docs) {
        final timeSlot =
            (doc.data() as Map<String, dynamic>)['timeSlot'] as String;
        timeSlotCounts[timeSlot] = (timeSlotCounts[timeSlot] ?? 0) + 1;
      }

      // 3 veya daha fazla kez rezerve edilmiş zaman dilimlerini döndür
      List<String> fullyBookedTimeSlots = [];
      timeSlotCounts.forEach((timeSlot, count) {
        if (count >= 3) {
          fullyBookedTimeSlots.add(timeSlot);
        }
      });

      print(
        "Tarih: $date, Tamamen dolu zaman dilimleri: $fullyBookedTimeSlots",
      );

      return fullyBookedTimeSlots;
    } catch (e) {
      print("Rezerve edilmiş zaman dilimlerini getirirken hata: $e");
      rethrow;
    }
  }

  // Rezervasyon durumunu güncelle
  Future<void> updateReservationStatus({
    required String userId,
    required String reservationId,
    required bool isActive,
  }) async {
    try {
      // Önce rezervasyonu kullanıcı koleksiyonunda güncelle
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reservations')
          .doc(reservationId)
          .update({'isActive': isActive});

      // Ardından genel rezervasyonlar koleksiyonunda da güncelle
      await _firestore.collection('reservations').doc(reservationId).update({
        'isActive': isActive,
      });
    } catch (e) {
      print("Rezervasyon durumu güncellenirken hata: $e");
      rethrow;
    }
  }

  // Rezervasyonu tamamen sil
  Future<void> deleteReservation({
    required String userId,
    required String reservationId,
  }) async {
    try {
      print("Rezervasyon silme işlemi başlatılıyor...");
      print("userId: $userId, reservationId: $reservationId");

      // Kullanıcı koleksiyonundan rezervasyonu sil
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('reservations')
          .doc(reservationId)
          .delete();

      print("Kullanıcı koleksiyonundan rezervasyon silindi");

      // Genel rezervasyonlar koleksiyonundan da sil
      await _firestore.collection('reservations').doc(reservationId).delete();

      print("Genel rezervasyonlar koleksiyonundan rezervasyon silindi");
      print("Rezervasyon başarıyla silindi: $reservationId");
    } catch (e) {
      print("Rezervasyon silme hatası: $e");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  // Firebase Firestore için izinleri ayarla
  Future<void> setupFirebasePermissions() async {
    try {
      print("Firebase izinleri ayarlanıyor...");

      // Firestore ayarları
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Geliştirme modunda güvenlik kuralı uygulamayı atla (SADECE GELIŞTIRME İÇİN!)
      // NOT: Bu yöntem sadece yerel geliştirme için kullanılmalıdır, üretimde kullanılmamalıdır!
      try {
        await _firestore.enableNetwork();
        print("Firestore ağ bağlantısı etkinleştirildi");
      } catch (e) {
        print("Firestore ağ bağlantısı etkinleştirilirken hata: $e");
      }

      print("Firebase izinleri başarıyla ayarlandı");
      return;
    } catch (e) {
      print("Firebase izinleri ayarlanırken hata: $e");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  // Vücut ölçülerini doğrudan veritabanına kaydet (Sadece Geliştirme İçin!)
  Future<void> saveMeasurementsDirectly({
    required String userId,
    required Map<String, dynamic> measurements,
    required String date,
  }) async {
    try {
      print("saveMeasurementsDirectly başlatılıyor...");

      // Ölçüm verilerini doğrudan measurements koleksiyonuna kaydet
      final CollectionReference measurementsCollection = _firestore.collection(
        'measurements',
      );

      // Firebase izinlerini kontrol etmeden doğrudan kayıt ekleme
      await measurementsCollection.doc(measurements['measurementId']).set({
        ...measurements,
        'userId': userId,
        'saveTime': FieldValue.serverTimestamp(),
      });

      print(
        "Vücut ölçüleri measurements koleksiyonuna doğrudan kaydedildi: ${measurements['measurementId']}",
      );
      return;
    } catch (e) {
      print("Vücut ölçüleri doğrudan kaydedilirken hata: $e");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  // Anonim olarak giriş yap
  Future<UserCredential> signInAnonymously() async {
    try {
      print("Anonim giriş başlatılıyor...");
      final userCredential = await _auth.signInAnonymously();
      print("Anonim giriş başarılı: ${userCredential.user?.uid}");
      return userCredential;
    } catch (e) {
      print("Anonim giriş hatası: $e");
      rethrow;
    }
  }

  // Başlangıç koleksiyonlarını oluştur
  Future<void> setupInitialCollections() async {
    try {
      print("Başlangıç koleksiyonları oluşturuluyor...");

      // Kullanıcı kimliğini al
      final userId = currentUser?.uid;
      if (userId == null) {
        print("Kullanıcı giriş yapmamış, koleksiyonlar oluşturulamaz");
        return;
      }

      // Koleksiyonları test amaçlı oluştur
      final testData = {
        'test': true,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      };

      // Koleksiyonları oluştur
      final collections = [
        'measurements',
        'measurements_direct',
        'users/$userId/measurements',
        'users/$userId/profile',
      ];

      for (final collectionPath in collections) {
        try {
          if (collectionPath.contains('/')) {
            // Alt koleksiyonlar için
            final parts = collectionPath.split('/');
            if (parts.length == 3) {
              await _firestore
                  .collection(parts[0])
                  .doc(parts[1])
                  .collection(parts[2])
                  .doc('test_doc')
                  .set(testData);
            }
          } else {
            // Ana koleksiyonlar için
            await _firestore
                .collection(collectionPath)
                .doc('test_doc')
                .set(testData);
          }
          print("$collectionPath koleksiyonu oluşturuldu");
        } catch (e) {
          print("$collectionPath koleksiyonu oluşturulurken hata: $e");
        }
      }

      print("Başlangıç koleksiyonları başarıyla oluşturuldu");
    } catch (e) {
      print("Başlangıç koleksiyonları oluşturulurken hata: $e");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  // Vücut ölçülerini güncelleme
  Future<void> updateBodyMeasurements({
    required String userId,
    required Map<String, dynamic> measurements,
    required String measurementId,
  }) async {
    try {
      print("updateBodyMeasurements başlatılıyor...");
      print("userId: $userId");
      print("measurementId: $measurementId");

      // Genel measurements koleksiyonundaki dökümanı güncelle
      try {
        await _firestore
            .collection('measurements')
            .doc(measurementId)
            .update(measurements);
        print(
          "Genel measurements koleksiyonunda döküman güncellendi: $measurementId",
        );
      } catch (e) {
        print("Genel measurements koleksiyonunda güncelleme hatası: $e");
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }
      }

      // Kullanıcıya özel measurements koleksiyonundaki dökümanı güncelle
      try {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('measurements')
            .doc(measurementId)
            .update(measurements);
        print(
          "Kullanıcı measurements koleksiyonunda döküman güncellendi: $measurementId",
        );
      } catch (e) {
        print("Kullanıcı measurements koleksiyonunda güncelleme hatası: $e");
        if (e is FirebaseException) {
          print("Firebase hata kodu: ${e.code}");
          print("Firebase hata mesajı: ${e.message}");
        }
        throw e;
      }

      print("Vücut ölçüleri başarıyla güncellendi");
    } catch (e) {
      print("Vücut ölçüleri güncellenirken hata: $e");
      print("Hata detayı: ${e.toString()}");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");
      }
      rethrow;
    }
  }

  // Vücut ölçülerini doğrudan güncelleme (Sadece Geliştirme İçin!)
  Future<void> updateBodyMeasurementsDirectly({
    required String userId,
    required Map<String, dynamic> measurements,
    required String measurementId,
  }) async {
    try {
      print("updateBodyMeasurementsDirectly başlatılıyor...");
      print("userId: $userId");
      print("measurementId: $measurementId");

      // Alternatif koleksiyondaki dökümanı güncelle
      final CollectionReference measurementsCollection = _firestore.collection(
        'measurements_direct',
      );

      // Dökümanı güncelle
      await measurementsCollection.doc(measurementId).update({
        ...measurements,
        'userId': userId,
        'updateTime': FieldValue.serverTimestamp(),
      });

      print("Vücut ölçüleri doğrudan güncellendi: $measurementId");
    } catch (e) {
      print("Vücut ölçüleri doğrudan güncellenirken hata: $e");
      if (e is FirebaseException) {
        print("Firebase hata kodu: ${e.code}");
        print("Firebase hata mesajı: ${e.message}");

        // Döküman bulunamadıysa, yeni döküman oluştur
        if (e.code == 'not-found') {
          print("Döküman bulunamadı, yeni döküman oluşturuluyor...");
          try {
            await _firestore
                .collection('measurements_direct')
                .doc(measurementId)
                .set({
                  ...measurements,
                  'userId': userId,
                  'createTime': FieldValue.serverTimestamp(),
                });
            print("Yeni döküman oluşturuldu: $measurementId");
            return;
          } catch (setError) {
            print("Yeni döküman oluşturulurken hata: $setError");
            throw setError;
          }
        }
      }
      rethrow;
    }
  }

  // Duyurular ile ilgili metodlar
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final querySnapshot = await _firestore.collection('announcements').get();

      return querySnapshot.docs.map((doc) {
        return Announcement.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print("Duyurular getirilirken hata: $e");
      rethrow;
    }
  }

  // Antrenman programları ile ilgili metodlar
  Future<List<TrainingProgram>> getUserTrainingPrograms(String userId) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('trainingProgram')
              .where('uid', isEqualTo: userId)
              .get();

      return querySnapshot.docs.map((doc) {
        return TrainingProgram.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    } catch (e) {
      print("Antrenman programları getirilirken hata: $e");
      rethrow;
    }
  }
}
