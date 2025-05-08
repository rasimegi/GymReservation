import 'package:flutter/material.dart';
import 'package:gym_reservation/view/signup_screen.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/view/forgot_password_screen.dart';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:gym_reservation/firebase/providers/auth_provider.dart';
import 'package:gym_reservation/responsive_helper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final screenWidth = ResponsiveHelper.getScreenWidth(context);
    final screenHeight = ResponsiveHelper.getScreenHeight(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(20.0 * paddingScale),
                  child: ResponsiveHelper.getResponsiveLayout(
                    context: context,
                    mobile: _buildMobileLayout(fontScale, paddingScale),
                    tablet: _buildTabletDesktopLayout(fontScale, paddingScale),
                    desktop: _buildTabletDesktopLayout(fontScale, paddingScale),
                  ),
                ),
              ),
            ),

            // Yeni Hesap Oluştur button - sayfanın en altında
            Padding(
              padding: EdgeInsets.only(
                left: 20 * paddingScale,
                right: 20 * paddingScale,
                bottom: 30 * paddingScale,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50 * (isDesktop ? 1.2 : (isTablet ? 1.1 : 1.0)),
                child: OutlinedButton(
                  onPressed: () {
                    NavigationService.navigateTo(context, const SignUpScreen());
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.red,
                      width: 1.5 * (isDesktop ? 1.2 : (isTablet ? 1.1 : 1.0)),
                    ),
                    backgroundColor: Colors.black,
                    shape: const StadiumBorder(), // Capsule şekli
                  ),
                  child: Text(
                    'Yeni Hesap Oluştur',
                    style: TextStyle(
                      fontSize: 16 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mobil cihazlar için düzen
  Widget _buildMobileLayout(double fontScale, double paddingScale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 30 * paddingScale),
        // Logo
        Center(
          child: Image.asset('assets/logo2.png', height: 150 * paddingScale),
        ),
        SizedBox(height: 50 * paddingScale),

        // Email / Username input
        _buildTextField(
          controller: _emailController,
          hintText: 'Kullanıcı Adı veya E-posta',
          prefixIcon: Icons.person,
          fontScale: fontScale,
          paddingScale: paddingScale,
        ),
        SizedBox(height: 20 * paddingScale),

        // Password input
        _buildTextField(
          controller: _passwordController,
          hintText: 'Şifre',
          isPassword: true,
          prefixIcon: Icons.lock,
          fontScale: fontScale,
          paddingScale: paddingScale,
        ),
        SizedBox(height: 30 * paddingScale),

        // Login button
        SizedBox(
          width: double.infinity,
          height: 50 * paddingScale,
          child: ElevatedButton(
            onPressed: _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0 * paddingScale),
              ),
            ),
            child: Text(
              'Giriş Yap',
              style: TextStyle(
                fontSize: 16 * fontScale,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (_errorMessage != null)
          Padding(
            padding: EdgeInsets.only(top: 10 * paddingScale),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 14 * fontScale),
            ),
          ),
        SizedBox(height: 20 * paddingScale),

        // Forgot password text
        TextButton(
          onPressed: () {
            NavigationService.navigateTo(context, const ForgotPasswordScreen());
          },
          child: Text(
            'Şifremi Unuttum',
            style: TextStyle(color: Colors.white70, fontSize: 14 * fontScale),
          ),
        ),
      ],
    );
  }

  // Tablet ve masaüstü için düzen
  Widget _buildTabletDesktopLayout(double fontScale, double paddingScale) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600 * paddingScale),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 40 * paddingScale),
            // Logo (biraz daha büyük)
            Center(
              child: Image.asset(
                'assets/logo2.png',
                height: 180 * paddingScale,
              ),
            ),
            SizedBox(height: 60 * paddingScale),

            // Email / Username input
            _buildTextField(
              controller: _emailController,
              hintText: 'Kullanıcı Adı veya E-posta',
              prefixIcon: Icons.person,
              fontScale: fontScale,
              paddingScale: paddingScale,
            ),
            SizedBox(height: 20 * paddingScale),

            // Password input
            _buildTextField(
              controller: _passwordController,
              hintText: 'Şifre',
              isPassword: true,
              prefixIcon: Icons.lock,
              fontScale: fontScale,
              paddingScale: paddingScale,
            ),
            SizedBox(height: 30 * paddingScale),

            // Login button
            SizedBox(
              width: double.infinity,
              height: 60 * paddingScale,
              child: ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0 * paddingScale),
                  ),
                ),
                child: Text(
                  'Giriş Yap',
                  style: TextStyle(
                    fontSize: 18 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(top: 10 * paddingScale),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red, fontSize: 16 * fontScale),
                ),
              ),
            SizedBox(height: 30 * paddingScale),

            // Forgot password text
            TextButton(
              onPressed: () {
                NavigationService.navigateTo(
                  context,
                  const ForgotPasswordScreen(),
                );
              },
              child: Text(
                'Şifremi Unuttum',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16 * fontScale,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Giriş yapmak için fonksiyon
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta ve şifre girin';
      });
      return;
    }
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.signIn(email, password);
    if (success) {
      NavigationService.navigateTo(context, const HomeScreen(), replace: true);
    } else {
      setState(() {
        _errorMessage = authProvider.errorMessage ?? 'Giriş başarısız';
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool isPassword = false,
    required double fontScale,
    required double paddingScale,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: TextStyle(color: Colors.white, fontSize: 16 * fontScale),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey, fontSize: 16 * fontScale),
        prefixIcon: Icon(prefixIcon, color: Colors.grey, size: 24 * fontScale),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 24 * fontScale,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
                : null,
        filled: true,
        fillColor: Colors.grey[900],
        contentPadding: EdgeInsets.symmetric(
          vertical: 16.0 * paddingScale,
          horizontal: 20.0 * paddingScale,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0 * paddingScale),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
