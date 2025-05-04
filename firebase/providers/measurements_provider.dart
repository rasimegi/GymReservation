import 'package:flutter/foundation.dart';
import 'package:gym_reservation/firebase/models/measurements_model.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';
import 'package:intl/intl.dart';

class MeasurementsProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  
  List<MeasurementsModel> _measurementsHistory = [];
  MeasurementsModel? _currentMeasurements;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  List<MeasurementsModel> get measurementsHistory => _measurementsHistory;
  MeasurementsModel? get currentMeasurements => _currentMeasurements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Kullanıcının ölçüm geçmişini getir
  Future<void> fetchMeasurementsHistory(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final measurementsData = 
          await _firebaseService.getBodyMeasurementsHistory(userId);
      
      _measurementsHistory = [];
      
      for (var data in measurementsData) {
        _measurementsHistory.add(
          MeasurementsModel.fromFirestore(
            data,
            data['id'] as String,
          ),
        );
      }
      
      // Son ölçümü mevcut ölçüm olarak ayarla (eğer varsa)
      if (_measurementsHistory.isNotEmpty) {
        _currentMeasurements = _measurementsHistory.first;
      }
    } catch (e) {
      _errorMessage = 'Ölçüm geçmişi yüklenirken hata: $e';
      print(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Yeni ölçüm kaydet
  Future<bool> saveMeasurements({
    required String userId,
    required double weight,
    double? height,
    double? chest,
    double? waist,
    double? hip,
    double? arm,
    double? leg,
    double? bodyFatPercentage,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);
      
      // BMI hesapla
      double? bmi;
      if (height != null && height > 0) {
        final heightInMeters = height / 100;
        bmi = weight / (heightInMeters * heightInMeters);
      }
      
      // Ölçüm verisi oluştur
      final measurementsData = {
        'userId': userId,
        'date': now,
        'weight': weight,
        'height': height,
        'chest': chest,
        'waist': waist,
        'hip': hip,
        'arm': arm,
        'leg': leg,
        'bodyFatPercentage': bodyFatPercentage,
        'bmi': bmi,
        'notes': notes,
        'id': dateStr, // ID olarak tarihi kullan
      };
      
      // Veritabanına kaydet
      await _firebaseService.saveBodyMeasurements(
        userId: userId,
        measurements: measurementsData,
        date: dateStr,
      );
      
      // Yeni ölçüm modelini oluştur
      final newMeasurement = MeasurementsModel.fromFirestore(
        measurementsData,
        dateStr,
      );
      
      // Mevcut ölçüm ve ölçüm geçmişini güncelle
      _currentMeasurements = newMeasurement;
      _measurementsHistory.insert(0, newMeasurement);
      
      return true;
    } catch (e) {
      _errorMessage = 'Ölçüm kaydedilirken hata: $e';
      print(_errorMessage);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // İlerleme hesapla (yüzde olarak)
  Map<String, double> calculateProgress() {
    if (_measurementsHistory.length < 2) {
      return {};
    }
    
    // İlk ölçüm (en son kaydedilen)
    final latest = _measurementsHistory.first;
    
    // Son ölçüm (ilk kaydedilen)
    final oldest = _measurementsHistory.last;
    
    Map<String, double> progressMap = {};
    
    // Kilo değişimi
    final weightDiff = oldest.weight - latest.weight;
    final weightPercentage = (weightDiff / oldest.weight) * 100;
    progressMap['weight'] = weightPercentage;
    
    // Bel çevresi değişimi
    if (latest.waist != null && oldest.waist != null) {
      final waistDiff = oldest.waist! - latest.waist!;
      final waistPercentage = (waistDiff / oldest.waist!) * 100;
      progressMap['waist'] = waistPercentage;
    }
    
    // Göğüs çevresi değişimi
    if (latest.chest != null && oldest.chest != null) {
      final chestDiff = oldest.chest! - latest.chest!;
      final chestPercentage = (chestDiff / oldest.chest!) * 100;
      progressMap['chest'] = chestPercentage;
    }
    
    // Kalça çevresi değişimi
    if (latest.hip != null && oldest.hip != null) {
      final hipDiff = oldest.hip! - latest.hip!;
      final hipPercentage = (hipDiff / oldest.hip!) * 100;
      progressMap['hip'] = hipPercentage;
    }
    
    // Vücut yağ oranı değişimi
    if (latest.bodyFatPercentage != null && oldest.bodyFatPercentage != null) {
      final bodyFatDiff = oldest.bodyFatPercentage! - latest.bodyFatPercentage!;
      final bodyFatPercentage = (bodyFatDiff / oldest.bodyFatPercentage!) * 100;
      progressMap['bodyFat'] = bodyFatPercentage;
    }
    
    return progressMap;
  }
} 