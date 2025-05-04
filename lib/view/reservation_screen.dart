import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_reservation/view/profile_screen.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/services/timer_service.dart';
import 'package:gym_reservation/utils/page_transition.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({Key? key}) : super(key: key);

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen>
    with WidgetsBindingObserver {
  late DateTime _selectedDate;
  late int _currentMonth;
  late int _currentYear;
  List<DateTime> _calendarDays = [];

  // Randevuları tutmak için Map
  final Map<String, String> _appointments = {};
  String? _selectedTime;

  // Saat aralıkları
  final List<String> _timeSlots = [
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '12:00-13:00',
    '13:00-14:00',
    '14:00-15:00',
    '15:00-16:00',
    '16:00-17:00',
    '17:00-18:00',
    '18:00-19:00',
    '19:00-20:00',
    '20:00-21:00',
  ];

  // Timer servisi
  final TimerService _timerService = TimerService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _selectedDate = DateTime.now();
    _currentMonth = _selectedDate.month;
    _currentYear = _selectedDate.year;
    _generateCalendarDays();

    // Timer güncellendiğinde setState çağrısı yapılacak
    _timerService.onTimerUpdate = () {
      if (mounted) {
        setState(() {});
      }
    };

    // Timer durumunu kontrol et
    _timerService.resumeTimerIfNeeded();
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
      setState(() {});
    }
  }

  // Tarih formatını oluştur
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showTimeSelectionDialog(BuildContext context, DateTime selectedDate) {
    // Lokal bir değişken oluştur, fonksiyon kapandığında kaybolmaması için
    String? localSelectedTime = _selectedTime;

    // 15 günden fazla ileri tarih kontrolü
    final DateTime now = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ); // Saat, dakika, saniye bilgisini sıfırla
    final DateTime maxDate = now.add(const Duration(days: 15));

    // Geçmiş tarih kontrolü
    if (selectedDate.isBefore(now)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1F26),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Uyarı', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              'Geçmiş tarihlere randevu oluşturamazsınız.',
              style: TextStyle(color: Color(0xFFBFC6D2)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF339DFF),
                ),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (selectedDate.isAfter(maxDate)) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1C1F26),
            title: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Text('Uyarı', style: TextStyle(color: Colors.white)),
              ],
            ),
            content: const Text(
              'En fazla 15 gün sonrasına kadar randevu oluşturabilirsiniz.',
              style: TextStyle(color: Color(0xFFBFC6D2)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF339DFF),
                ),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF0B0E14),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Randevu Saati Seçin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 250,
                  width: double.maxFinite,
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              childAspectRatio: 5.0,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: _timeSlots.length,
                        itemBuilder: (context, index) {
                          final timeSlot = _timeSlots[index];
                          final isSelected = timeSlot == localSelectedTime;
                          final isBooked =
                              _appointments.entries
                                  .where(
                                    (entry) =>
                                        entry.value == timeSlot &&
                                        entry.key == _formatDate(selectedDate),
                                  )
                                  .isNotEmpty;

                          return GestureDetector(
                            onTap:
                                isBooked
                                    ? null
                                    : () {
                                      setDialogState(() {
                                        localSelectedTime = timeSlot;
                                      });
                                    },
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? const Color(0xFF339DFF)
                                        : const Color(0xFF1C1F26),
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    isBooked
                                        ? Border.all(
                                          color: Colors.red.withOpacity(0.5),
                                          width: 1.5,
                                        )
                                        : isSelected
                                        ? null
                                        : Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1.5,
                                        ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF339DFF,
                                            ).withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Center(
                                child:
                                    isBooked
                                        ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              timeSlot,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.5,
                                                ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Dolu',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          timeSlot,
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.white.withOpacity(
                                                      0.8,
                                                    ),
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                          ),
                                        ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFBFC6D2),
                      ),
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF339DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () {
                        if (localSelectedTime != null) {
                          setState(() {
                            _selectedTime = localSelectedTime;
                            _appointments[_formatDate(selectedDate)] =
                                localSelectedTime!;
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text(
                        'Randevu Oluştur',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _generateCalendarDays() {
    _calendarDays = [];

    // Ay bilgisini oluştur
    final firstDayOfMonth = DateTime(_currentYear, _currentMonth, 1);
    final lastDayOfMonth = DateTime(
      _currentYear,
      _currentMonth + 1,
      0,
    ); // Bir sonraki ayın 0. günü, bu ayın son günüdür

    // Önceki aydan görünecek günleri ekle
    int prevDays = firstDayOfMonth.weekday % 7;
    for (int i = prevDays - 1; i >= 0; i--) {
      _calendarDays.add(firstDayOfMonth.subtract(Duration(days: i + 1)));
    }

    // Bu ayın günlerini ekle
    for (int i = 0; i < lastDayOfMonth.day; i++) {
      _calendarDays.add(DateTime(_currentYear, _currentMonth, i + 1));
    }

    // Sonraki aydan görünecek günleri ekle
    int nextDays = 42 - _calendarDays.length; // 6 satır * 7 gün = 42
    for (int i = 0; i < nextDays; i++) {
      _calendarDays.add(lastDayOfMonth.add(Duration(days: i + 1)));
    }

    // UI'ı güncelle
    setState(() {});
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonth == 1) {
        _currentMonth = 12;
        _currentYear--;
      } else {
        _currentMonth--;
      }
      _generateCalendarDays();
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonth == 12) {
        _currentMonth = 1;
        _currentYear++;
      } else {
        _currentMonth++;
      }
      _generateCalendarDays();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayNames = ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'];
    final monthFormat = DateFormat.MMMM('tr_TR');
    final dateFormat = DateFormat('dd-MM-yyyy');
    final monthName =
        monthFormat.format(DateTime(_currentYear, _currentMonth)).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        elevation: 0,
        title: const Text(
          'Rezervasyonlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Ay seçimi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                    color: Color(0xFF339DFF),
                  ),
                  onPressed: _previousMonth,
                ),
                Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF339DFF),
                  ),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gün isimleri
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  dayNames
                      .map(
                        (day) => Text(
                          day,
                          style: const TextStyle(
                            color: Color(0xFFBFC6D2),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Takvim günleri
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _calendarDays.length,
              itemBuilder: (context, index) {
                final date = _calendarDays[index];
                final isCurrentMonth = date.month == _currentMonth;
                final isSelected =
                    date.day == _selectedDate.day &&
                    date.month == _selectedDate.month &&
                    date.year == _selectedDate.year;
                final isToday =
                    date.day == DateTime.now().day &&
                    date.month == DateTime.now().month &&
                    date.year == DateTime.now().year;
                final hasAppointment = _appointments.containsKey(
                  _formatDate(date),
                );

                // Renkleri ayarla
                Color bgColor = Colors.transparent;
                Color textColor =
                    isCurrentMonth
                        ? Colors.white
                        : const Color(0xFFBFC6D2).withOpacity(0.5);

                if (isSelected) {
                  bgColor = const Color(0xFF339DFF).withOpacity(0.8);
                  textColor = Colors.white;
                } else if (isToday) {
                  bgColor = const Color(0xFF339DFF).withOpacity(0.3);
                  textColor = Colors.white;
                }

                return GestureDetector(
                  onTap: () {
                    if (isCurrentMonth) {
                      setState(() {
                        _selectedDate = date;
                      });
                      _showTimeSelectionDialog(context, date);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          isToday && !isSelected
                              ? Border.all(color: const Color(0xFF339DFF))
                              : null,
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF339DFF,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                              : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight:
                                isSelected || isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                        if (hasAppointment)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF339DFF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Randevu listesi
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1F26),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Randevularım',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Tüm randevularınızı aşağıda görebilirsiniz',
                  style: TextStyle(fontSize: 12, color: Color(0xFFBFC6D2)),
                ),
                const SizedBox(height: 16),
                if (_appointments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Henüz randevu oluşturmadınız',
                        style: TextStyle(
                          color: Color(0xFFBFC6D2),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: ShaderMask(
                      shaderCallback: (Rect rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1C1F26),
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xFF1C1F26),
                          ],
                          stops: [0.0, 0.05, 0.95, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstOut,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(right: 5),
                        itemCount: _appointments.length,
                        itemBuilder: (context, index) {
                          final date = _appointments.keys.elementAt(index);
                          final time = _appointments[date];
                          final dateObj = DateTime.parse(date);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B0E14),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF339DFF,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      color: Color(0xFF339DFF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Fitness Seans',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormat('d MMMM y', 'tr_TR').format(dateObj)} · $time',
                                          style: const TextStyle(
                                            color: Color(0xFFBFC6D2),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _appointments.remove(date);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0B0E14),
        selectedItemColor: const Color(0xFF339DFF),
        unselectedItemColor: const Color(0xFFBFC6D2),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 1,
        onTap: (index) {
          if (index == 0) {
            // Ana Sayfa butonuna tıklandığında
            NavigationService.navigateTo(
              context,
              const HomeScreen(),
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
}
