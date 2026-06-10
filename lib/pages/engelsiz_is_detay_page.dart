import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/engelsiz_is_model.dart';

class EngelsizIsDetayPage extends StatelessWidget {
  const EngelsizIsDetayPage({
    super.key,
    required this.item,
  });

  final EngelsizIsModel item;

  String get _module => 'engelsiz_is';

  DatabaseReference get _itemRef =>
      FirebaseDatabase.instance.ref('engelsiz_is/items/${item.id}');

  String _ownerId() => item.ownerId.trim();

  Future<void> _reportItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    await FirebaseDatabase.instance.ref('reports').push().set({
      'module': _module,
      'itemId': item.id,
      'itemTitle': item.title,
      'reportedUserId': _ownerId(),
      'reporterUserId': user?.uid ?? '',
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
      'itemTitle': item.title,
      'createdAt': ServerValue.timestamp,
    });

    await FirebaseDatabase.instance.ref('blocked_users/${user.uid}/$ownerId').set({
      'blockedUserId': ownerId,
      'module': _module,
      'itemId': item.id,
      'itemTitle': item.title,
      'createdAt': ServerValue.timestamp,
    });

    await FirebaseDatabase.instance.ref('reports').push().set({
      'module': _module,
      'itemId': item.id,
      'itemTitle': item.title,
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
    final typeText = item.type == 'is_arayan' ? 'İş Arayan' : 'İşçi Arayan';

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isOwner = _ownerId().isNotEmpty && _ownerId() == uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detay'),
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
                  child: Text('Sil'),
                ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(typeText)),
              Chip(label: Text(item.category)),
              Chip(label: Text(item.city)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.desc,
            style: const TextStyle(
              fontSize: 15,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'İletişim',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              title: Text(item.contactName),
              subtitle: Text(
                'Tel: ${item.phone}\n'
                    'WP: ${item.whatsapp.isEmpty ? '-' : item.whatsapp}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}