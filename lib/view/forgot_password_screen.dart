import 'package:flutter/material.dart';
import 'package:gym_reservation/view/home_screen.dart';
import 'package:gym_reservation/utils/page_transition.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  void _sendVerificationCode() {
    // Burada normalde API çağrısı yapılacak
    setState(() {
      _codeSent = true;
    });
  }

  void _verifyCode() {
    // Burada normalde API çağrısı yapılacak ve kod doğrulanacak
    // Şimdilik direkt olarak ana sayfaya yönlendiriyoruz
    NavigationService.navigateTo(context, const HomeScreen(), replace: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Şifre Sıfırlama',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text(
                _codeSent ? 'Doğrulama Kodu' : 'Şifremi Unuttum',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _codeSent
                    ? 'E-posta adresinize gönderilen doğrulama kodunu giriniz.'
                    : 'Şifrenizi sıfırlamak için e-posta adresinizi giriniz.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
              ),

              const SizedBox(height: 40),

              // E-posta girişi veya Doğrulama kodu girişi
              if (!_codeSent) ...[
                _buildTextField(
                  controller: _emailController,
                  labelText: 'E-posta Adresi',
                  hintText: 'E-posta adresinizi giriniz',
                  iconData: Icons.email,
                ),

                const SizedBox(height: 30),

                // Doğrulama kodu gönder butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _emailController.text.isEmpty
                            ? null
                            : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0EA5E9), // Camgöbeği
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Doğrulama Kodu Gönder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Doğrulama kodu girişi
                _buildTextField(
                  controller: _verificationCodeController,
                  labelText: 'Doğrulama Kodu',
                  hintText: 'Doğrulama kodunu giriniz',
                  iconData: Icons.lock,
                ),

                const SizedBox(height: 30),

                // Onayla butonu
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _verificationCodeController.text.isEmpty
                            ? null
                            : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E), // Yeşil
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    child: const Text(
                      'Onayla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Kod gelmedi mi? Tekrar gönder
                TextButton(
                  onPressed: _sendVerificationCode,
                  child: const Text(
                    'Kod gelmedi mi? Tekrar gönder',
                    style: TextStyle(color: Color(0xFF0EA5E9), fontSize: 14),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData iconData,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(iconData, color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.grey.shade900,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
      ),
      onChanged: (text) {
        setState(
          () {},
        ); // TextField'ın durumuna göre butonun aktif/pasif olması için
      },
    );
  }
}
