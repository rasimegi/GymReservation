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
      final reservationsData = await _firebaseService.getUserReservations(userId);
      
      _userReservations = [];
      
      for (var data in reservationsData) {
        _userReservations.add(
          ReservationModel.fromFirestore(
            data,
            '${data['date']}_${data['timeSlot']}',
          ),
        );
      }
      
      // Tarihe göre sırala (yaklaşan rezervasyonlar önce)
      _userReservations.sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      _errorMessage = 'Rezervasyonlar yüklenirken hata: $e';
      print(_errorMessage);
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
      
      // Rezervasyon verisi oluştur
      final reservationData = {
        'date': date,
        'timeSlot': timeSlot,
        'status': 'onaylandı',
        'createdAt': DateTime.now(),
        'notes': notes,
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
      await _firebaseService.cancelReservation(
        userId: userId,
        reservationId: reservationId,
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
} 