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
      print("📊 fetchMeasurementsHistory başlatılıyor: $userId");

      // Veritabanından ölçüm geçmişini al
      final measurementsData = await _firebaseService
          .getBodyMeasurementsHistory(userId);

      print(
        "📊 Veri tabanından alınan ölçüm sayısı: ${measurementsData.length}",
      );

      // Mevcut ölçümleri temizle
      _measurementsHistory = [];

      // Hiç veri yoksa
      if (measurementsData.isEmpty) {
        print("📊 Kullanıcı için hiç ölçüm verisi bulunamadı");
        _currentMeasurements = null;
        notifyListeners();
        return;
      }

      // Verileri model listesine dönüştür
      for (var data in measurementsData) {
        final String docId =
            data['measurementId'] ??
            data['id'] ??
            "unknown_${DateTime.now().millisecondsSinceEpoch}";

        print("📊 Ölçüm ekleniyor: $docId");
        print(
          "📊 Ölçüm tarihi: ${data['mDate']}, Güncelleme: ${data['updatedAt']}",
        );
        print(
          "📊 Ölçüm değerleri - Kilo: ${data['weight']}, Boy: ${data['height']}",
        );

        // Eksik alanları kontrol et ve varsayılan değerlerle doldur
        data = _ensureRequiredFields(data, userId);

        // Listeye ekle
        _measurementsHistory.add(MeasurementsModel.fromFirestore(data, docId));
      }

      // Tarihleri karşılaştırmak için yardımcı fonksiyon
      DateTime _parseDate(String dateStr) {
        try {
          // ISO 8601 formatındaki string'i DateTime'a çevir
          return DateTime.parse(dateStr);
        } catch (e) {
          // Hata durumunda bugünün tarihini kullan
          return DateTime.now();
        }
      }

      // Verileri güncellenme tarihine göre sırala (en yeni en üstte)
      _measurementsHistory.sort((a, b) {
        try {
          // Önce updatedAt alanını kontrol et (daha kesin ve zaman bilgisini içerir)
          if (a.updatedAt != null && b.updatedAt != null) {
            final DateTime dateA = _parseDate(a.updatedAt!);
            final DateTime dateB = _parseDate(b.updatedAt!);
            return dateB.compareTo(dateA); // En yeni en üstte
          }

          // Eğer updatedAt yoksa veya geçersizse, mDate kullan
          final DateTime dateA = _parseDate(a.mDate);
          final DateTime dateB = _parseDate(b.mDate);
          return dateB.compareTo(dateA); // En yeni en üstte
        } catch (e) {
          print("❌ Tarihleri sıralama hatası: $e");
          return 0; // Sıralama yapılamıyorsa mevcut sırayı koru
        }
      });

      // Sıralanmış ilk 3 ölçümü log'la
      if (_measurementsHistory.isNotEmpty) {
        print("📊 SIRALANMIŞ ÖLÇÜMLER (EN YENİDEN ESKİYE):");
        for (int i = 0; i < _measurementsHistory.length && i < 3; i++) {
          final measurement = _measurementsHistory[i];
          print(
            "📊 #${i + 1}: ${measurement.measurementId} | Tarih: ${measurement.mDate} | Güncelleme: ${measurement.updatedAt}",
          );
          print(
            "📊 #${i + 1}: Kilo: ${measurement.weight}, Boy: ${measurement.height}",
          );
        }
      }

      // Son ölçümü mevcut ölçüm olarak ayarla (eğer varsa)
      if (_measurementsHistory.isNotEmpty) {
        _currentMeasurements = _measurementsHistory.first;
        print(
          "✅ Mevcut ölçüm olarak ayarlandı: ${_currentMeasurements?.measurementId}",
        );
        print("📅 Mevcut ölçüm tarihi: ${_currentMeasurements?.mDate}");
        print(
          "⏱️ Mevcut ölçüm güncelleme tarihi: ${_currentMeasurements?.updatedAt}",
        );
        print(
          "⚖️ Mevcut ölçüm değerleri - Kilo: ${_currentMeasurements?.weight}, Boy: ${_currentMeasurements?.height}",
        );
      } else {
        _currentMeasurements = null;
        print("❌ Mevcut ölçüm bulunamadı");
      }
    } catch (e) {
      _errorMessage = 'Ölçüm geçmişi yüklenirken hata: $e';
      print("❌ $_errorMessage");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Eksik alanları kontrol eder ve varsayılan değerlere tamamlar
  Map<String, dynamic> _ensureRequiredFields(
    Map<String, dynamic> data,
    String userId,
  ) {
    // Zorunlu alanlar için varsayılan değerler
    Map<String, dynamic> result = Map.from(data);

    // MeasurementId kontrolü
    if (!result.containsKey('measurementId')) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      result['measurementId'] = result['id'] ?? 'meas_${timestamp}_1';
    }

    // UserId kontrolü
    if (!result.containsKey('userId')) {
      result['userId'] = userId;
    }

    // mDate kontrolü
    if (!result.containsKey('mDate')) {
      result['mDate'] = DateTime.now().toIso8601String().split('T')[0];
    }

    // Sayısal alanlar
    final requiredDoubleFields = [
      'weight',
      'height',
      'chest',
      'waist',
      'hip',
      'arm',
      'thigh',
      'shoulder',
      'age',
    ];

    for (var field in requiredDoubleFields) {
      if (!result.containsKey(field) || result[field] == null) {
        result[field] = 0.0;
      } else if (result[field] is int) {
        result[field] = (result[field] as int).toDouble();
      }
    }

    // Metin alanları
    if (!result.containsKey('gender') || result['gender'] == null) {
      result['gender'] = 'Belirtilmemiş';
    }

    if (!result.containsKey('goal') || result['goal'] == null) {
      result['goal'] = 'Belirtilmemiş';
    }

    if (!result.containsKey('activityLevel') ||
        result['activityLevel'] == null) {
      result['activityLevel'] = 'Orta Seviye';
    }

    return result;
  }

  // Yeni ölçüm kaydet veya mevcut ölçümü güncelle
  Future<bool> saveMeasurements({
    required String userId,
    required double weight,
    required double height,
    required double chest,
    required double waist,
    required double hip,
    required double arm,
    required double thigh,
    required double shoulder,
    required double age,
    required String gender,
    required String goal,
    required String activityLevel,
    required String measurementId,
    required String mDate,
    String? updatedAt,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // BMI hesapla
      double bmi = 0;
      if (height > 0) {
        final heightInMeters = height / 100;
        bmi = weight / (heightInMeters * heightInMeters);
      }

      // Ölçüm verisi oluştur
      final measurementsData = {
        'userId': userId,
        'measurementId': measurementId,
        'mDate': mDate,
        'weight': weight,
        'height': height,
        'chest': chest,
        'waist': waist,
        'hip': hip,
        'arm': arm,
        'thigh': thigh,
        'shoulder': shoulder,
        'age': age,
        'gender': gender,
        'goal': goal,
        'activityLevel': activityLevel,
        'bmi': bmi,
        'updatedAt':
            updatedAt ?? DateTime.now().toIso8601String(), // Güncellenme zamanı
      };

      // Önce mevcut ölçümleri kontrol et
      print("Mevcut ölçümler kontrol ediliyor...");
      await fetchMeasurementsHistory(userId);

      // Eğer bugün için bir ölçüm zaten kaydedilmişse, üzerine yaz
      String docId = measurementId; // Varsayılan olarak yeni ID kullan
      bool isUpdate = false;

      // Eğer ölçüm geçmişi doluysa, bugün için bir ölçüm var mı kontrol et
      if (_measurementsHistory.isNotEmpty) {
        // Bugünkü tarihi kullanarak arama yap
        final today = DateTime.now();
        final todayStr =
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

        print("Bugünün tarihi: $todayStr için ölçüm aranıyor...");

        // Bugünün tarihiyle eşleşen ölçüm var mı?
        for (var measurement in _measurementsHistory) {
          // Karşılaştırma yapmak için tarihin sadece gün kısmını al (saat olmadan)
          final measurementDate =
              measurement.mDate.split(' ')[0]; // Eğer saat bilgisi varsa ayır

          print(
            "Kontrol edilen ölçüm: $measurementDate | ID: ${measurement.measurementId}",
          );

          if (measurementDate == todayStr || measurementDate == mDate) {
            docId = measurement.measurementId;
            isUpdate = true;
            print(
              "Bugün için bir ölçüm bulundu: $docId - Güncelleme yapılacak",
            );
            break;
          }
        }
      }

      print(
        isUpdate
            ? "Mevcut dökümanı güncelleme: $docId"
            : "Yeni döküman oluşturma: $docId",
      );

      // Veritabanına kaydetmeyi dene - Her iki yöntemi de kullan
      try {
        // Her iki yöntemi de dene, ilk olarak doğrudan measurements koleksiyonuna kaydet
        print("Doğrudan measurements koleksiyonuna kaydetme deneniyor...");
        await _firebaseService.saveMeasurementsDirectly(
          userId: userId,
          measurements: measurementsData,
          date: mDate,
        );
        print(
          "Ölçümler doğrudan measurements koleksiyonuna kaydedildi: $measurementId",
        );

        // Şimdi de standart yöntemi dene
        try {
          if (isUpdate) {
            // Mevcut dökümanı güncelle
            await _firebaseService.updateBodyMeasurements(
              userId: userId,
              measurements: measurementsData,
              measurementId: docId,
            );
            print("Ölçümler standart yöntemle de güncellendi: $docId");
          } else {
            // Yeni döküman oluştur
            await _firebaseService.saveBodyMeasurements(
              userId: userId,
              measurements: measurementsData,
              date: mDate,
            );
            print("Ölçümler standart yöntemle de kaydedildi: $measurementId");
          }
        } catch (standardError) {
          print(
            "Standart yöntemle kaydetme başarısız oldu, ancak sorun değil çünkü doğrudan kaydedildi: $standardError",
          );
        }
      } catch (e) {
        print("Tüm kaydetme yöntemleri başarısız oldu: $e");
        throw e; // Tüm yöntemler başarısız olursa hatayı ilet
      }

      // Yeni ölçüm modelini oluştur
      final newMeasurement = MeasurementsModel.fromFirestore(
        measurementsData,
        isUpdate ? docId : measurementId,
      );

      // Ölçüm listesini güncelle
      if (isUpdate) {
        // Mevcut ölçümü güncelle
        int index = _measurementsHistory.indexWhere(
          (m) => m.measurementId == docId,
        );
        if (index >= 0) {
          _measurementsHistory[index] = newMeasurement;
        } else {
          _measurementsHistory.insert(0, newMeasurement);
        }
      } else {
        // Yeni ölçümü ekle
        _measurementsHistory.insert(0, newMeasurement);
      }

      // Mevcut ölçümü güncelle
      _currentMeasurements = newMeasurement;

      // Ölçüm verilerini yeniden yükle
      await fetchMeasurementsHistory(userId);

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
    final waistDiff = oldest.waist - latest.waist;
    final waistPercentage = (waistDiff / oldest.waist) * 100;
    progressMap['waist'] = waistPercentage;

    // Göğüs çevresi değişimi
    final chestDiff = oldest.chest - latest.chest;
    final chestPercentage = (chestDiff / oldest.chest) * 100;
    progressMap['chest'] = chestPercentage;

    // Kalça çevresi değişimi
    final hipDiff = oldest.hip - latest.hip;
    final hipPercentage = (hipDiff / oldest.hip) * 100;
    progressMap['hip'] = hipPercentage;

    // Kol çevresi değişimi
    final armDiff = oldest.arm - latest.arm;
    final armPercentage = (armDiff / oldest.arm) * 100;
    progressMap['arm'] = armPercentage;

    // Uyluk çevresi değişimi
    final thighDiff = oldest.thigh - latest.thigh;
    final thighPercentage = (thighDiff / oldest.thigh) * 100;
    progressMap['thigh'] = thighPercentage;

    // Omuz çevresi değişimi
    final shoulderDiff = oldest.shoulder - latest.shoulder;
    final shoulderPercentage = (shoulderDiff / oldest.shoulder) * 100;
    progressMap['shoulder'] = shoulderPercentage;

    return progressMap;
  }

  // Ölçüm verilerini temizle
  void clearMeasurements() {
    _measurementsHistory = [];
    _currentMeasurements = null;
    _errorMessage = null;
    notifyListeners();
    print("Ölçüm verileri temizlendi");
  }
}
