import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_reservation/view/reservation_screen.dart';
import 'package:gym_reservation/view/profile_screen.dart';
import 'package:gym_reservation/services/timer_service.dart';
import 'dart:async';
import 'package:gym_reservation/utils/page_transition.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _completedDays = 0;
  int _targetDays = 7;
  List<bool> _dayStatus = [false, false, false, false, false, false, false];

  // Timer servisi
  final TimerService _timerService = TimerService();

  // Günlük istatistikler için değişkenler
  int _selectedDay = -1; // Seçilen gün indeksi (-1 seçim yok demek)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDayStatus();
    _initializeTimerService();
  }

  // Timer servisini başlat
  Future<void> _initializeTimerService() async {
    // Timer güncellendiğinde UI'ı güncelle
    _timerService.onTimerUpdate = () {
      if (mounted) {
        setState(() {});
      }
    };

    // İstatistikleri yükle
    await _timerService.loadStats();

    // Timer durumunu yükle
    await _timerService.loadTimerState();

    // Bugünün indeksini ayarla
    _timerService.setTodayIndex();

    // Eğer timer çalışıyorsa devam ettir
    _timerService.resumeTimerIfNeeded();

    // UI'ı güncelle
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Uygulama arka plana alındığında timer durumunu kaydet
      _timerService.saveTimerState();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar açıldığında timer'ı kontrol et
      _timerService.resumeTimerIfNeeded();

      // UI'ı güncelle
      setState(() {});
    }
  }

  // Kayıtlı durumu yükle
  Future<void> _loadDayStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Son sıfırlama tarihini kontrol et
      final lastResetStr = prefs.getString('lastReset');
      if (lastResetStr != null) {
        final lastReset = DateTime.parse(lastResetStr);
        final now = DateTime.now();

        // Eğer yeni bir hafta başladıysa, durumları sıfırla
        if (now.difference(lastReset).inDays >= 7) {
          await _resetWeek();
          return;
        }
      } else {
        // İlk çalıştırma, tarihi kaydet
        await prefs.setString('lastReset', DateTime.now().toIso8601String());
      }

      // Gün durumlarını ve tamamlanan gün sayısını yükle
      setState(() {
        _completedDays = prefs.getInt('completedDays') ?? 0;

        for (int i = 0; i < 7; i++) {
          _dayStatus[i] = prefs.getBool('day_$i') ?? false;
        }
      });
    } catch (e) {
      // Hata durumunda varsayılan değerleri kullan
      print('Veri yüklenirken hata: $e');
    }
  }

  // Durumu kaydet
  Future<void> _saveDayStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Tamamlanan gün sayısını kaydet
      await prefs.setInt('completedDays', _completedDays);

      // Her günün durumunu kaydet
      for (int i = 0; i < 7; i++) {
        await prefs.setBool('day_$i', _dayStatus[i]);
      }
    } catch (e) {
      print('Veri kaydedilirken hata: $e');
    }
  }

  // Haftayı sıfırla
  Future<void> _resetWeek() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Son sıfırlama tarihini güncelle
      await prefs.setString('lastReset', DateTime.now().toIso8601String());

      setState(() {
        _completedDays = 0;
        _dayStatus = List.filled(7, false);
      });

      // Sıfırlanan değerleri kaydet
      await _saveDayStatus();
    } catch (e) {
      print('Hafta sıfırlanırken hata: $e');
    }
  }

  // Gün durumunu değiştir
  void _toggleDayStatus(int index) {
    setState(() {
      // Eğer gün tamamlanmadıysa, tamamlandı olarak işaretle
      if (!_dayStatus[index]) {
        _dayStatus[index] = true;
        _completedDays++;
      } else {
        // Eğer gün zaten tamamlandıysa, tamamlanmadı olarak işaretle
        _dayStatus[index] = false;
        _completedDays--;
      }
    });

    // Değişiklikleri kaydet
    _saveDayStatus();
  }

  // Süre seçme dialog'unu göster
  void _showDurationPicker(BuildContext context) {
    final durationOptions = [2, 30, 45, 60, 90];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1F26),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Süre Seç',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children:
                      durationOptions.map((duration) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _timerService.selectedDuration = duration;
                              _timerService.duration =
                                  duration * 60; // Dakikaları saniyelere çevir
                              _timerService.lastMinute =
                                  _timerService.duration ~/
                                  60; // Başlangıç dakikasını sakla
                              _timerService.saveTimerState();
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B0E14),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFF339DFF).withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '$duration',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'dakika',
                                  style: TextStyle(
                                    color: Color(0xFFBFC6D2),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF339DFF),
                    backgroundColor: const Color(0xFF0B0E14),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('İptal', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> dayLetters = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Merhabalar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Spacer(),
            // Zamanlayıcı durumunu yazdırmak için debug butonu
            IconButton(
              icon: const Icon(Icons.bug_report, color: Colors.red),
              onPressed: () {
                _timerService.printDebugInfo();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debug bilgileri konsola yazdırıldı'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Spor günü yazısı
              const Text(
                'Spor yapmak için harika bir gün!',
                style: TextStyle(color: Color(0xFFBFC6D2), fontSize: 16),
              ),
              const SizedBox(height: 20),

              // Haftanın günleri
              SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Günler için tıklanabilir butonlar
                    for (int i = 0; i < 7; i++)
                      _buildDayCircle(
                        dayLetters[i],
                        _dayStatus[i],
                        index: i,
                        onTap: () => _toggleDayStatus(i),
                      ),

                    // Hedef sayısı
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'HEDEF',
                          style: TextStyle(
                            color: Color(0xFFBFC6D2),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$_completedDays / $_targetDays',
                          style: const TextStyle(
                            color: Color(0xFFBFC6D2),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Günlük Takvim Kartı (yatayda genişletilmiş)
              Container(
                width: double.infinity,
                height: 105,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F26),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'ANTRENMAN PROGRAMI',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bugün kayıtlı programın yok',
                      style: TextStyle(color: Color(0xFFBFC6D2), fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Adım sayısı grafiği
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1F26),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: Colors.white.withOpacity(0.8),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Haftalık Aktivite',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          '${_timerService.totalMinutes}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'total minutes',
                          style: TextStyle(
                            color: Color(0xFFBFC6D2),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final days = ['Pt', 'S', 'Ç', 'P', 'C', 'Ct', 'P'];
                        // Bugünün sütununun vurgulanması için
                        final isToday = index == _timerService.todayIndex;

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDay =
                                      _selectedDay == index ? -1 : index;
                                });
                              },
                              child: Container(
                                width: 15,
                                height:
                                    110 *
                                    (_timerService.dailyMinutes[index] == 0
                                        ? 0.10 // 0 iken %10 boyut
                                        : (_timerService.dailyMinutes[index] *
                                                    0.01) +
                                                0.10 >
                                            1.0
                                        ? 1.0 // Maksimum %100
                                        : (_timerService.dailyMinutes[index] *
                                                0.01) +
                                            0.10 // Her 1 artışta %1 artış + başlangıç %10
                                            ),
                                decoration: BoxDecoration(
                                  color:
                                      isToday
                                          ? Colors.greenAccent.withOpacity(
                                            0.7,
                                          ) // Bugünün rengi farklı olsun
                                          : const Color(0xFFB0E5F3).withOpacity(
                                            _timerService.dailyMinutes[index] >
                                                    0
                                                ? 0.4 +
                                                    (_timerService
                                                            .dailyMinutes[index] /
                                                        120)
                                                : 0.3,
                                          ),
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      isToday
                                          ? Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          )
                                          : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              days[index],
                              style: TextStyle(
                                color:
                                    isToday
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.6),
                                fontSize: 14,
                                fontWeight:
                                    isToday
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),

                    // Seçilen gün için bilgi kutusu
                    if (_selectedDay >= 0 && _selectedDay < 7)
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0E14),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFFBFC6D2),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Total Minutes: ${_timerService.dailyMinutes[_selectedDay]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Color(0xFFBFC6D2),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Calories: ${_timerService.dailyCalories[_selectedDay]}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Kalori ve süre
              Row(
                children: [
                  // Kalori
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1F26),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_fire_department,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Calories',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Text(
                                '${_timerService.calories}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'kcal',
                                style: TextStyle(
                                  color: Color(0xFFBFC6D2),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Duration kartı
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showDurationPicker(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1F26),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Durations',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Text(
                                  _timerService.isRunning ||
                                          _timerService.duration <
                                              _timerService.selectedDuration *
                                                  60
                                      ? _timerService.formatDuration(
                                        _timerService.duration,
                                      )
                                      : (_timerService.selectedDuration > 0
                                          ? '${_timerService.selectedDuration}'
                                          : '0'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _timerService.isRunning ||
                                          _timerService.duration <
                                              _timerService.selectedDuration *
                                                  60
                                      ? ''
                                      : 'minutes',
                                  style: const TextStyle(
                                    color: Color(0xFFBFC6D2),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Play/Pause ve Restart butonları
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Play/Pause butonu
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_timerService.isRunning) {
                          _timerService.stopTimer();
                        } else {
                          _timerService.startTimer();
                        }
                      });
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1F26),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _timerService.isRunning
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Restart butonu
                  GestureDetector(
                    onTap: () {
                      _timerService.resetTimer();
                      setState(() {});
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1F26),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            spreadRadius: 1,
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.restart_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B0E14),
        selectedItemColor: const Color(0xFF339DFF),
        unselectedItemColor: const Color(0xFFBFC6D2),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            // Rezervasyon butonuna tıklandığında
            NavigationService.navigateTo(
              context,
              const ReservationScreen(),
              replace: true,
            );
          } else if (index == 2) {
            // Profil butonuna tıklandığında
            NavigationService.navigateTo(
              context,
              const ProfileScreen(),
              replace: true,
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Rezervasyon',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildDayCircle(
    String day,
    bool isCompleted, {
    required int index,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: const TextStyle(color: Color(0xFFBFC6D2), fontSize: 14),
          ),
          const SizedBox(height: 5),
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child:
                isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : const Icon(
                      Icons.circle_outlined,
                      size: 16,
                      color: Color(0xFFBFC6D2),
                    ),
          ),
        ],
      ),
    );
  }
}
