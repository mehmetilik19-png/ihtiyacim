import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:ihtiyacim/models/ustam_model.dart';
import 'ustam_detay_page.dart';

enum ProfileItemsMode { favorites, recent }

class ProfileItemsPage extends StatefulWidget {
  final String title;
  final ProfileItemsMode mode;
  final String moduleKey;

  const ProfileItemsPage({
    super.key,
    required this.title,
    required this.mode,
    required this.moduleKey,
  });

  @override
  State<ProfileItemsPage> createState() => _ProfileItemsPageState();
}

class _ProfileItemsPageState extends State<ProfileItemsPage> {
  final _db = FirebaseDatabase.instance.ref();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  DatabaseReference get _listRef {
    final base = widget.mode == ProfileItemsMode.favorites ? 'favorites' : 'recent';
    return _db.child('users/$_uid/$base/${widget.moduleKey}');
  }

  // ✅ RTDB'deki gerçek ilanların durduğu yer (senin ekran görüntünden)
  String get _dataPath {
    switch (widget.moduleKey) {
      case 'ustam':
        return 'ustam/items';
      case 'market':
        return 'market/items';
      case 'can_dostum':
        return 'can_dostum/items';
      case 'esya_paylas':
        return 'esya_paylas/items';
      case 'gecerken_beni_de_al':
        return 'gecerken_beni_de_al/items';
      case 'engelsiz_is':
        return 'engelsiz_is/listings';
      case 'game':
        return 'game/items';
      default:
        return '${widget.moduleKey}/items';
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<Map<String, dynamic>?> _fetchItem(String id) async {
    final snap = await _db.child('$_dataPath/$id').get();
    final v = snap.value;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  String _pickString(Map<String, dynamic> m, List<String> keys, {String fallback = ''}) {
    for (final k in keys) {
      final v = m[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }

  List<String> _pickPhotos(Map<String, dynamic> m) {
    final raw = m['photoUrls'] ?? m['photos'] ?? m['images'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return <String>[];
  }

  int _pickInt(Map<String, dynamic> m, List<String> keys, {int fallback = 0}) {
    for (final k in keys) {
      final v = m[k];
      if (v is int) return v;
      if (v is num) return v.toInt();
      final parsed = int.tryParse((v ?? '').toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  Future<void> _removeFromList(String id) async {
    try {
      await _listRef.child(id).remove();
      _snack(widget.mode == ProfileItemsMode.favorites ? 'Favoriden kaldırıldı' : 'Geçmişten kaldırıldı');
    } catch (e) {
      _snack('Hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = widget.mode == ProfileItemsMode.favorites;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: StreamBuilder<DatabaseEvent>(
        stream: _listRef.onValue,
        builder: (_, s) {
          final val = s.data?.snapshot.value;

          if (val == null) {
            return const Center(child: Text('Kayıt yok'));
          }
          if (val is! Map) {
            return const Center(child: Text('Kayıt formatı hatalı'));
          }

          // ids
          final ids = val.keys.map((e) => e.toString()).toList();

          // recent: lastSeen varsa ona göre sırala (yoksa id sırası)
          if (!isFav) {
            ids.sort((a, b) {
              final ma = (val[a] is Map) ? Map<dynamic, dynamic>.from(val[a]) : <dynamic, dynamic>{};
              final mb = (val[b] is Map) ? Map<dynamic, dynamic>.from(val[b]) : <dynamic, dynamic>{};
              final ta = (ma['lastSeen'] is int) ? ma['lastSeen'] as int : 0;
              final tb = (mb['lastSeen'] is int) ? mb['lastSeen'] as int : 0;
              return tb.compareTo(ta);
            });
          }

          return FutureBuilder<List<_ProfileItemVM>>(
            future: _buildItems(ids),
            builder: (_, f) {
              if (!f.hasData) return const Center(child: CircularProgressIndicator());
              final items = f.data!;
              if (items.isEmpty) return const Center(child: Text('Kayıt yok'));

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final x = items[i];

                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.black.withOpacity(0.08)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: x.coverUrl == null
                            ? Container(
                          width: 56,
                          height: 56,
                          color: Colors.black.withOpacity(0.05),
                          child: const Icon(Icons.image_outlined),
                        )
                            : Image.network(
                          x.coverUrl!,
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.black.withOpacity(0.05),
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                      title: Text(
                        x.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        x.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        tooltip: isFav ? 'Favoriden kaldır' : 'Geçmişten kaldır',
                        onPressed: () => _removeFromList(x.id),
                        icon: Icon(isFav ? Icons.favorite : Icons.history),
                      ),
                      // Şimdilik: sadece liste (detaya bağlamayı B adımında net yapacağız)
                      // Çünkü her modülün detay sayfası farklı.
                      onTap: () async {
                        if (widget.moduleKey == 'ustam') {
                          final snap = await FirebaseDatabase.instance
                              .ref('ustam/items/${x.id}')
                              .get();

                          if (snap.value is Map) {
                            final model = UstamModel.fromMap(
                              x.id,
                              Map<String, dynamic>.from(snap.value as Map),
                            );

                            if (!mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UstamDetayPage(ustam: model),
                              ),
                            );
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_ProfileItemVM>> _buildItems(List<String> ids) async {
    // RTDB'yi yormamak için tek tek çekiyoruz (büyük listelerde daha stabil)
    final out = <_ProfileItemVM>[];

    for (final id in ids) {
      final m = await _fetchItem(id);
      if (m == null) continue;

      final title = _pickString(m, ['title', 'name', 'baslik'], fallback: 'İlan');
      final city = _pickString(m, ['city', 'il'], fallback: '');
      final job = _pickString(m, ['job', 'category', 'meslek'], fallback: '');
      final desc = _pickString(m, ['desc', 'description', 'aciklama'], fallback: '');

      final photos = _pickPhotos(m);
      final cover = photos.isNotEmpty ? photos.first : null;

      // createdAt vs (istersen ileride sıralamada kullanırız)
      _pickInt(m, ['createdAt', 'created_at', 'time'], fallback: 0);

      final subtitleParts = <String>[
        if (job.isNotEmpty) job,
        if (city.isNotEmpty) city,
        if (desc.isNotEmpty) desc,
      ];

      out.add(
        _ProfileItemVM(
          id: id,
          title: title,
          subtitle: subtitleParts.join(' • '),
          coverUrl: cover,
        ),
      );
    }

    return out;
  }
}

class _ProfileItemVM {
  final String id;
  final String title;
  final String subtitle;
  final String? coverUrl;

  _ProfileItemVM({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.coverUrl,
  });
}