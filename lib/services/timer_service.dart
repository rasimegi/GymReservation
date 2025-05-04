import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class TimerService {
  static final TimerService _instance = TimerService._internal();

  factory TimerService() {
    return _instance;
  }

  TimerService._internal();

  // Timer değişkenleri
  Timer? timer;
  bool isRunning = false;
  int duration = 0;
  int selectedDuration = 0;
  int lastMinute = 0;
  int secondCounter = 0;
  DateTime? lastTimerUpdate;
  bool hasFirstMinutePassed = false; // İlk dakika geçiş durumu

  // İstatistikler
  int totalMinutes = 0;
  int calories = 0;
  List<int> dailyMinutes = [0, 0, 0, 0, 0, 0, 0];
  List<int> dailyCalories = [0, 0, 0, 0, 0, 0, 0];
  int todayIndex = 0;
  String lastActiveDate = '';

  // Callback fonksiyonu
  Function()? onTimerUpdate;

  // Timer'ı başlat
  void startTimer() {
    if (selectedDuration == 0 || duration == 0) return;

    isRunning = true;

    // Timer'ı iptal et eğer varsa
    timer?.cancel();

    // Son güncelleme zamanını ayarla
    lastTimerUpdate = DateTime.now();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (duration > 0) {
        duration--;
        secondCounter++;

        // Son güncelleme zamanını güncelle
        lastTimerUpdate = DateTime.now();

        // Her 7 saniyede bir kalori artır (ilk periyot tamamlandıktan sonra)
        if (secondCounter >= 7 && secondCounter % 7 == 0) {
          calories++;
          dailyCalories[todayIndex] = calories;
          saveStats();
        }

        // Dakika değişimini kontrol et
        int currentMinute = duration ~/ 60;

        // Dakika değişimi olduysa
        if (currentMinute < lastMinute) {
          if (hasFirstMinutePassed) {
            // İlk dakika geçtiyse total minutes'ı artır
            totalMinutes++;
            dailyMinutes[todayIndex] = totalMinutes;
            saveStats();
          } else {
            // İlk dakika geçişini işaretle
            hasFirstMinutePassed = true;
          }
          lastMinute = currentMinute;
        }
      } else {
        // Süre bittiğinde ve ilk dakika geçtiyse total minutes değerini artır
        if (duration == 0 && hasFirstMinutePassed) {
          totalMinutes++;
          dailyMinutes[todayIndex] = totalMinutes;
          saveStats();
        }
        stopTimer();
      }

      // Timer durumunu kaydet
      saveTimerState();

      // UI güncelleme için callback çağır
      if (onTimerUpdate != null) {
        onTimerUpdate!();
      }
    });

    saveTimerState();
  }

  // Timer'ı durdur
  void stopTimer() {
    isRunning = false;
    timer?.cancel();
    timer = null;
    saveTimerState();

    // UI güncelleme için callback çağır
    if (onTimerUpdate != null) {
      onTimerUpdate!();
    }
  }

  // Timer'ı sıfırla
  void resetTimer() {
    stopTimer();
    duration = selectedDuration * 60;
    lastMinute = duration ~/ 60;
    secondCounter = 0;
    hasFirstMinutePassed = false;
    saveTimerState();

    // UI güncelleme için callback çağır
    if (onTimerUpdate != null) {
      onTimerUpdate!();
    }
  }

  // Timer'ı sürdür (gerekirse)
  void resumeTimerIfNeeded() {
    if (isRunning && duration > 0) {
      // Eğer uygulama kapalıyken geçen süreyi hesapla
      if (lastTimerUpdate != null) {
        final now = DateTime.now();
        final diff = now.difference(lastTimerUpdate!).inSeconds;

        // Eğer zaman geçmişse
        if (diff > 0) {
          // Orijinal değerleri kopyala
          final oldDuration = duration;
          final oldMinute = oldDuration ~/ 60;

          // Yeni süreyi hesapla
          duration = (duration - diff) > 0 ? (duration - diff) : 0;
          final newMinute = duration ~/ 60;

          // Geçen dakikaları hesapla
          int minutesPassed = oldMinute - newMinute;

          // Eğer dakika geçişi olduysa ve ilk dakika zaten geçmişse
          if (minutesPassed > 0 && hasFirstMinutePassed) {
            totalMinutes += minutesPassed;
            dailyMinutes[todayIndex] = totalMinutes;
            saveStats();
          }
          // İlk dakika henüz geçmediyse ve şimdi geçiyorsa
          else if (!hasFirstMinutePassed && oldMinute > newMinute) {
            hasFirstMinutePassed = true;
          }

          // Son dakikayı güncelle
          lastMinute = newMinute;

          // Eğer süre bittiyse
          if (duration <= 0) {
            // Süre bittiyse ve ilk dakika geçtiyse
            if (hasFirstMinutePassed) {
              totalMinutes++;
              dailyMinutes[todayIndex] = totalMinutes;
              saveStats();
            }
            stopTimer();
            return;
          }
        }
      }

      // Timer'ı tekrar başlat
      startTimer();
    }
  }

  // Timer durumunu kaydet
  Future<void> saveTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('timerRunning', isRunning);
      await prefs.setInt('timerDuration', duration);
      await prefs.setInt('timerSelectedDuration', selectedDuration);
      await prefs.setInt('timerLastMinute', lastMinute);
      await prefs.setInt('timerSecondCounter', secondCounter);
      await prefs.setBool('hasFirstMinutePassed', hasFirstMinutePassed);

      // Son güncelleme zamanını kaydet
      if (isRunning) {
        await prefs.setString(
          'timerLastUpdate',
          DateTime.now().toIso8601String(),
        );
      }
    } catch (e) {
      print('Zamanlayıcı durumu kaydedilirken hata: $e');
    }
  }

  // Timer durumunu yükle
  Future<void> loadTimerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isRunning = prefs.getBool('timerRunning') ?? false;
      duration = prefs.getInt('timerDuration') ?? 0;
      selectedDuration = prefs.getInt('timerSelectedDuration') ?? 0;
      lastMinute = prefs.getInt('timerLastMinute') ?? 0;
      secondCounter = prefs.getInt('timerSecondCounter') ?? 0;
      hasFirstMinutePassed = prefs.getBool('hasFirstMinutePassed') ?? false;

      // Son güncelleme zamanını al
      final lastUpdateStr = prefs.getString('timerLastUpdate');
      if (lastUpdateStr != null) {
        lastTimerUpdate = DateTime.parse(lastUpdateStr);
      }
    } catch (e) {
      print('Zamanlayıcı durumu yüklenirken hata: $e');
    }
  }

  // İstatistikleri kaydet
  Future<void> saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Son aktif tarihi kaydet
      await prefs.setString('lastActiveDate', lastActiveDate);

      // Total değerleri kaydet
      await prefs.setInt('totalMinutes', totalMinutes);
      await prefs.setInt('calories', calories);

      // Her gün için dakika ve kalori değerlerini kaydet
      for (int i = 0; i < 7; i++) {
        await prefs.setInt('dailyMinutes_$i', dailyMinutes[i]);
        await prefs.setInt('dailyCalories_$i', dailyCalories[i]);
      }
    } catch (e) {
      print('İstatistikler kaydedilirken hata: $e');
    }
  }

  // İstatistikleri yükle
  Future<void> loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Son aktif tarihi yükle
      lastActiveDate = prefs.getString('lastActiveDate') ?? '';

      // Total değerleri yükle
      totalMinutes = prefs.getInt('totalMinutes') ?? 0;
      calories = prefs.getInt('calories') ?? 0;

      // Her gün için dakika ve kalori değerlerini yükle
      for (int i = 0; i < 7; i++) {
        dailyMinutes[i] = prefs.getInt('dailyMinutes_$i') ?? 0;
        dailyCalories[i] = prefs.getInt('dailyCalories_$i') ?? 0;
      }
    } catch (e) {
      print('İstatistikler yüklenirken hata: $e');
    }
  }

  // Bugünün indeksini belirle ve gerekirse sıfırla
  void setTodayIndex() {
    final now = DateTime.now();
    // Haftanın günü (1: Pazartesi, 7: Pazar) -> (0-6 indeksine çevir)
    todayIndex = now.weekday - 1;

    // Bugünün tarihini kontrol et ve gerekirse sıfırla
    final today = "${now.year}-${now.month}-${now.day}";

    // Eğer son aktif tarih boşsa (ilk çalıştırma), bugünün tarihini kaydet
    if (lastActiveDate.isEmpty) {
      lastActiveDate = today;
      saveStats();
      return;
    }

    // Farklı bir güne geçiş olmuşsa
    if (lastActiveDate != today) {
      try {
        // Son aktif tarihi parse et
        final lastDate = DateTime.parse(lastActiveDate);
        final currentDate = DateTime.parse(today);

        // İki tarih arasındaki farkı hesapla
        final difference = currentDate.difference(lastDate).inDays;

        // Eğer yeni bir haftaya başlandıysa (7 gün veya daha fazla geçtiyse ya da Pazartesi gününe geçildiyse)
        if (difference >= 7 || now.weekday == 1) {
          // Tüm haftalık veriler sıfırlanır
          dailyMinutes = List.filled(7, 0);
          dailyCalories = List.filled(7, 0);
          print("Hafta değişti! Tüm veriler sıfırlandı.");
        }

        // Bugün için verileri sıfırla
        totalMinutes = 0;
        calories = 0;
        lastActiveDate = today;
        saveStats();
      } catch (e) {
        print("Tarih hesaplamasında hata: $e");
        lastActiveDate = today;
        saveStats();
      }
    }
  }

  // Saniyeyi dakika:saniye formatına dönüştür
  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Debug bilgisi yazdır
  void printDebugInfo() {
    print("==== Timer Service Debug ====");
    print("isRunning: $isRunning");
    print("duration: $duration");
    print("selectedDuration: $selectedDuration");
    print("lastMinute: $lastMinute");
    print("hasFirstMinutePassed: $hasFirstMinutePassed");
    print("totalMinutes: $totalMinutes");
    print("todayIndex: $todayIndex");
    print("===========================");
  }
}
