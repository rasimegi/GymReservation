import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gym_reservation/view/reservation_screen.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gym_reservation/services/timer_service.dart';
import 'package:gym_reservation/utils/page_transition.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  // Kullanıcı verileri
  String _name = "Ayşe Yılmaz";
  String _email = "ayse.yilmaz@mail.com";
  int _age = 28;
  String _gender = "-";
  String _activity = "-";
  String _goal = "-";
  bool _isEditingProfile = false;

  // Profil fotoğrafı
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Timer servisi
  final TimerService _timerService = TimerService();

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameController = TextEditingController(text: _name);
    _emailController = TextEditingController(text: _email);
    _ageController = TextEditingController(text: _age.toString());
    _activityController = TextEditingController(text: _activity);
    _goalController = TextEditingController(text: _goal);

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
    if (state == AppLifecycleState.paused) {
      // Uygulama arka plana alındığında timer durumunu kaydet
      _timerService.saveTimerState();
    } else if (state == AppLifecycleState.resumed) {
      // Uygulama tekrar açıldığında timer'ı kontrol et
      _timerService.resumeTimerIfNeeded();
      setState(() {});
    }
  }

  // Galeriden fotoğraf seçme
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Kameradan fotoğraf çekme
  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _hasChanges = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf çekilirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fotoğraf seçme veya çekme seçeneklerini gösterme
  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1F26),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profil Fotoğrafı Seç',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    title: 'Galeri',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    title: 'Kamera',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ],
              ),
              if (_profileImage != null) ...[
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _profileImage = null;
                      _hasChanges = true;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'Fotoğrafı Kaldır',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0E14),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF339DFF)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
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

    // Burada veritabanı kaydetme işlemleri yapılacak

    // Başarılı kayıt mesajı göster
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Değişiklikler kaydedildi'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      _hasChanges = false;
    });
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
              ? IconButton(
                icon: const Icon(Icons.save, color: Color(0xFF339DFF)),
                onPressed: _saveChanges,
              )
              : const SizedBox.shrink(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // Profil fotoğrafı
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1C1F26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                      image:
                          _profileImage != null
                              ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _profileImage == null
                            ? const Icon(
                              Icons.person,
                              color: Color(0xFFBFC6D2),
                              size: 80,
                            )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _showImageSourceBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF339DFF),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            _isEditingProfile ? Icons.check : Icons.edit,
                            color: const Color(0xFF339DFF),
                          ),
                          onPressed: () {
                            if (_isEditingProfile) {
                              // Değişiklikleri kaydet
                              setState(() {
                                _name = _nameController.text;
                                _email = _emailController.text;
                                _age =
                                    int.tryParse(_ageController.text) ?? _age;
                                _activity = _activityController.text;
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
                                _ageController.text = _age.toString();
                                _activityController.text = _activity;
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
                      _buildEditableField('Ad Soyad', _nameController),
                      _buildEditableField('E-posta', _emailController),
                      _buildEditableField('Yaş', _ageController),
                      _buildGenderSelection(),
                      _buildEditableField(
                        'Aktivite Seviyesi',
                        _activityController,
                      ),
                      _buildEditableField('Hedef', _goalController),
                    ] else ...[
                      _buildProfileField('Ad Soyad', _name),
                      _buildProfileField('E-posta', _email),
                      _buildProfileField('Yaş', _age.toString()),
                      _buildProfileField('Cinsiyet', _gender),
                      _buildProfileField('Aktivite Seviyesi', _activity),
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
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: bodyMeasurements.length,
                      itemBuilder: (context, index) {
                        final key = bodyMeasurements.keys.elementAt(index);
                        final value = bodyMeasurements[key];
                        return _buildMeasurementTile(key, value!);
                      },
                    ),
                  ],
                ),
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
}
