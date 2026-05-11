import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final loginC = TextEditingController(); // e-posta veya telefon
  final passC = TextEditingController();
  final pass2C = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    loginC.dispose();
    passC.dispose();
    pass2C.dispose();
    super.dispose();
  }

  bool get isPhone {
    final v = loginC.text.trim();
    if (v.contains('@')) return false; // mail ise telefon sayma
    final digits = v.replaceAll(RegExp(r'\D'), '');
    return v.startsWith('+') || digits.length >= 10;
  }

  Future<void> _register() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      if (isPhone) {
        // 📞 TELEFON İLE KAYIT (SMS)
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: loginC.text.trim(),
          verificationCompleted: (cred) async {
            await FirebaseAuth.instance.signInWithCredential(cred);
            if (mounted) Navigator.pop(context); // AuthGate Home'a geçirir
          },
          verificationFailed: (e) {
            if (mounted) setState(() => error = _trError(e.code));
          },
          codeSent: (verificationId, _) async {
            final smsCode = await _askSmsCode();
            if (smsCode == null || smsCode.isEmpty) return;

            final cred = PhoneAuthProvider.credential(
              verificationId: verificationId,
              smsCode: smsCode,
            );

            await FirebaseAuth.instance.signInWithCredential(cred);

            if (mounted) Navigator.pop(context); // AuthGate Home'a geçirir
          },
          codeAutoRetrievalTimeout: (_) {},
        );
      } else {
        // 📧 E-POSTA İLE KAYIT
        if (passC.text != pass2C.text) {
          if (mounted) setState(() => error = 'Şifreler aynı değil.');
          return;
        }
        if (passC.text.trim().length < 6) {
          if (mounted) setState(() => error = 'Şifre en az 6 karakter olmalı.');
          return;
        }

        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: loginC.text.trim(),
          password: passC.text,
        );

        if (mounted) Navigator.pop(context); // AuthGate Home'a geçirir
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = _trError(e.code));
    } catch (_) {
      if (mounted) setState(() => error = 'Bir hata oluştu.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _trError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Bu e-posta zaten kayıtlı.';
      case 'invalid-email':
        return 'E-posta geçersiz.';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter).';
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi kapalı (Firebase ayarlarını kontrol et).';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen sonra tekrar dene.';
      case 'invalid-phone-number':
        return 'Telefon numarası geçersiz. Örn: +905xxxxxxxxx';
      case 'invalid-verification-code':
        return 'SMS kodu hatalı.';
      case 'session-expired':
        return 'SMS oturumu süresi doldu, tekrar dene.';
      default:
        return 'Kayıt başarısız.';
    }
  }

  Future<String?> _askSmsCode() async {
    final c = TextEditingController();

    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('SMS Kodu'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: '6 haneli kod'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, c.text.trim()),
            child: const Text('Doğrula'),
          ),
        ],
      ),
    );

    c.dispose();
    return res;
  }

  @override
  Widget build(BuildContext context) {
    final phoneMode = isPhone;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        actions: [
          // ✅ "Çıkış" yerine: Giriş ekranına dön (kayıt ekranında mantıklısı bu)
          IconButton(
            tooltip: 'Girişe Dön',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
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
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'E-posta veya Telefon',
                hintText: '+905xxxxxxxxx veya mail@ornek.com',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 12),

            // Telefon kayıt modunda şifre alanlarını kapat
            TextField(
              controller: passC,
              obscureText: true,
              enabled: !phoneMode,
              decoration: InputDecoration(
                labelText: 'Şifre',
                border: const OutlineInputBorder(),
                helperText: phoneMode ? 'Telefon kaydında şifre gerekmez.' : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pass2C,
              obscureText: true,
              enabled: !phoneMode,
              decoration: const InputDecoration(
                labelText: 'Şifre Tekrar',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : _register,
                child: loading
                    ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(phoneMode ? 'SMS ile Kayıt Ol' : 'Kayıt Ol'),
              ),
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zaten hesabın var mı? Girişe dön'),
            ),
          ],
        ),
      ),
    );
  }
}