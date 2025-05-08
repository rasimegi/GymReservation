import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_reservation/view/splash_screen.dart';
import 'package:gym_reservation/view/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:gym_reservation/firebase/providers/auth_provider.dart';
import 'package:gym_reservation/firebase/providers/measurements_provider.dart';
import 'package:gym_reservation/firebase/providers/reservation_provider.dart';
import 'package:gym_reservation/firebase/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gym_reservation/services/notification_service.dart';
// Diğer Firebase provider'larını da ekleyebilirsiniz

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firestore'u başlat
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // Firestore ayarları
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    print("Firestore ayarları yapılandırıldı");
  } catch (e) {
    print("Firestore ayarları yapılandırılırken hata: $e");
  }

  // Firestore izinlerini ayarla
  try {
    final firebaseService = FirebaseService();
    await firebaseService.setupFirebasePermissions();
    print("Firebase izinleri başarıyla ayarlandı");

    // Kullanıcı otomatik giriş yapma (geliştirme/test için)
    try {
      if (firebaseService.currentUser == null) {
        final userCredential = await firebaseService.signInWithEmailAndPassword(
          email: "test@test.com",
          password: "123456",
        );
        print(
          "Test kullanıcısı ile otomatik giriş yapıldı: ${userCredential.user?.uid}",
        );

        // Firebase bağlantısını kontrol et
        try {
          await Future.delayed(const Duration(seconds: 1));
          print("Firestore bağlantısı kontrol ediliyor...");

          // Firestore koleksiyonlarını oluştur (eğer yoksa)
          await firebaseService.setupInitialCollections();

          print("Firestore bağlantısı başarılı!");
        } catch (e) {
          print("Firestore bağlantı kontrolü başarısız: $e");
        }
      } else {
        print("Zaten giriş yapılmış: ${firebaseService.currentUser?.uid}");
      }
    } catch (e) {
      print("Test kullanıcısı ile giriş yapılamadı: $e");

      // Eğer test kullanıcısı ile giriş yapılamazsa, anonim olarak giriş yapmayı dene
      try {
        print("Anonim giriş deneniyor...");
        final anonCredential = await firebaseService.signInAnonymously();
        print("Anonim giriş başarılı: ${anonCredential.user?.uid}");
      } catch (anonError) {
        print("Anonim giriş başarısız: $anonError");
      }
    }
  } catch (e) {
    print("Firebase izinleri ayarlanırken hata: $e");
  }

  await initializeDateFormatting('tr_TR', null);

  // Yönlendirmeyi hem dikey hem yatay modda çalışacak şekilde ayarla
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Bildirim servisini başlat
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MeasurementsProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        // Diğer provider'ları buraya ekleyebilirsiniz
      ],
      child: const MyApp(),
    ),
  );
}

/// Ana uygulama sınıfı
/// MVVM mimarisine uygun olarak tasarlanmıştır
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spor Salonu Rezervasyonu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        // Responsive davranış için MediaQuery'i yönet
        final mediaQueryData = MediaQuery.of(context);
        final scale = mediaQueryData.textScaleFactor.clamp(0.8, 1.2);

        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaleFactor: scale,
            padding: mediaQueryData.padding,
          ),
          child: child!,
        );
      },
      home: const SplashScreen(nextScreen: LoginScreen()),
    );
  }
}
