import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/gecerken_model.dart';
import '../services/user_activity_service.dart';

class GecerkenDetayPage extends StatelessWidget {
  final GecerkenModel item;

  const GecerkenDetayPage({
    super.key,
    required this.item,
  });

  String get _module => 'gecerken_beni_de_al';

  DatabaseReference get _itemRef =>
      FirebaseDatabase.instance.ref('gecerken_beni_de_al/items/${item.id}');

  String _ownerId() => item.ownerId.trim();

  String _title() {
    return item.title.isEmpty ? '${item.fromWhere} → ${item.toWhere}' : item.title;
  }

  Future<void> _reportItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şikayet etmek için giriş yapmalısın.')),
      );
      return;
    }

    await FirebaseDatabase.instance.ref('reports').push().set({
      'module': _module,
      'itemId': item.id,
      'itemTitle': _title(),
      'reportedUserId': _ownerId(),
      'reporterUserId': user.uid,
      'reason': 'Uygunsuz içerik',
      'createdAt': ServerValue.timestamp,
      'status': 'pending',
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('İlan şikayet edildi. İncelenecek.')),
    );
  }

  Future<void> _blockUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kullanıcı engellemek için giriş yapmalısın.')),
      );
      return;
    }

    final ownerId = _ownerId();

    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ilanda kullanıcı bilgisi eksik.')),
      );
      return;
    }

    if (ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kendi ilanını engelleyemezsin.')),
      );
      return;
    }

    await FirebaseDatabase.instance
        .ref('users/${user.uid}/blocked_users/$ownerId')
        .set({
      'blockedUserId': ownerId,
      'module': _module,
      'itemId': item.id,
      'itemTitle': _title(),
      'createdAt': ServerValue.timestamp,
    });

    await FirebaseDatabase.instance
        .ref('blocked_users/${user.uid}/$ownerId')
        .set({
      'blockedUserId': ownerId,
      'blockedBy': user.uid,
      'module': _module,
      'itemId': item.id,
      'itemTitle': _title(),
      'createdAt': ServerValue.timestamp,
    });

    await FirebaseDatabase.instance.ref('reports').push().set({
      'module': _module,
      'itemId': item.id,
      'itemTitle': _title(),
      'reportedUserId': ownerId,
      'reporterUserId': user.uid,
      'reason': 'Kullanıcı engellendi',
      'createdAt': ServerValue.timestamp,
      'status': 'pending',
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı engellendi ve içerik bildirildi.')),
    );
  }

  Future<void> _deleteItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final isOwner = _ownerId().isNotEmpty && _ownerId() == uid;

    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu ilanı silme yetkin yok.')),
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
      const SnackBar(content: Text('İlan silindi.')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final photos = item.photoUrls;
    final cover = photos.isNotEmpty ? photos.first : null;
    final title = _title();

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = _ownerId().isNotEmpty && _ownerId() == uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('İlan Detayı'),
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
              if (!isOwner)
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Şikayet Et'),
                ),
              if (!isOwner)
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
              itemId: item.id,
            ),
            builder: (context, snap) {
              final isFav = snap.data ?? false;

              return IconButton(
                tooltip: isFav ? 'Favoriden çıkar' : 'Favoriye ekle',
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                onPressed: () async {
                  await UserActiveService.instance.toggleFavorite(
                    module: _module,
                    itemId: item.id,
                    payload: {
                      'title': title,
                      'subtitle': '${item.role} • ${item.city}',
                      'photo': cover ?? '',
                    },
                  );

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFav ? 'Favoriden çıkarıldı' : 'Favorilere eklendi',
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
        padding: const EdgeInsets.all(12),
        children: [
          if (photos.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: photos.length,
                  itemBuilder: (context, i) {
                    return Image.network(
                      photos[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 48),
                      ),
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      },
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Icon(Icons.image_not_supported, size: 48),
              ),
            ),

          const SizedBox(height: 14),

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: item.role),
              _Chip(text: item.city),
              _Chip(text: 'Foto: ${photos.length}'),
            ],
          ),

          const SizedBox(height: 14),

          _RowInfo(label: 'Nereden', value: item.fromWhere),
          _RowInfo(label: 'Nereye', value: item.toWhere),

          const SizedBox(height: 14),

          const Text(
            'Not',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            item.note.isEmpty ? 'Not yok.' : item.note,
            style: const TextStyle(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({
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
        color: const Color(0xFFF3EEF5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RowInfo extends StatelessWidget {
  final String label;
  final String value;

  const _RowInfo({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
            child: Text(value.isEmpty ? '-' : value)),
      ],
    );
  }
}