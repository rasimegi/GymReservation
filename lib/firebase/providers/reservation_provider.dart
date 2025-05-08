import 'package:flutter/foundation.dart';
import 'package:gym_reservation/firebase/models/reservation_model.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';

class ReservationProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<ReservationModel> _userReservations = [];
  List<String> _reservedTimeSlots = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ReservationModel> get userReservations => _userReservations;
  List<String> get reservedTimeSlots => _reservedTimeSlots;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Kullanıcının rezervasyonlarını getir
  Future<void> fetchUserReservations(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print("fetchUserReservations başlatılıyor... userId: $userId");
      final reservationsData = await _firebaseService.getUserReservations(
        userId,
      );

      print(
        "Firebase'den gelen rezervasyon sayısı: ${reservationsData.length}",
      );

      _userReservations = [];

      for (var data in reservationsData) {
        print("Dönüştürülen rezervasyon verisi: $data");

        String reservationId =
            data['reservationId'] ?? '${data['date']}_${data['timeSlot']}';
        print("Kullanılan reservationId: $reservationId");

        _userReservations.add(
          ReservationModel.fromFirestore(data, reservationId),
        );
      }

      print(
        "Oluşturulan rezervasyon modeli sayısı: ${_userReservations.length}",
      );

      // Tarihe göre sırala (yaklaşan rezervasyonlar önce)
      _userReservations.sort((a, b) => a.date.compareTo(b.date));

      print(
        "Sıralanmış rezervasyonlar: ${_userReservations.map((r) => r.date).toList()}",
      );
    } catch (e) {
      _errorMessage = 'Rezervasyonlar yüklenirken hata: $e';
      print("HATA: $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Belirli bir tarihteki rezerve edilmiş saat aralıklarını getir
  Future<void> fetchReservedTimeSlots(String date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _reservedTimeSlots = await _firebaseService.getReservedTimeSlots(date);
    } catch (e) {
      _errorMessage = 'Rezerve edilmiş saatler yüklenirken hata: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Yeni rezervasyon oluştur
  Future<bool> createReservation({
    required String userId,
    required String date,
    required String timeSlot,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Saat aralığı zaten rezerve edilmiş mi kontrol et
      await fetchReservedTimeSlots(date);

      if (_reservedTimeSlots.contains(timeSlot)) {
        _errorMessage = 'Bu saat aralığı zaten rezerve edilmiş';
        return false;
      }

      // Şu anki tarih ve saat (YYYY-MM-DD formatında)
      final now = DateTime.now();
      final createdAtStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      // Benzersiz bir rezervasyon ID'si oluştur
      final timestamp = now.millisecondsSinceEpoch;
      final reservationId = "res_${timestamp}_1";

      // Rezervasyon verisi oluştur
      final reservationData = {
        'date': date,
        'timeSlot': timeSlot,
        'createdAt': createdAtStr,
        'reservationId': reservationId,
        'notes': notes,
        'isActive': true, // Aktif rezervasyon olarak işaretle
      };

      // Rezervasyonu kaydet
      await _firebaseService.createReservation(
        userId: userId,
        reservationData: reservationData,
      );

      // Kullanıcının rezervasyonlarını güncelle
      await fetchUserReservations(userId);

      return true;
    } catch (e) {
      _errorMessage = 'Rezervasyon oluşturulurken hata: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Rezervasyon iptal et
  Future<bool> cancelReservation({
    required String userId,
    required String reservationId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Rezervasyonu silmek yerine, isActive değerini false olarak güncelle
      await _firebaseService.updateReservationStatus(
        userId: userId,
        reservationId: reservationId,
        isActive: false,
      );

      // Kullanıcının rezervasyonlarını güncelle
      await fetchUserReservations(userId);

      return true;
    } catch (e) {
      _errorMessage = 'Rezervasyon iptal edilirken hata: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Belirli bir tarihteki zaman aralığının uygun olup olmadığını kontrol et
  bool isTimeSlotAvailable(String timeSlot) {
    return !_reservedTimeSlots.contains(timeSlot);
  }

  // Rezervasyonu tamamen sil
  Future<bool> deleteReservation({
    required String userId,
    required String reservationId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Rezervasyonu veritabanından tamamen sil
      await _firebaseService.deleteReservation(
        userId: userId,
        reservationId: reservationId,
      );

      // Kullanıcının rezervasyonlarını güncelle
      await fetchUserReservations(userId);

      return true;
    } catch (e) {
      _errorMessage = 'Rezervasyon silinirken hata: $e';
      print("HATA: $_errorMessage");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
