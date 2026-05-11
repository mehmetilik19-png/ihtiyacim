import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final pass2C = TextEditingController();

  bool loading = false;
  String? error;

  @override
  void dispose() {
    emailC.dispose();
    passC.dispose();
    pass2C.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final email = emailC.text.trim();

      if (email.isEmpty) {
        setState(() => error = 'E-posta boş olamaz.');
        return;
      }

      if (passC.text != pass2C.text) {
        setState(() => error = 'Şifreler aynı değil.');
        return;
      }

      if (passC.text.trim().length < 6) {
        setState(() => error = 'Şifre en az 6 karakter olmalı.');
        return;
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: passC.text.trim(),
      );

      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() => error = _trError(e.code));
    } catch (e) {
      if (mounted) setState(() => error = 'Bir hata oluştu: $e');
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
        return 'Şifre çok zayıf.';
      case 'operation-not-allowed':
        return 'E-posta giriş yöntemi kapalı.';
      default:
        return 'Kayıt başarısız. Hata kodu: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap Oluştur'),
        actions: [
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
            // 🔥 AÇIKLAMA
            const Text(
              'E-postanı yaz, uygulama için yeni bir şifre belirle.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 14),

            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // 📧 E-POSTA
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                hintText: 'ornek@mail.com',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // 🔒 ŞİFRE BELİRLE
            TextField(
              controller: passC,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre Belirle',
                hintText: 'Uygulama için yeni şifre oluştur',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            // 🔒 ŞİFRE TEKRAR
            TextField(
              controller: pass2C,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifreyi Tekrar Yaz',
                hintText: 'Belirlediğin şifreyi tekrar yaz',
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
                    : const Text('Hesap Oluştur'),
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