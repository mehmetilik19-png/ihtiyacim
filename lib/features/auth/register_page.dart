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

    final email = emailC.text.trim();
    final password = passC.text.trim();
    final password2 = pass2C.text.trim();

    if (email.isEmpty) {
      setState(() => error = 'E-posta boş olamaz.');
      return;
    }

    if (password.isEmpty || password2.isEmpty) {
      setState(() => error = 'Şifre boş olamaz.');
      return;
    }

    if (password != password2) {
      setState(() => error = 'Şifreler aynı değil.');
      return;
    }

    if (password.length < 6) {
      setState(() => error = 'Şifre en az 6 karakter olmalı.');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap oluşturuldu')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => error = _trError(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = 'Bir hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
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
            onPressed: loading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          TextField(
            controller: emailC,
            enabled: !loading,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-posta',
              hintText: 'ornek@mail.com',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passC,
            enabled: !loading,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Şifre Belirle',
              hintText: 'Uygulama için yeni şifre oluştur',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: pass2C,
            enabled: !loading,
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
            onPressed: loading ? null : () => Navigator.pop(context),
            child: const Text('Zaten hesabın var mı? Girişe dön'),
          ),
        ],
      ),
    );
  }
}
