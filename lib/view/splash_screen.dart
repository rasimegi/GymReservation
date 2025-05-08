import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:gym_reservation/responsive_helper.dart';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Logo animasyonu için controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade-in ve büyüme animasyonu
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    // Kullanıcı oturum durumunu kontrol et ve uygun ekrana yönlendir
    Timer(const Duration(seconds: 3), () {
      _checkAuthAndNavigate();
    });
  }

  // Kullanıcı oturum durumunu kontrol et
  Future<void> _checkAuthAndNavigate() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Kullanıcı giriş yapmışsa ana sayfaya yönlendir
      print("✅ Kullanıcı zaten giriş yapmış: ${currentUser.uid}");
      NavigationService.navigateTo(context, const HomeScreen(), replace: true);
    } else {
      // Kullanıcı giriş yapmamışsa giriş sayfasına yönlendir
      print("❌ Kullanıcı giriş yapmamış. Giriş sayfasına yönlendiriliyor...");
      NavigationService.navigateTo(context, widget.nextScreen, replace: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);

    // Ekran boyutuna göre logo boyutlandırması
    double logoSize = isDesktop ? 500.0 : (isTablet ? 400.0 : 300.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Center(
          child: FadeTransition(
            opacity: _animation,
            child: ScaleTransition(
              scale: _animation,
              child:
                  isDesktop || isTablet
                      ? Container(
                        width: logoSize,
                        height: logoSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/logo1.jpeg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                      : Image.asset(
                        'assets/logo1.jpeg',
                        fit: BoxFit.cover,
                        width: screenWidth,
                        height: screenHeight,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
