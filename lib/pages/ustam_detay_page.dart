import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ustam_model.dart';

class UstamDetayPage extends StatefulWidget {
  final UstamModel ustam;
  const UstamDetayPage({super.key, required this.ustam});

  @override
  State<UstamDetayPage> createState() => _UstamDetayPageState();
}

class _UstamDetayPageState extends State<UstamDetayPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _auth = FirebaseAuth.instance;

  String _uid = '';
  bool _isFav = false;

  // ✅ ProfilePage ile aynı yapı:
  // user_activity/<uid>/favorites/<module>/<itemId>/{title,subtitle,photo,ts}
  DatabaseReference get _favRef =>
      _db.child('user_activity/$_uid/favorites/ustam/${widget.ustam.id}');

  // ✅ ProfilePage ile aynı yapı:
  // user_activity/<uid>/history/<module>/<itemId>/{title,subtitle,photo,ts}
  DatabaseReference get _histRef =>
      _db.child('user_activity/$_uid/history/ustam/${widget.ustam.id}');

  bool get _isOwner => widget.ustam.ownerId == _uid && _uid.isNotEmpty;

  @override
  void initState() {
    super.initState();

    final user = _auth.currentUser;
    if (user == null) {
      // giriş yoksa favori/history yazmayacağız
      return;
    }

    _uid = user.uid;

    _markAsHistory(); // ✅ son baktım
    _listenFav();     // ✅ favori durumunu canlı takip
  }

  Map<String, dynamic> _payload() {
    final u = widget.ustam;
    final cover = u.photoUrls.isNotEmpty ? u.photoUrls.first : '';
    return {
      'title': u.title,
      'subtitle': '${u.job} • ${u.city}',
      'photo': cover,
      'ts': ServerValue.timestamp, // ✅ ProfilePage ts bekliyor
    };
  }

  Future<void> _markAsHistory() async {
    // ✅ Profilde "Son Baktıklarım" burada okunuyor
    await _histRef.set(_payload());
  }

  void _listenFav() {
    _favRef.onValue.listen((event) {
      if (!mounted) return;
      setState(() => _isFav = event.snapshot.exists);
    });
  }

  Future<void> _toggleFav() async {
    if (_uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favori için giriş yapmalısın')),
      );
      return;
    }

    if (_isFav) {
      await _favRef.remove();
    } else {
      await _favRef.set(_payload());
    }
    // _listenFav zaten güncelliyor; setState şart değil ama sorun olmaz
    if (mounted) setState(() => _isFav = !_isFav);
  }

  Future<void> _deleteIlan() async {
    await _db.child('ustam/items/${widget.ustam.id}').remove();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.ustam;

    return Scaffold(
      appBar: AppBar(
        title: Text(u.title),
        actions: [
          IconButton(
            tooltip: _isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
            icon: Icon(_isFav ? Icons.star : Icons.star_border),
            onPressed: _toggleFav,
          ),
          if (_isOwner)
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'delete') _deleteIlan();
                if (v == 'edit') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Düzenleme yakında')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (u.photoUrls.isNotEmpty)
            SizedBox(
              height: 220,
              child: PageView(
                children: u.photoUrls
                    .map(
                      (e) => Image.network(
                    e,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Center(child: Icon(Icons.broken_image)),
                  ),
                )
                    .toList(),
              ),
            )
          else
            Container(
              height: 180,
              color: Colors.black.withOpacity(0.05),
              child: const Icon(Icons.person, size: 60),
            ),

          const SizedBox(height: 16),

          Text(
            u.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            '${u.job} • ${u.city}',
            style: const TextStyle(color: Colors.black54),
          ),

          const SizedBox(height: 14),
          Text(u.desc),
        ],
      ),
    );
  }
}