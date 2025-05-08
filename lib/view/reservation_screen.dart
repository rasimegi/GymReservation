import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gym_reservation/view/profile_screen.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/services/timer_service.dart';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:gym_reservation/firebase/providers/reservation_provider.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';

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

  // Firebase servisleri
  final FirebaseService _firebaseService = FirebaseService();
  final ReservationProvider _reservationProvider = ReservationProvider();
  String? _currentUserId;
  bool _isLoading = false;

  // Saat aralıkları
  final List<String> _timeSlots = [
    '07:00-08:00',
    '08:00-09:00',
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

    // Test kullanıcısıyla giriş yapmayı dene
    _testLogin();

    // Giriş yapmış kullanıcıyı al
    _getCurrentUser();

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

    // Kullanıcı giriş yapmamışsa uyarı göster
    if (_currentUserId == null) {
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
              'Rezervasyon yapabilmek için giriş yapmalısınız.',
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

    // Formatlanmış tarih
    final formattedDate = _formatDate(selectedDate);

    // Önce bu tarihteki mevcut rezervasyon durumunu kontrol edelim
    setState(() {
      _isLoading = true;
    });

    _reservationProvider
        .fetchReservedTimeSlots(formattedDate)
        .then((_) {
          setState(() {
            _isLoading = false;
          });

          // Şimdi rezervasyon durumuyla birlikte zaman seçim diyaloğunu göster
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return Dialog(
                    backgroundColor: const Color(0xFF1C1F26),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF339DFF),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Saat Seçin - ${DateFormat('dd.MM.yyyy').format(selectedDate)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Lütfen randevu için bir saat aralığı seçin. Her saat dilimini en fazla 3 kişi seçebilir.',
                            style: TextStyle(color: Color(0xFFBFC6D2)),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.5,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    _timeSlots.map((timeSlot) {
                                      // Zaman diliminin dolu olup olmadığını kontrol et
                                      final isReserved = _reservationProvider
                                          .reservedTimeSlots
                                          .contains(timeSlot);

                                      // Zaman dilimini seçin
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              localSelectedTime == timeSlot
                                                  ? const Color(
                                                    0xFF339DFF,
                                                  ).withOpacity(0.2)
                                                  : isReserved
                                                  ? const Color(0xFF444444)
                                                  : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color:
                                                localSelectedTime == timeSlot
                                                    ? const Color(0xFF339DFF)
                                                    : isReserved
                                                    ? Colors.red.withOpacity(
                                                      0.5,
                                                    )
                                                    : Colors.white.withOpacity(
                                                      0.3,
                                                    ),
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          title: Text(
                                            timeSlot,
                                            style: TextStyle(
                                              color:
                                                  localSelectedTime == timeSlot
                                                      ? const Color(0xFF339DFF)
                                                      : isReserved
                                                      ? Colors.grey
                                                      : Colors.white,
                                              fontWeight:
                                                  localSelectedTime == timeSlot
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                          trailing:
                                              isReserved
                                                  ? const Chip(
                                                    label: Text(
                                                      'Dolu',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    backgroundColor: Colors.red,
                                                    labelPadding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 0,
                                                        ),
                                                  )
                                                  : const Icon(
                                                    Icons.access_time,
                                                    color: Color(0xFF339DFF),
                                                  ),
                                          enabled: !isReserved,
                                          onTap:
                                              isReserved
                                                  ? null
                                                  : () {
                                                    setDialogState(() {
                                                      localSelectedTime =
                                                          timeSlot;
                                                    });
                                                  },
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ),
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
                                onPressed: () async {
                                  if (localSelectedTime != null) {
                                    Navigator.pop(context);

                                    // Yükleniyor göstergesi
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    // Tarih formatını hazırla
                                    final formattedDate = _formatDate(
                                      selectedDate,
                                    );

                                    print(
                                      "Rezervasyon oluşturuluyor... Tarih: $formattedDate, Saat: $localSelectedTime",
                                    );

                                    // Firebase üzerinden rezervasyon oluştur
                                    if (_currentUserId != null) {
                                      final result = await _reservationProvider
                                          .createReservation(
                                            userId: _currentUserId!,
                                            date: formattedDate,
                                            timeSlot: localSelectedTime!,
                                          );

                                      print(
                                        "Rezervasyon oluşturma sonucu: $result",
                                      );

                                      if (result) {
                                        // Başarılı ise yerel Map'i güncelle
                                        await _reservationProvider
                                            .fetchUserReservations(
                                              _currentUserId!,
                                            );

                                        // Rezerve edilmiş zaman dilimlerini güncelle
                                        await _reservationProvider
                                            .fetchReservedTimeSlots(
                                              formattedDate,
                                            );

                                        // Yerel map'i güncelle
                                        _updateLocalAppointments();

                                        // Rezervasyonu manuel olarak ekle (yenileme sorunu için)
                                        setState(() {
                                          _appointments[formattedDate] =
                                              localSelectedTime!;
                                        });

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Rezervasyonunuz başarıyla oluşturuldu',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        // Hata varsa uyarı göster
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              _reservationProvider
                                                      .errorMessage ??
                                                  'Rezervasyon oluşturulamadı',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Giriş yapmadığınız için rezervasyon yapamazsınız',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }

                                    setState(() {
                                      _isLoading = false;
                                    });
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
            },
          );
        })
        .catchError((error) {
          setState(() {
            _isLoading = false;
          });
          // Hata durumunda uyarı göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rezervasyonlar yüklenirken hata: $error'),
              backgroundColor: Colors.red,
            ),
          );
        });
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

  // Kullanıcıyı al ve rezervasyonları yükle
  Future<void> _getCurrentUser() async {
    print("_getCurrentUser başlatılıyor...");

    final currentUser = _firebaseService.currentUser;
    print("Mevcut kullanıcı: ${currentUser?.uid ?? 'Giriş yapılmamış'}");

    if (currentUser != null) {
      setState(() {
        _currentUserId = currentUser.uid;
        _isLoading = true;
      });
      print("Kullanıcı ID: $_currentUserId");

      // Kullanıcının rezervasyonlarını getir
      print("Kullanıcı rezervasyonları alınıyor...");
      await _reservationProvider.fetchUserReservations(_currentUserId!);
      print(
        "Rezervasyon sayısı: ${_reservationProvider.userReservations.length}",
      );

      // Lokal Map'i güncelle
      _updateLocalAppointments();
      print("Lokal appointment sayısı: ${_appointments.length}");

      setState(() {
        _isLoading = false;
      });
    } else {
      print("HATA: Kullanıcı giriş yapmamış!");
      // Test için dummy veri oluştur
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Giriş yapmadığınız için rezervasyon yapamazsınız.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Firebase'den gelen rezervasyonları yerel Map'e aktar
  void _updateLocalAppointments() {
    print("_updateLocalAppointments başlatılıyor...");
    print("Önceki rezervasyon sayısı: ${_appointments.length}");

    // Önce Map'i temizle
    _appointments.clear();

    // Yeni rezervasyonları ekle
    for (var reservation in _reservationProvider.userReservations) {
      print(
        "İşlenen rezervasyon: ${reservation.date} ${reservation.timeSlot} (Aktif: ${reservation.isActive})",
      );

      if (reservation.isActive) {
        // Sadece aktif rezervasyonları göster
        _appointments[reservation.date] = reservation.timeSlot;
        print(
          "Rezervasyon eklendi: ${reservation.date} -> ${reservation.timeSlot}",
        );
      }
    }

    print("Güncellenmiş rezervasyon sayısı: ${_appointments.length}");
    print("Appointments içeriği: $_appointments");

    // UI'ı güncelle
    setState(() {});
  }

  void _showCancelConfirmationDialog(
    BuildContext context,
    String reservationId,
  ) {
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
            'Bu rezervasyonu tamamen silmek istediğinize emin misiniz?',
            style: TextStyle(color: Color(0xFFBFC6D2)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF339DFF),
              ),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                setState(() {
                  _isLoading = true;
                });

                // Rezervasyonu tamamen sil
                if (_currentUserId != null) {
                  await _reservationProvider.deleteReservation(
                    userId: _currentUserId!,
                    reservationId: reservationId,
                  );

                  // Rezervasyon listesini güncelle
                  _updateLocalAppointments();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rezervasyonunuz silindi'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                setState(() {
                  _isLoading = false;
                });
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  // Test kullanıcısıyla giriş yapma
  Future<void> _testLogin() async {
    try {
      print("Test kullanıcısıyla giriş deneniyor...");
      final result = await _firebaseService.signInWithEmailAndPassword(
        email: "test@test.com",
        password: "123456",
      );
      print("Test giriş başarılı: ${result.user?.uid}");
    } catch (e) {
      print("Test giriş başarısız: $e");
    }
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tüm randevularınızı aşağıda görebilirsiniz',
                      style: TextStyle(fontSize: 12, color: Color(0xFFBFC6D2)),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF339DFF),
                        size: 20,
                      ),
                      onPressed: () async {
                        // Yükleniyor göstergesi göster
                        setState(() {
                          _isLoading = true;
                        });

                        if (_currentUserId != null) {
                          // Rezervasyonları yeniden yükle
                          await _reservationProvider.fetchUserReservations(
                            _currentUserId!,
                          );

                          // Lokal map'i güncelle
                          _updateLocalAppointments();

                          // Bildirimi göster
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rezervasyonlar yenilendi'),
                              backgroundColor: Color(0xFF339DFF),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }

                        // Yükleniyor göstergesini kapat
                        setState(() {
                          _isLoading = false;
                        });
                      },
                    ),
                  ],
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
                    child:
                        _isLoading
                            ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF339DFF),
                              ),
                            )
                            : ShaderMask(
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
                                itemCount:
                                    _reservationProvider
                                        .userReservations
                                        .length,
                                itemBuilder: (context, index) {
                                  final reservation =
                                      _reservationProvider
                                          .userReservations[index];
                                  // Sadece aktif rezervasyonları göster
                                  if (!reservation.isActive)
                                    return const SizedBox.shrink();

                                  // Tarih formatını ayarla
                                  final dateObj = DateTime.parse(
                                    reservation.date,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B0E14),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                  '${DateFormat('d MMMM y', 'tr_TR').format(dateObj)} · ${reservation.timeSlot}',
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
                                              // Silme onayı iste
                                              _showCancelConfirmationDialog(
                                                context,
                                                reservation.reservationId ??
                                                    '${reservation.date}_${reservation.timeSlot}',
                                              );
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
