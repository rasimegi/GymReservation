import 'package:flutter/material.dart';
import 'package:gym_reservation/view/reservation_screen.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/view/login_screen.dart';
import 'package:gym_reservation/services/timer_service.dart';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:gym_reservation/firebase/providers/measurements_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_reservation/firebase/models/measurements_model.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  // Kullanıcı verileri
  String _name = "Ad Soyad";
  String _email = "örnek@mail.com";
  int _age = 0;
  String _gender = "-";
  String _activity = "-";
  String _goal = "-";
  bool _isEditingProfile = false;

  // Timer servisi
  final TimerService _timerService = TimerService();

  // Firebase ile ilgili
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MeasurementsProvider _measurementsProvider = MeasurementsProvider();
  final FirebaseService _firebaseService = FirebaseService();

  // Kişisel bilgi kontrolcüleri
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _activityController;
  late TextEditingController _goalController;

  // Vücut ölçüleri için değişkenler
  Map<String, String> bodyMeasurements = {
    'Kilo': '-',
    'Boy': '-',
    'Omuz': '-',
    'Göğüs': '-',
    'Kol': '-',
    'Bel': '-',
    'Kalça': '-',
    'Bacak': '-',
  };

  // Değişiklikleri kaydetme işlemi
  bool _hasChanges = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _ageController = TextEditingController(text: _age.toString());
    _activityController = TextEditingController(text: _activity);
    _goalController = TextEditingController(text: _goal);

    // Kullanıcı profilini yükle
    _loadUserProfile();

    // Mevcut kullanıcının vücut ölçülerini getir
    _loadUserMeasurements(forceRefresh: true);

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
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _activityController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("🔄 App Yaşam Döngüsü Durumu Değişti: $state");

    if (state == AppLifecycleState.paused) {
      // Uygulama arka plana alındığında timer durumunu kaydet
      print("⏸️ Uygulama duraklatıldı, timer durumu kaydediliyor...");
      _timerService.saveTimerState();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar açıldığında timer'ı kontrol et
      print("▶️ Uygulama devam ediyor, timer kontrol ediliyor...");
      _timerService.resumeTimerIfNeeded();

      // Önbelleği temizle ve verileri tamamen yeniden yükle
      print("🔄 Uygulama devam ediyor, veriler yenileniyor...");
      _measurementsProvider.clearMeasurements();

      // Verileri yeniden yükle
      Future.delayed(const Duration(milliseconds: 300), () {
        _loadUserMeasurements(forceRefresh: true);
      });

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _saveChanges() async {
    // Kullanıcı bilgilerini de kaydet
    if (_isEditingProfile) {
      setState(() {
        _name = _nameController.text;
        _email = _emailController.text;
        _age = int.tryParse(_ageController.text) ?? _age;
        _activity = _activityController.text;
        _goal = _goalController.text;
        _isEditingProfile = false;
      });
    }

    // Kullanıcı ID'sini al
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı giriş yapmamış! Lütfen giriş yapın.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Yükleme göstergesi
      setState(() {
        _isLoading = true;
      });

      // Kullanıcı profili güncellemesi
      if (_isEditingProfile) {
        // Ad ve soyadı parçalara ayır
        final nameParts = _name.split(' ');
        String firstName = '';
        String lastName = '';

        if (nameParts.length > 1) {
          firstName = nameParts[0];
          lastName = nameParts.sublist(1).join(' ');
        } else if (nameParts.isNotEmpty) {
          firstName = nameParts[0];
        }

        // Kullanıcı profilini güncelle
        await _firebaseService.updateUserProfile(
          userId: currentUser.uid,
          userData: {
            'name': firstName,
            'surname': lastName,
            'email': _email,
            // Diğer alanları da güncelleyebilirsiniz
          },
        );

        print("✅ Kullanıcı profili başarıyla güncellendi");
      }

      // Ölçüm değerlerinin boş olması durumunu kontrol et
      if (bodyMeasurements.entries.any(
        (entry) => entry.value == '-' || entry.value.isEmpty,
      )) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen tüm vücut ölçülerini girin'),
            backgroundColor: Colors.amber,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Önce önbelleği tamamen temizle
      _measurementsProvider.clearMeasurements();
      print("🔄 Veri kaydetmeden önce önbellek temizlendi");

      // Bugünün tarihini al
      final now = DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(now);

      // Ölçüm değerlerini sayıya dönüştür
      final double weight =
          double.tryParse(bodyMeasurements['Kilo'] ?? '0') ?? 0;
      final double height =
          double.tryParse(bodyMeasurements['Boy'] ?? '0') ?? 0;
      final double chest =
          double.tryParse(bodyMeasurements['Göğüs'] ?? '0') ?? 0;
      final double waist = double.tryParse(bodyMeasurements['Bel'] ?? '0') ?? 0;
      final double hip = double.tryParse(bodyMeasurements['Kalça'] ?? '0') ?? 0;
      final double arm = double.tryParse(bodyMeasurements['Kol'] ?? '0') ?? 0;
      final double thigh =
          double.tryParse(bodyMeasurements['Bacak'] ?? '0') ?? 0;
      final double shoulder =
          double.tryParse(bodyMeasurements['Omuz'] ?? '0') ?? 0;
      final double ageDouble = _age.toDouble();

      // Benzersiz ölçüm ID'si oluştur
      final timestamp = now.millisecondsSinceEpoch;
      final measurementId = "meas_${timestamp}_1";

      // Varsayılan değerler için kontrol
      String actualGender = _gender == '-' ? 'Belirtilmemiş' : _gender;
      String actualGoal = _goal == '-' ? 'Belirtilmemiş' : _goal;
      String actualActivity = _activity == '-' ? 'Orta Seviye' : _activity;

      // Güncel zaman bilgisi oluştur (ISO 8601 formatında)
      final updatedAtStr = now.toIso8601String();
      print("📅 Kullanılan güncelleme tarihi: $updatedAtStr");

      // ÖNCE YENİ DEĞERLERİ EKRANDA GÖSTER (Firebase'e kaydetmeden)
      setState(() {
        bodyMeasurements = {
          'Kilo': weight.toString(),
          'Boy': height.toString(),
          'Omuz': shoulder.toString(),
          'Göğüs': chest.toString(),
          'Kol': arm.toString(),
          'Bel': waist.toString(),
          'Kalça': hip.toString(),
          'Bacak': thigh.toString(),
        };
        _hasChanges = false;
        _isLoading = false;
      });

      // Başarılı kayıt mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ölçüm değerleri güncelleştirildi'),
          backgroundColor: Colors.green,
        ),
      );

      // Arka planda Firebase'e kaydetme işlemi
      _measurementsProvider
          .saveMeasurements(
            userId: currentUser.uid,
            weight: weight,
            height: height,
            chest: chest,
            waist: waist,
            hip: hip,
            arm: arm,
            thigh: thigh,
            shoulder: shoulder,
            age: ageDouble,
            gender: actualGender,
            goal: actualGoal,
            activityLevel: actualActivity,
            measurementId: measurementId,
            mDate: dateStr,
            updatedAt: updatedAtStr,
          )
          .then((result) {
            // İşlem tamamlandığında loglama yap
            if (result) {
              print("✅ Ölçümler Firebase'e kaydedildi: $measurementId");
            } else {
              print(
                "❌ Ölçümler Firebase'e kaydedilemedi: ${_measurementsProvider.errorMessage}",
              );
            }
            // Arkaplanda verileri yenile (göstermeye çalışma)
            _measurementsProvider.fetchMeasurementsHistory(currentUser.uid);
          });
    } catch (e) {
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Vücut ölçüsü düzenleme dialog'unu göster
  void _showEditMeasurementDialog(String key) {
    final textController = TextEditingController(text: bodyMeasurements[key]);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1F26),
          title: Text(
            '$key değerini düzenle',
            style: const TextStyle(color: Colors.white),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: 'Yeni değeri girin',
              hintStyle: const TextStyle(color: Color(0xFFBFC6D2)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF339DFF),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF339DFF),
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'İptal',
                style: TextStyle(color: Color(0xFFBFC6D2)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF339DFF),
              ),
              onPressed: () {
                setState(() {
                  bodyMeasurements[key] = textController.text;
                  _hasChanges = true;
                });
                Navigator.pop(context);
              },
              child: const Text(
                'Kaydet',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Cinsiyet seçim widget'ı
  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cinsiyet',
          style: TextStyle(color: Color(0xFFBFC6D2), fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _gender = "Erkek";
                    _hasChanges = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        _gender == "Erkek"
                            ? const Color(0xFF339DFF).withOpacity(0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _gender == "Erkek"
                              ? const Color(0xFF339DFF)
                              : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: "Erkek",
                        groupValue: _gender,
                        activeColor: const Color(0xFF339DFF),
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                            _hasChanges = true;
                          });
                        },
                      ),
                      Text(
                        'Erkek',
                        style: TextStyle(
                          color:
                              _gender == "Erkek"
                                  ? const Color(0xFF339DFF)
                                  : Colors.white,
                          fontWeight:
                              _gender == "Erkek"
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _gender = "Kadın";
                    _hasChanges = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        _gender == "Kadın"
                            ? const Color(0xFF339DFF).withOpacity(0.2)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _gender == "Kadın"
                              ? const Color(0xFF339DFF)
                              : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Radio<String>(
                        value: "Kadın",
                        groupValue: _gender,
                        activeColor: const Color(0xFF339DFF),
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                            _hasChanges = true;
                          });
                        },
                      ),
                      Text(
                        'Kadın',
                        style: TextStyle(
                          color:
                              _gender == "Kadın"
                                  ? const Color(0xFF339DFF)
                                  : Colors.white,
                          fontWeight:
                              _gender == "Kadın"
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0E14),
        elevation: 0,
        title: const Text(
          'Profil Bilgileri',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          _hasChanges
              ? Container(
                margin: const EdgeInsets.only(right: 10),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF339DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              )
              : const SizedBox.shrink(),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF339DFF)),
              )
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),

                            const SizedBox(height: 24),

                            // Kişisel Bilgiler Kartı
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1F26),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Kişisel Bilgiler',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isEditingProfile
                                              ? Icons.check
                                              : Icons.edit,
                                          color: const Color(0xFF339DFF),
                                        ),
                                        onPressed: () {
                                          if (_isEditingProfile) {
                                            // Değişiklikleri kaydet
                                            setState(() {
                                              _name = _nameController.text;
                                              _email = _emailController.text;
                                              _age =
                                                  int.tryParse(
                                                    _ageController.text,
                                                  ) ??
                                                  _age;
                                              _activity =
                                                  _activityController.text;
                                              _goal = _goalController.text;
                                              _isEditingProfile = false;
                                              _hasChanges = true;
                                            });
                                          } else {
                                            // Düzenleme modunu aç
                                            setState(() {
                                              _isEditingProfile = true;
                                              _nameController.text = _name;
                                              _emailController.text = _email;
                                              _ageController.text =
                                                  _age.toString();
                                              _activityController.text =
                                                  _activity;
                                              _goalController.text = _goal;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Editable fields
                                  if (_isEditingProfile) ...[
                                    _buildEditableField(
                                      'Ad Soyad',
                                      _nameController,
                                    ),
                                    _buildEditableField(
                                      'E-posta',
                                      _emailController,
                                    ),
                                    _buildEditableField('Yaş', _ageController),
                                    _buildGenderSelection(),
                                    _buildEditableField(
                                      'Aktivite Seviyesi',
                                      _activityController,
                                    ),
                                    _buildEditableField(
                                      'Hedef',
                                      _goalController,
                                    ),
                                  ] else ...[
                                    _buildProfileField('Ad Soyad', _name),
                                    _buildProfileField('E-posta', _email),
                                    _buildProfileField('Yaş', _age.toString()),
                                    _buildProfileField('Cinsiyet', _gender),
                                    _buildProfileField(
                                      'Aktivite Seviyesi',
                                      _activity,
                                    ),
                                    _buildProfileField('Hedef', _goal),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Vücut Ölçüleri Kartı
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1F26),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Vücut Ölçüleri',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 2,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 10,
                                        ),
                                    itemCount: bodyMeasurements.length,
                                    itemBuilder: (context, index) {
                                      final key = bodyMeasurements.keys
                                          .elementAt(index);
                                      final value = bodyMeasurements[key];
                                      return _buildMeasurementTile(key, value!);
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Çıkış Yap Butonu
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1F26),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Hesap',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: _signOut,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.red.withOpacity(0.6),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Çıkış Yap',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
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
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            // Ana sayfa butonuna tıklandığında
            NavigationService.navigateTo(
              context,
              const HomeScreen(),
              replace: true,
            );
          } else if (index == 1) {
            // Rezervasyon butonuna tıklandığında
            NavigationService.navigateTo(
              context,
              const ReservationScreen(),
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

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFC6D2), fontSize: 12),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF339DFF),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF339DFF),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFC6D2), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTile(String label, String value) {
    return InkWell(
      onTap: () => _showEditMeasurementDialog(label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF339DFF).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(color: Color(0xFFBFC6D2), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Kullanıcının vücut ölçülerini Firebase'den yükle
  Future<void> _loadUserMeasurements({bool forceRefresh = false}) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("⚠️ _loadUserMeasurements: Kullanıcı giriş yapmamış");
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      print(
        "📥 _loadUserMeasurements: Kullanıcı verileri yükleniyor: ${currentUser.uid}",
      );

      // Ölçüm verilerini temizle - eğer zorunlu yenileme isteniyorsa
      if (forceRefresh) {
        _measurementsProvider.clearMeasurements();
        print("🧹 Ölçüm verileri zorla temizlendi - yeniden yükleniyor");
      }

      // Ölçüm verilerini getir
      await _measurementsProvider.fetchMeasurementsHistory(currentUser.uid);

      // Veri kontrolü ve yazdırma
      print(
        "📊 Mevcut ölçüm verisi: ${_measurementsProvider.currentMeasurements != null ? 'VAR' : 'YOK'}",
      );

      if (_measurementsProvider.currentMeasurements != null) {
        final measurements = _measurementsProvider.currentMeasurements!;

        print(
          "✅ _loadUserMeasurements: Ölçüm verileri bulundu: ${measurements.measurementId}",
        );
        print("📅 _loadUserMeasurements: Ölçüm tarihi: ${measurements.mDate}");
        print(
          "⏱️ _loadUserMeasurements: Güncelleme tarihi: ${measurements.updatedAt}",
        );
        print(
          "⚖️ _loadUserMeasurements: Kilo: ${measurements.weight}, Boy: ${measurements.height}",
        );

        if (mounted) {
          setState(() {
            bodyMeasurements = {
              'Kilo': measurements.weight.toString(),
              'Boy': measurements.height.toString(),
              'Omuz': measurements.shoulder.toString(),
              'Göğüs': measurements.chest.toString(),
              'Kol': measurements.arm.toString(),
              'Bel': measurements.waist.toString(),
              'Kalça': measurements.hip.toString(),
              'Bacak': measurements.thigh.toString(),
            };

            _age = measurements.age.toInt();
            _gender = measurements.gender;
            _goal = measurements.goal;
            _activity = measurements.activityLevel;

            _ageController.text = _age.toString();
            _activityController.text = _activity;
            _goalController.text = _goal;
          });
        }
      } else {
        print("❌ _loadUserMeasurements: Ölçüm verisi bulunamadı");
        // Ölçüm verisi bulunamadığında varsayılan değerler göster
        if (mounted) {
          setState(() {
            bodyMeasurements = {
              'Kilo': '0',
              'Boy': '0',
              'Omuz': '0',
              'Göğüs': '0',
              'Kol': '0',
              'Bel': '0',
              'Kalça': '0',
              'Bacak': '0',
            };
          });
        }
      }
    } catch (e) {
      print('❌ Vücut ölçüleri yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Kullanıcı profil bilgilerini Firebase'den yükle
  Future<void> _loadUserProfile() async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("⚠️ _loadUserProfile: Kullanıcı giriş yapmamış");
      return;
    }

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      print(
        "📥 _loadUserProfile: Kullanıcı profili yükleniyor: ${currentUser.uid}",
      );

      // Firebase'den kullanıcı profilini getir
      final userData = await _firebaseService.getUserProfile(currentUser.uid);

      if (userData != null) {
        print("✅ _loadUserProfile: Kullanıcı profili bulundu");

        if (mounted) {
          setState(() {
            // Kullanıcı bilgilerini güncelle
            _name =
                "${userData['name'] ?? ''} ${userData['surname'] ?? ''}".trim();
            _email = userData['email'] ?? '';

            // Kontrolleri güncelle
            _nameController.text = _name;
            _emailController.text = _email;
          });
        }
      } else {
        print("❌ _loadUserProfile: Kullanıcı profili bulunamadı");

        // E-posta bilgisini Firebase Auth'dan al
        if (mounted && currentUser.email != null) {
          setState(() {
            _email = currentUser.email!;
            _emailController.text = _email;
          });
        }
      }
    } catch (e) {
      print('❌ Kullanıcı profili yüklenirken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil bilgileri yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Çıkış yapma işlemi
  Future<void> _signOut() async {
    try {
      // Kullanıcıya çıkış yapmak istediğinden emin misin diye sor
      final shouldSignOut = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: const Color(0xFF1C1F26),
              title: const Text(
                'Çıkış Yap',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
                style: TextStyle(color: Color(0xFFBFC6D2)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Color(0xFFBFC6D2)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Çıkış Yap',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
      );

      // Eğer kullanıcı emin değilse işlemi iptal et
      if (shouldSignOut != true) {
        return;
      }

      // Yükleme göstergesi göster
      setState(() {
        _isLoading = true;
      });

      // Önce timer durumunu kaydet
      _timerService.saveTimerState();

      // Firebase'den çıkış yap
      await FirebaseAuth.instance.signOut();

      print("👋 Kullanıcı hesaptan çıkış yaptı");

      // Giriş ekranına yönlendir
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, // Tüm ekranları temizle
      );
    } catch (e) {
      print("❌ Çıkış yapma hatası: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapma hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Hata durumunda yükleme göstergesini kapat
      setState(() {
        _isLoading = false;
      });
    }
  }
}
