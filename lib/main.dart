import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gym_reservation/view/splash_screen.dart';
import 'package:gym_reservation/view/login_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);

  // Yönlendirmeyi hem dikey hem yatay modda çalışacak şekilde ayarla
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const MyApp());
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
