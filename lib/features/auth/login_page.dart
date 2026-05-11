import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final loginC = TextEditingController(); // email veya telefon
  final passC = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    loginC.dispose();
    passC.dispose();
    super.dispose();
  }

  bool get isEmail => loginC.text.trim().contains('@');

  String _normalizePhoneTR(String raw) {
    var x = raw.trim().replaceAll(' ', '').replaceAll('-', '');
    if (x.startsWith('0')) x = x.substring(1);         // 05xx -> 5xx
    if (x.startsWith('90')) x = '+$x';                 // 90xxx -> +90xxx
    if (!x.startsWith('+')) x = '+90$x';               // 5xxx -> +905xxx
    return x;
  }

  Future<void> _login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (isEmail) {
        // 📧 E-POSTA: şifre zorunlu
        if (passC.text.isEmpty) {
          setState(() => error = 'Şifre zorunlu.');
          return;
        }

        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: loginC.text.trim(),
          password: passC.text,
        );
      } else {
        // 📞 TELEFON: SMS zorunlu (şifre yok)
        final phone = _normalizePhoneTR(loginC.text);

        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phone,
          verificationCompleted: (cred) async {
            await FirebaseAuth.instance.signInWithCredential(cred);
          },
          verificationFailed: (e) {
            setState(() => error = _trError(e.code));
          },
          codeSent: (verificationId, _) async {
            final smsCode = await _askSmsCode();
            if (smsCode == null || smsCode.isEmpty) return;

            final cred = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: smsCode,
            );
            await FirebaseAuth.instance.signInWithCredential(cred);
          },
          codeAutoRetrievalTimeout: (_) {},
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => error = _trError(e.code));
    } catch (_) {
      setState(() => error = 'Bir hata oluştu.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _trError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Şifre yanlış.';
      case 'invalid-email':
        return 'E-posta geçersiz.';
      case 'user-disabled':
        return 'Bu hesap devre dışı.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı.';
      case 'invalid-verification-code':
        return 'SMS kodu hatalı.';
      case 'invalid-phone-number':
        return 'Telefon numarası geçersiz.';
      default:
        return 'Giriş başarısız.';
    }
  }

  Future<String?> _askSmsCode() async {
    final c = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SMS Kodu'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '6 haneli kod'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Doğrula')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailMode = isEmail;

    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),

            TextField(
              controller: loginC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta veya Telefon',
                hintText: 'mail@ornek.com veya 5xxxxxxxxx',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}), // email/phone algısı güncellensin
            ),

            const SizedBox(height: 12),

            // ✅ SADECE E-POSTA MODUNDA ŞİFRE GÖSTER
            if (emailMode)
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                ),
              ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _login,
                child: loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(emailMode ? 'E-posta ile Giriş' : 'Telefon ile Giriş (SMS)'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
              },
              child: const Text('Hesabın yok mu? Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}