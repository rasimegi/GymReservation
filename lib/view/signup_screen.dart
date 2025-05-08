import 'package:flutter/material.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:gym_reservation/firebase/providers/auth_provider.dart';
import 'package:gym_reservation/responsive_helper.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Responsive değerleri al
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    // AuthProvider'ı dinle
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Yeni Hesap Oluştur',
          style: TextStyle(color: Colors.white, fontSize: 20 * fontScale),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0 * paddingScale),
            child: ResponsiveHelper.getResponsiveLayout(
              context: context,
              mobile: _buildMobileLayout(authProvider, fontScale, paddingScale),
              tablet: _buildTabletDesktopLayout(
                authProvider,
                fontScale,
                paddingScale,
              ),
              desktop: _buildTabletDesktopLayout(
                authProvider,
                fontScale,
                paddingScale,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mobil cihazlar için düzen
  Widget _buildMobileLayout(
    AuthProvider authProvider,
    double fontScale,
    double paddingScale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hesap bilgilerinizi girin',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20 * fontScale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 30 * paddingScale),

        // Ad input
        _buildTextField(
          controller: _nameController,
          hintText: 'Ad',
          prefixIcon: Icons.person_outline,
          fontScale: fontScale,
          paddingScale: paddingScale,
        ),
        SizedBox(height: 20 * paddingScale),

        // Soyad input
        _buildTextField(
          controller: _surnameController,
          hintText: 'Soyad',
          prefixIcon: Icons.person_outline,
          fontScale: fontScale,
          paddingScale: paddingScale,
        ),
        SizedBox(height: 20 * paddingScale),

        // Kullanıcı Adı input
        _buildTextField(
          controller: _usernameController,
          hintText: 'Kullanıcı Adı',
          prefixIcon: Icons.person,
          fontScale: fontScale,
          paddingScale: paddingScale,
        ),
        SizedBox(height: 20 * paddingScale),

        // Email input
        _buildTextField(
          controller: _emailController,
          hintText: 'E-posta',
          prefixIcon: Icons.email,
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
        SizedBox(height: 20 * paddingScale),

        // Hata mesajı gösterme
        if (_errorMessage != null || authProvider.errorMessage != null)
          Padding(
            padding: EdgeInsets.only(bottom: 20 * paddingScale),
            child: Text(
              _errorMessage ?? authProvider.errorMessage ?? '',
              style: TextStyle(color: Colors.red, fontSize: 14 * fontScale),
            ),
          ),

        SizedBox(height: 20 * paddingScale),

        // Sign Up Button
        SizedBox(
          width: double.infinity,
          height: 50 * paddingScale,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _signUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0 * paddingScale),
              ),
            ),
            child:
                _isLoading
                    ? CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3 * fontScale,
                    )
                    : Text(
                      'Kaydol',
                      style: TextStyle(
                        fontSize: 16 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  // Tablet ve Masaüstü için düzen
  Widget _buildTabletDesktopLayout(
    AuthProvider authProvider,
    double fontScale,
    double paddingScale,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 600 * paddingScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hesap bilgilerinizi girin',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 40 * paddingScale),

            // Ad ve Soyad yan yana
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _nameController,
                    hintText: 'Ad',
                    prefixIcon: Icons.person_outline,
                    fontScale: fontScale,
                    paddingScale: paddingScale,
                  ),
                ),
                SizedBox(width: 16 * paddingScale),
                Expanded(
                  child: _buildTextField(
                    controller: _surnameController,
                    hintText: 'Soyad',
                    prefixIcon: Icons.person_outline,
                    fontScale: fontScale,
                    paddingScale: paddingScale,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24 * paddingScale),

            // Kullanıcı Adı input
            _buildTextField(
              controller: _usernameController,
              hintText: 'Kullanıcı Adı',
              prefixIcon: Icons.person,
              fontScale: fontScale,
              paddingScale: paddingScale,
            ),
            SizedBox(height: 24 * paddingScale),

            // Email input
            _buildTextField(
              controller: _emailController,
              hintText: 'E-posta',
              prefixIcon: Icons.email,
              fontScale: fontScale,
              paddingScale: paddingScale,
            ),
            SizedBox(height: 24 * paddingScale),

            // Password input
            _buildTextField(
              controller: _passwordController,
              hintText: 'Şifre',
              isPassword: true,
              prefixIcon: Icons.lock,
              fontScale: fontScale,
              paddingScale: paddingScale,
            ),
            SizedBox(height: 24 * paddingScale),

            // Hata mesajı gösterme
            if (_errorMessage != null || authProvider.errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 24 * paddingScale),
                child: Text(
                  _errorMessage ?? authProvider.errorMessage ?? '',
                  style: TextStyle(color: Colors.red, fontSize: 16 * fontScale),
                ),
              ),

            SizedBox(height: 16 * paddingScale),

            // Sign Up Button
            Center(
              child: SizedBox(
                width: 300 * paddingScale,
                height: 60 * paddingScale,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0 * paddingScale),
                    ),
                  ),
                  child:
                      _isLoading
                          ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3 * fontScale,
                          )
                          : Text(
                            'Kaydol',
                            style: TextStyle(
                              fontSize: 18 * fontScale,
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10 * paddingScale),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 20 * paddingScale,
          vertical: 16 * paddingScale,
        ),
      ),
    );
  }

  void _signUp() async {
    // Kullanıcı bilgileri kontrolü
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _surnameController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen tüm alanları doldurun';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // AuthProvider üzerinden kayıt işlemi
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Önce signUp ile kullanıcı oluştur
      bool success = await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _usernameController.text.trim(),
      );

      if (success) {
        // Kullanıcı profil bilgilerini güncelle
        await authProvider.updateUserProfile({
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
        });

        NavigationService.navigateTo(
          context,
          const HomeScreen(),
          replace: true,
        );
      } else {
        setState(() {
          _errorMessage = authProvider.errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
}
