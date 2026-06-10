import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/ilan_model.dart';
import '../services/user_activity_service.dart';

class EsyaIlanDetayPage extends StatelessWidget {
  final IlanModel ilan;

  const EsyaIlanDetayPage({
    super.key,
    required this.ilan,
  });

  static const Color _bgColor = Color(0xFFF8F4F6);
  static const Color _cardColor = Color(0xFFFFFAFB);
  static const Color _borderColor = Color(0xFFEADFE3);

  String get _module => 'esya_paylas';

  DatabaseReference get _itemRef =>
      FirebaseDatabase.instance.ref('esya_paylas/items/${ilan.id}');

  String _ownerId() => ilan.ownerId.trim();

  Future<void> _reportItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şikayet etmek için giriş yapmalısın.'),
        ),
      );
      return;
    }

    await FirebaseDatabase.instance.ref('reports').push().set({
      'module': _module,
      'itemId': ilan.id,
      'itemTitle': ilan.title,
      'reportedUserId': _ownerId(),
      'reporterUserId': user.uid,
      'reason': 'Uygunsuz içerik',
      'createdAt': ServerValue.timestamp,
      'status': 'pending',
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İlan şikayet edildi. İncelenecek.'),
      ),
    );
  }

  Future<void> _blockUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı engellemek için giriş yapmalısın.'),
        ),
      );
      return;
    }

    final ownerId = _ownerId();

    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu ilanda kullanıcı bilgisi eksik.'),
        ),
      );
      return;
    }

    if (ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi ilanını engelleyemezsin.'),
        ),
      );
      return;
    }

    await FirebaseDatabase.instance
        .ref('users/${user.uid}/blocked_users/$ownerId')
        .set({
      'blockedUserId': ownerId,
      'module': _module,
      'itemId': ilan.id,
      'itemTitle': ilan.title,
      'createdAt': ServerValue.timestamp,
    });

    await FirebaseDatabase.instance
        .ref('blocked_users/${user.uid}/$ownerId')
        .set({
      'blockedUserId': ownerId,
      'blockedBy': user.uid,
      'module': _module,
      'itemId': ilan.id,
      'itemTitle': ilan.title,
      'createdAt': ServerValue.timestamp,
    });

    await FirebaseDatabase.instance.ref('reports').push().set({
      'module': _module,
      'itemId': ilan.id,
      'itemTitle': ilan.title,
      'reportedUserId': ownerId,
      'reporterUserId': user.uid,
      'reason': 'Kullanıcı engellendi',
      'createdAt': ServerValue.timestamp,
      'status': 'pending',
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kullanıcı engellendi ve içerik bildirildi.'),
      ),
    );
  }

  Future<void> _deleteItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final isOwner = _ownerId().isNotEmpty && _ownerId() == uid;

    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bu ilanı silme yetkin yok.'),
        ),
      );
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İlan silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _itemRef.remove();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('İlan silindi.'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cover = ilan.photoUrls.isNotEmpty ? ilan.photoUrls.first : null;

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = _ownerId().isNotEmpty && _ownerId() == uid;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text('İlan Detayı'),
        backgroundColor: _bgColor,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'report') {
                _reportItem(context);
              } else if (value == 'block') {
                _blockUser(context);
              } else if (value == 'delete') {
                _deleteItem(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'report',
                child: Text('Şikayet Et'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Kullanıcıyı Engelle'),
              ),
              if (isOwner)
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Sil',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),

          StreamBuilder<bool>(
            stream: UserActiveService.instance.watchFavorite(
              module: _module,
              itemId: ilan.id,
            ),
            builder: (context, snap) {
              final isFav = snap.data ?? false;

              return IconButton(
                tooltip: isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                onPressed: () async {
                  await UserActiveService.instance.toggleFavorite(
                    module: _module,
                    itemId: ilan.id,
                    payload: {
                      'title': ilan.title,
                      'subtitle': '${ilan.category} • ${ilan.city}',
                      'photo': cover ?? '',
                    },
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav
                            ? 'Favoriden çıkarıldı'
                            : 'Favorilere eklendi',
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: cover == null
                  ? Container(
                color: Colors.black.withOpacity(0.05),
                child: const Icon(
                  Icons.image_outlined,
                  size: 72,
                ),
              )
                  : Image.network(
                cover,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          Text(
            ilan.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Tag(text: ilan.category),
              _Tag(text: ilan.city),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Açıklama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ilan.desc,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (ilan.photoUrls.length > 1) ...[
            const Text(
              'Fotoğraflar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ilan.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = ilan.photoUrls[i];

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      url,
                      width: 120,
                      height: 92,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        color: Colors.black12,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;

  const _Tag({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEADFE3),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}