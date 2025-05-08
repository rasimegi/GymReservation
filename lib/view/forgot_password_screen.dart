import 'package:flutter/material.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/view/login_screen.dart';
import 'package:gym_reservation/utils/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:gym_reservation/firebase/providers/auth_provider.dart';
import 'package:gym_reservation/responsive_helper.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _sendVerificationCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen e-posta adresinizi giriniz.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.resetPassword(email);

      if (success) {
        setState(() {
          _codeSent = true;
          _successMessage = 'Doğrulama kodu e-posta adresinize gönderildi.';
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage =
              authProvider.errorMessage ??
              'Bir hata oluştu. Lütfen tekrar deneyin.';
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bir hata oluştu: $e';
        _successMessage = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyCode() {
    // Firebase doğrudan şifre sıfırlama e-postası gönderdiği için burada
    // sadece kullanıcıyı login sayfasına yönlendiriyoruz
    NavigationService.navigateTo(context, const LoginScreen(), replace: true);
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = ResponsiveHelper.getFontScale(context);
    final paddingScale = ResponsiveHelper.getPaddingScale(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Şifre Sıfırlama',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20 * fontScale,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.0 * paddingScale),
          child: ResponsiveHelper.getResponsiveLayout(
            context: context,
            mobile: _buildMobileLayout(fontScale, paddingScale),
            tablet: _buildTabletDesktopLayout(fontScale, paddingScale),
            desktop: _buildTabletDesktopLayout(fontScale, paddingScale),
          ),
        ),
      ),
    );
  }

  // Mobil cihazlar için düzen
  Widget _buildMobileLayout(double fontScale, double paddingScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20 * paddingScale),

        Text(
          _codeSent ? 'Doğrulama Kodu Gönderildi' : 'Şifremi Unuttum',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * fontScale,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10 * paddingScale),

        Text(
          _codeSent
              ? 'E-posta adresinize gönderilen bağlantıya tıklayarak şifrenizi sıfırlayabilirsiniz.'
              : 'Şifrenizi sıfırlamak için e-posta adresinizi giriniz.',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16 * fontScale,
          ),
        ),

        SizedBox(height: 40 * paddingScale),

        _buildMessageContainers(fontScale, paddingScale),

        // E-posta girişi veya Doğrulama kodu girişi
        if (!_codeSent) ...[
          _buildTextField(
            controller: _emailController,
            labelText: 'E-posta Adresi',
            hintText: 'E-posta adresinizi giriniz',
            iconData: Icons.email,
            fontScale: fontScale,
            paddingScale: paddingScale,
          ),

          SizedBox(height: 30 * paddingScale),

          // Doğrulama kodu gönder butonu
          SizedBox(
            width: double.infinity,
            height: 50 * paddingScale,
            child: ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : _emailController.text.isEmpty
                      ? null
                      : _sendVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9), // Camgöbeği
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0 * paddingScale),
                ),
              ),
              child:
                  _isLoading
                      ? SizedBox(
                        height: 20 * paddingScale,
                        width: 20 * paddingScale,
                        child: CircularProgressIndicator(
                          strokeWidth: 2 * fontScale,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : Text(
                        'Doğrulama Kodu Gönder',
                        style: TextStyle(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ] else ...[
          // Doğrulama kodu gönderildiğinde bilgi mesajı
          Text(
            'E-posta adresinize gönderilen bağlantıya tıklayarak şifrenizi sıfırlayın.',
            style: TextStyle(color: Colors.white, fontSize: 16 * fontScale),
          ),

          SizedBox(height: 30 * paddingScale),

          // Giriş sayfasına dön butonu
          SizedBox(
            width: double.infinity,
            height: 50 * paddingScale,
            child: ElevatedButton(
              onPressed:
                  () => NavigationService.navigateTo(
                    context,
                    const LoginScreen(),
                    replace: true,
                  ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0 * paddingScale),
                ),
              ),
              child: Text(
                'Giriş Sayfasına Dön',
                style: TextStyle(
                  fontSize: 16 * fontScale,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Tablet ve masaüstü cihazlar için düzen
  Widget _buildTabletDesktopLayout(double fontScale, double paddingScale) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 500 * paddingScale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 40 * paddingScale),

            Text(
              _codeSent ? 'Doğrulama Kodu Gönderildi' : 'Şifremi Unuttum',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28 * fontScale,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 15 * paddingScale),

            Text(
              _codeSent
                  ? 'E-posta adresinize gönderilen bağlantıya tıklayarak şifrenizi sıfırlayabilirsiniz.'
                  : 'Şifrenizi sıfırlamak için e-posta adresinizi giriniz.',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 18 * fontScale,
              ),
            ),

            SizedBox(height: 50 * paddingScale),

            _buildMessageContainers(fontScale, paddingScale),

            // E-posta girişi veya Doğrulama kodu girişi
            if (!_codeSent) ...[
              _buildTextField(
                controller: _emailController,
                labelText: 'E-posta Adresi',
                hintText: 'E-posta adresinizi giriniz',
                iconData: Icons.email,
                fontScale: fontScale,
                paddingScale: paddingScale,
              ),

              SizedBox(height: 40 * paddingScale),

              // Doğrulama kodu gönder butonu
              Center(
                child: SizedBox(
                  width: 300 * paddingScale,
                  height: 60 * paddingScale,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : _emailController.text.isEmpty
                            ? null
                            : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9), // Camgöbeği
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10.0 * paddingScale,
                        ),
                      ),
                    ),
                    child:
                        _isLoading
                            ? SizedBox(
                              height: 24 * paddingScale,
                              width: 24 * paddingScale,
                              child: CircularProgressIndicator(
                                strokeWidth: 3 * fontScale,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              'Doğrulama Kodu Gönder',
                              style: TextStyle(
                                fontSize: 18 * fontScale,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ),
            ] else ...[
              // Doğrulama kodu gönderildiğinde bilgi mesajı
              Text(
                'E-posta adresinize gönderilen bağlantıya tıklayarak şifrenizi sıfırlayın.',
                style: TextStyle(color: Colors.white, fontSize: 18 * fontScale),
              ),

              SizedBox(height: 40 * paddingScale),

              // Giriş sayfasına dön butonu
              Center(
                child: SizedBox(
                  width: 300 * paddingScale,
                  height: 60 * paddingScale,
                  child: ElevatedButton(
                    onPressed:
                        () => NavigationService.navigateTo(
                          context,
                          const LoginScreen(),
                          replace: true,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10.0 * paddingScale,
                        ),
                      ),
                    ),
                    child: Text(
                      'Giriş Sayfasına Dön',
                      style: TextStyle(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Hata ve başarı mesajları
  Widget _buildMessageContainers(double fontScale, double paddingScale) {
    return Column(
      children: [
        if (_errorMessage != null)
          Container(
            padding: EdgeInsets.all(10 * paddingScale),
            margin: EdgeInsets.only(bottom: 20 * paddingScale),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * paddingScale),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24 * fontScale,
                ),
                SizedBox(width: 10 * paddingScale),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14 * fontScale,
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (_successMessage != null)
          Container(
            padding: EdgeInsets.all(10 * paddingScale),
            margin: EdgeInsets.only(bottom: 20 * paddingScale),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * paddingScale),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 24 * fontScale,
                ),
                SizedBox(width: 10 * paddingScale),
                Expanded(
                  child: Text(
                    _successMessage!,
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 14 * fontScale,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData iconData,
    required double fontScale,
    required double paddingScale,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white, fontSize: 16 * fontScale),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey, fontSize: 16 * fontScale),
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.withOpacity(0.5),
          fontSize: 14 * fontScale,
        ),
        prefixIcon: Icon(iconData, color: Colors.grey, size: 22 * fontScale),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * paddingScale),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16 * paddingScale,
          vertical: 16 * paddingScale,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }
}
