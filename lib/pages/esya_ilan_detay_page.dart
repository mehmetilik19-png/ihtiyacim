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

  static const Color _bgColor = Color(0xFFF4F1E8);
  static const Color _cardColor = Color(0xFFFFFCF4);
  static const Color _primaryColor = Color(0xFF5F7867);
  static const Color _primarySoft = Color(0xFFDDE6DC);
  static const Color _borderColor = Color(0xFFD5DDD2);
  static const Color _textColor = Color(0xFF26352C);
  static const Color _mutedColor = Color(0xFF6D786F);

  String get _module => 'esya_paylas';

  DatabaseReference get _itemRef {
    return FirebaseDatabase.instance.ref(
      'esya_paylas/items/${ilan.id}',
    );
  }

  String _ownerId() {
    return ilan.ownerId.trim();
  }

  Future<void> _reportItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Şikayet etmek için giriş yapmalısın.',
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseDatabase.instance
          .ref('reports')
          .push()
          .set({
        'module': _module,
        'itemId': ilan.id,
        'itemTitle': ilan.title,
        'reportedUserId': _ownerId(),
        'reporterUserId': user.uid,
        'reason': 'Uygunsuz içerik',
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İlan şikayet edildi. İncelenecek.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Şikayet gönderilemedi: $error',
          ),
        ),
      );
    }
  }

  Future<void> _blockUser(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı engellemek için giriş yapmalısın.',
          ),
        ),
      );
      return;
    }

    final ownerId = _ownerId();

    if (ownerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu ilanda kullanıcı bilgisi eksik.',
          ),
        ),
      );
      return;
    }

    if (ownerId == user.uid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kendi ilanını engelleyemezsin.',
          ),
        ),
      );
      return;
    }

    try {
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

      await FirebaseDatabase.instance
          .ref('reports')
          .push()
          .set({
        'module': _module,
        'itemId': ilan.id,
        'itemTitle': ilan.title,
        'reportedUserId': ownerId,
        'reporterUserId': user.uid,
        'reason': 'Kullanıcı engellendi',
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
      });

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kullanıcı engellendi ve içerik bildirildi.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kullanıcı engellenemedi: $error',
          ),
        ),
      );
    }
  }

  Future<void> _deleteItem(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    final isOwner =
        _ownerId().isNotEmpty && _ownerId() == uid;

    if (!isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bu ilanı silme yetkin yok.',
          ),
        ),
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'İlan silinsin mi?',
            style: TextStyle(
              color: _textColor,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Bu işlem geri alınamaz.',
            style: TextStyle(
              color: _mutedColor,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Vazgeç'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await _itemRef.remove();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İlan silindi.'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İlan silinemedi: $error',
          ),
        ),
      );
    }
  }

  void _showImagePreview(
      BuildContext context,
      String imageUrl,
      ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(14),
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) {
                      return Container(
                        height: 300,
                        color: _primarySoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 60,
                          color: _primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cover =
    ilan.photoUrls.isNotEmpty ? ilan.photoUrls.first : null;

    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';

    final isOwner =
        _ownerId().isNotEmpty && _ownerId() == uid;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'İlan Detayı',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            iconColor: Colors.white,
            color: _cardColor,
            onSelected: (value) {
              if (value == 'report') {
                _reportItem(context);
              } else if (value == 'block') {
                _blockUser(context);
              } else if (value == 'delete') {
                _deleteItem(context);
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag_outlined,
                        color: _mutedColor,
                      ),
                      SizedBox(width: 10),
                      Text('Şikayet Et'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_rounded,
                        color: _mutedColor,
                      ),
                      SizedBox(width: 10),
                      Text('Kullanıcıyı Engelle'),
                    ],
                  ),
                ),
                if (isOwner)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Sil',
                          style: TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ];
            },
          ),
          StreamBuilder<bool>(
            stream: UserActiveService.instance.watchFavorite(
              module: _module,
              itemId: ilan.id,
            ),
            builder: (context, snapshot) {
              final isFavorite = snapshot.data ?? false;

              return IconButton(
                tooltip: isFavorite
                    ? 'Favoriden çıkar'
                    : 'Favoriye ekle',
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                ),
                onPressed: () async {
                  await UserActiveService.instance
                      .toggleFavorite(
                    module: _module,
                    itemId: ilan.id,
                    payload: {
                      'title': ilan.title,
                      'subtitle':
                      '${ilan.category} • ${ilan.city}',
                      'photo': cover ?? '',
                    },
                  );

                  if (!context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isFavorite
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
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          30,
        ),
        children: [
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                maxHeight: 235,
              ),
              decoration: BoxDecoration(
                color: _primarySoft,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _borderColor,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: cover == null
                    ? const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 68,
                    color: _primaryColor,
                  ),
                )
                    : InkWell(
                  onTap: () {
                    _showImagePreview(
                      context,
                      cover,
                    );
                  },
                  child: Image.network(
                    cover,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 50,
                          color: _primaryColor,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Text(
            ilan.title,
            style: const TextStyle(
              color: _textColor,
              fontSize: 23,
              height: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              _Tag(
                icon: Icons.category_outlined,
                text: ilan.category,
              ),
              _Tag(
                icon: Icons.location_on_outlined,
                text: ilan.city,
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _borderColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: _primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Açıklama',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ilan.desc.trim().isEmpty
                      ? 'Açıklama eklenmemiş.'
                      : ilan.desc,
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          if (ilan.photoUrls.length > 1) ...[
            const SizedBox(height: 20),
            const Text(
              'Diğer Fotoğraflar',
              style: TextStyle(
                color: _textColor,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ilan.photoUrls.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(width: 10);
                },
                itemBuilder: (context, index) {
                  final imageUrl =
                  ilan.photoUrls[index];

                  return InkWell(
                    borderRadius:
                    BorderRadius.circular(15),
                    onTap: () {
                      _showImagePreview(
                        context,
                        imageUrl,
                      );
                    },
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(15),
                      child: Image.network(
                        imageUrl,
                        width: 125,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            width: 125,
                            height: 100,
                            color: _primarySoft,
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: _primaryColor,
                            ),
                          );
                        },
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
  final IconData icon;
  final String text;

  const _Tag({
    required this.icon,
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
        color: const Color(0xFFDDE6DC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFC7D4C7),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 17,
            color: const Color(0xFF5F7867),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF395244),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}