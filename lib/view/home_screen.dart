import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_reservation/view/reservation_screen.dart';
import 'package:gym_reservation/view/profile_screen.dart';
import 'package:gym_reservation/services/timer_service.dart';
import 'dart:async';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';
import 'package:gym_reservation/firebase/models/announcement_model.dart';
import 'package:gym_reservation/firebase/models/training_program_model.dart';
import 'package:gym_reservation/responsive_helper.dart';

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
  final FirebaseService _firebaseService = FirebaseService();

  // Günlük istatistikler için değişkenler
  int _selectedDay = -1; // Seçilen gün indeksi (-1 seçim yok demek)

  // Duyurular ve antrenman programları için değişkenler
  List<Announcement> _announcements = [];
  List<TrainingProgram> _trainingPrograms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDayStatus();
    _initializeTimerService();
    _loadFirebaseData();
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

  // Firebase verilerini yükle
  Future<void> _loadFirebaseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Duyuruları yükle
      final announcements = await _firebaseService.getAnnouncements();

      // Kullanıcı antrenman programlarını yükle
      final user = _firebaseService.currentUser;
      List<TrainingProgram> trainingPrograms = [];

      if (user != null) {
        trainingPrograms = await _firebaseService.getUserTrainingPrograms(
          user.uid,
        );
      }

      setState(() {
        _announcements = announcements;
        _trainingPrograms = trainingPrograms;
        _isLoading = false;
      });
    } catch (e) {
      print('Firebase verileri yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
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
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        elevation: 0,
        title: Row(
          children: [
            Text(
              'Merhabalar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22 * fontScale,
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
      body: RefreshIndicator(
        onRefresh: _loadFirebaseData,
        color: Colors.red,
        backgroundColor: const Color(0xFF1C1F26),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(16.0 * paddingScale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Spor günü yazısı
                Text(
                  'Spor yapmak için harika bir gün!',
                  style: TextStyle(
                    color: const Color(0xFFBFC6D2),
                    fontSize: 16 * fontScale,
                  ),
                ),
                SizedBox(height: 20 * paddingScale),

                // Haftanın günleri
                SizedBox(
                  height: 60 * paddingScale,
                  child: _buildDaysRow(dayLetters, paddingScale, fontScale),
                ),
                SizedBox(height: 16 * paddingScale),

                // Tablet ve masaüstü için özel düzen
                if (isTablet || isDesktop)
                  _buildTabletDesktopLayout(paddingScale, fontScale)
                else
                  _buildMobileLayout(paddingScale, fontScale),
              ],
            ),
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
        selectedFontSize: 12 * fontScale,
        unselectedFontSize: 12 * fontScale,
        iconSize: 24 * fontScale,
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

  // Günler satırı için widget
  Widget _buildDaysRow(
    List<String> dayLetters,
    double paddingScale,
    double fontScale,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Günler için tıklanabilir butonlar
        for (int i = 0; i < 7; i++)
          _buildDayCircle(
            dayLetters[i],
            _dayStatus[i],
            index: i,
            onTap: () => _toggleDayStatus(i),
            fontScale: fontScale,
          ),

        // Hedef sayısı
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HEDEF',
              style: TextStyle(
                color: const Color(0xFFBFC6D2),
                fontSize: 12 * fontScale,
              ),
            ),
            Text(
              '$_completedDays / $_targetDays',
              style: TextStyle(
                color: const Color(0xFFBFC6D2),
                fontSize: 14 * fontScale,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Tablet ve masaüstü için layout
  Widget _buildTabletDesktopLayout(double paddingScale, double fontScale) {
    return Column(
      children: [
        // Ana içerik - 2 sütunlu düzen
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sol sütun - Program ve Duyurular
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  _buildTrainingProgramCard(paddingScale, fontScale),
                  SizedBox(height: 20 * paddingScale),
                  _buildAnnouncementsCard(paddingScale, fontScale),
                ],
              ),
            ),
            SizedBox(width: 20 * paddingScale),
            // Sağ sütun - Aktivite, Kalori ve Süre
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _buildWeeklyActivityCard(paddingScale, fontScale),
                  SizedBox(height: 20 * paddingScale),
                  _buildCaloriesAndDurationRow(paddingScale, fontScale),
                  SizedBox(height: 20 * paddingScale),
                  _buildTimerControls(paddingScale, fontScale),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Mobil için layout
  Widget _buildMobileLayout(double paddingScale, double fontScale) {
    return Column(
      children: [
        _buildTrainingProgramCard(paddingScale, fontScale),
        SizedBox(height: 20 * paddingScale),
        _buildAnnouncementsCard(paddingScale, fontScale),
        SizedBox(height: 20 * paddingScale),
        _buildWeeklyActivityCard(paddingScale, fontScale),
        SizedBox(height: 10 * paddingScale),
        _buildCaloriesAndDurationRow(paddingScale, fontScale),
        SizedBox(height: 20 * paddingScale),
        _buildTimerControls(paddingScale, fontScale),
      ],
    );
  }

  // Antrenman programı kartı
  Widget _buildTrainingProgramCard(double paddingScale, double fontScale) {
    return Container(
      width: double.infinity,
      height: _trainingPrograms.isEmpty ? 105 * paddingScale : null,
      padding: EdgeInsets.all(16 * paddingScale),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16 * paddingScale),
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
          Text(
            'ANTRENMAN PROGRAMI',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14 * fontScale,
            ),
          ),
          SizedBox(height: 8 * paddingScale),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_trainingPrograms.isEmpty)
            Text(
              'Bugün kayıtlı programın yok',
              style: TextStyle(
                color: const Color(0xFFBFC6D2),
                fontSize: 14 * fontScale,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _trainingPrograms.length,
              itemBuilder: (context, index) {
                final program = _trainingPrograms[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.0 * paddingScale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * fontScale,
                        ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        program.description,
                        style: TextStyle(
                          color: const Color(0xFFBFC6D2),
                          fontSize: 14 * fontScale,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Duyurular kartı
  Widget _buildAnnouncementsCard(double paddingScale, double fontScale) {
    return Container(
      width: double.infinity,
      height: _announcements.isEmpty ? 105 * paddingScale : null,
      padding: EdgeInsets.all(16 * paddingScale),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16 * paddingScale),
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
          Text(
            'DUYURULAR',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14 * fontScale,
            ),
          ),
          SizedBox(height: 8 * paddingScale),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_announcements.isEmpty)
            Text(
              'Şuan herhangi bir duyuru yok',
              style: TextStyle(
                color: const Color(0xFFBFC6D2),
                fontSize: 14 * fontScale,
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _announcements.length,
              itemBuilder: (context, index) {
                final announcement = _announcements[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.0 * paddingScale),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.aTitle,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * fontScale,
                        ),
                      ),
                      SizedBox(height: 4 * paddingScale),
                      Text(
                        announcement.message,
                        style: TextStyle(
                          color: const Color(0xFFBFC6D2),
                          fontSize: 14 * fontScale,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Haftalık aktivite kartı
  Widget _buildWeeklyActivityCard(double paddingScale, double fontScale) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16 * paddingScale),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F26),
        borderRadius: BorderRadius.circular(16 * paddingScale),
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
                    size: 20 * fontScale,
                  ),
                  SizedBox(width: 8 * paddingScale),
                  Text(
                    'Haftalık Aktivite',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16 * fontScale,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20 * paddingScale),
          Row(
            children: [
              Text(
                '${_timerService.totalMinutes}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8 * paddingScale),
              Text(
                'total minutes',
                style: TextStyle(
                  color: const Color(0xFFBFC6D2),
                  fontSize: 16 * fontScale,
                ),
              ),
            ],
          ),
          SizedBox(height: 16 * paddingScale),
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
                        _selectedDay = _selectedDay == index ? -1 : index;
                      });
                    },
                    child: Container(
                      width: 15 * paddingScale,
                      height:
                          110 *
                          paddingScale *
                          (_timerService.dailyMinutes[index] == 0
                              ? 0.10 // 0 iken %10 boyut
                              : (_timerService.dailyMinutes[index] * 0.01) +
                                      0.10 >
                                  1.0
                              ? 1.0 // Maksimum %100
                              : (_timerService.dailyMinutes[index] * 0.01) +
                                  0.10 // Her 1 artışta %1 artış + başlangıç %10
                                  ),
                      decoration: BoxDecoration(
                        color:
                            isToday
                                ? Colors.greenAccent.withOpacity(
                                  0.7,
                                ) // Bugünün rengi farklı olsun
                                : const Color(0xFFB0E5F3).withOpacity(
                                  _timerService.dailyMinutes[index] > 0
                                      ? 0.4 +
                                          (_timerService.dailyMinutes[index] /
                                              120)
                                      : 0.3,
                                ),
                        borderRadius: BorderRadius.circular(20 * paddingScale),
                        border:
                            isToday
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                      ),
                    ),
                  ),
                  SizedBox(height: 8 * paddingScale),
                  Text(
                    days[index],
                    style: TextStyle(
                      color:
                          isToday
                              ? Colors.white
                              : Colors.white.withOpacity(0.6),
                      fontSize: 14 * fontScale,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              );
            }),
          ),

          // Seçilen gün için bilgi kutusu
          if (_selectedDay >= 0 && _selectedDay < 7)
            Container(
              margin: EdgeInsets.only(top: 16 * paddingScale),
              padding: EdgeInsets.all(12 * paddingScale),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0E14),
                borderRadius: BorderRadius.circular(12 * paddingScale),
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
                      Icon(
                        Icons.access_time,
                        color: const Color(0xFFBFC6D2),
                        size: 16 * fontScale,
                      ),
                      SizedBox(width: 6 * paddingScale),
                      Text(
                        'Total Minutes: ${_timerService.dailyMinutes[_selectedDay]}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * fontScale,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8 * paddingScale),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: const Color(0xFFBFC6D2),
                        size: 16 * fontScale,
                      ),
                      SizedBox(width: 6 * paddingScale),
                      Text(
                        'Calories: ${_timerService.dailyCalories[_selectedDay]}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14 * fontScale,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Kalori ve süre satırı
  Widget _buildCaloriesAndDurationRow(double paddingScale, double fontScale) {
    return Row(
      children: [
        // Kalori
        Expanded(
          child: Container(
            padding: EdgeInsets.all(16 * paddingScale),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1F26),
              borderRadius: BorderRadius.circular(16 * paddingScale),
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
                          size: 20 * fontScale,
                        ),
                        SizedBox(width: 8 * paddingScale),
                        Text(
                          'Calories',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16 * fontScale,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 20 * paddingScale),
                Row(
                  children: [
                    Text(
                      '${_timerService.calories}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8 * paddingScale),
                    Text(
                      'kcal',
                      style: TextStyle(
                        color: const Color(0xFFBFC6D2),
                        fontSize: 16 * fontScale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        SizedBox(width: 10 * paddingScale),

        // Duration kartı
        Expanded(
          child: GestureDetector(
            onTap: () => _showDurationPicker(context),
            child: Container(
              padding: EdgeInsets.all(16 * paddingScale),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1F26),
                borderRadius: BorderRadius.circular(16 * paddingScale),
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
                            size: 20 * fontScale,
                          ),
                          SizedBox(width: 8 * paddingScale),
                          Text(
                            'Durations',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16 * fontScale,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white.withOpacity(0.8),
                        size: 20 * fontScale,
                      ),
                    ],
                  ),
                  SizedBox(height: 20 * paddingScale),
                  Row(
                    children: [
                      Text(
                        _timerService.isRunning ||
                                _timerService.duration <
                                    _timerService.selectedDuration * 60
                            ? _timerService.formatDuration(
                              _timerService.duration,
                            )
                            : (_timerService.selectedDuration > 0
                                ? '${_timerService.selectedDuration}'
                                : '0'),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40 * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8 * paddingScale),
                      Text(
                        _timerService.isRunning ||
                                _timerService.duration <
                                    _timerService.selectedDuration * 60
                            ? ''
                            : 'minutes',
                        style: TextStyle(
                          color: const Color(0xFFBFC6D2),
                          fontSize: 16 * fontScale,
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
    );
  }

  // Timer kontrol butonları
  Widget _buildTimerControls(double paddingScale, double fontScale) {
    return Row(
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
            width: 60 * paddingScale,
            height: 60 * paddingScale,
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
                _timerService.isRunning ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 30 * fontScale,
              ),
            ),
          ),
        ),

        SizedBox(width: 20 * paddingScale),

        // Restart butonu
        GestureDetector(
          onTap: () {
            _timerService.resetTimer();
            setState(() {});
          },
          child: Container(
            width: 40 * paddingScale,
            height: 40 * paddingScale,
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
                Icons.restart_alt,
                color: Colors.white,
                size: 20 * fontScale,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCircle(
    String day,
    bool isCompleted, {
    required int index,
    required Function() onTap,
    required double fontScale,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              color: const Color(0xFFBFC6D2),
              fontSize: 14 * fontScale,
            ),
          ),
          SizedBox(height: 5),
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
            ),
            child:
                isCompleted
                    ? Icon(
                      Icons.check,
                      size: 16 * fontScale,
                      color: Colors.white,
                    )
                    : Icon(
                      Icons.circle_outlined,
                      size: 16 * fontScale,
                      color: const Color(0xFFBFC6D2),
                    ),
          ),
        ],
      ),
    );
  }
}
