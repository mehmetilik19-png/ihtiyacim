import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class MyListingsPage extends StatefulWidget {
  final String uid;
  final String moduleKey; // esya_paylas, can_dostum...
  final String moduleTitle; // "Eşya Paylaş" vb.
  final String groupTitle; // "İlanlarım" / "Favoriler" / "Son Baktıklarım"
  final String itemsPath; // esya_paylas/items vb.

  /// ✅ ProfilePage senden "mode" gönderiyor diye ekledim.
  /// "my" / "fav" / "recent"
  final String? mode;

  const MyListingsPage({
    super.key,
    required this.uid,
    required this.moduleKey,
    required this.moduleTitle,
    required this.groupTitle,
    required this.itemsPath,
    this.mode,
  });

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final _db = FirebaseDatabase.instance.ref();

  bool get _isMy {
    final m = (widget.mode ?? '').toLowerCase();
    if (m.isNotEmpty) return m == 'my';
    return widget.groupTitle.toLowerCase().contains('ilan');
  }

  bool get _isFav {
    final m = (widget.mode ?? '').toLowerCase();
    if (m.isNotEmpty) return m == 'fav';
    return widget.groupTitle.toLowerCase().contains('favor');
  }

  bool get _isRecent {
    final m = (widget.mode ?? '').toLowerCase();
    if (m.isNotEmpty) return m == 'recent';
    return widget.groupTitle.toLowerCase().contains('son');
  }

  DatabaseReference get _itemsRef => _db.child(widget.itemsPath);

  DatabaseReference get _favModuleRef =>
      _db.child('users/${widget.uid}/favorites/${widget.moduleKey}');

  DatabaseReference get _recentModuleRef =>
      _db.child('users/${widget.uid}/recent/${widget.moduleKey}');

  // ------------------ STREAM ------------------

  Stream<List<_RowItem>> _streamRows() {
    if (_isMy) {
      // İLANLARIM: itemsPath'ten ownerId == uid filtrele
      return _itemsRef.onValue.map((ev) {
        final v = ev.snapshot.value;
        if (v == null) return <_RowItem>[];

        final map = Map<dynamic, dynamic>.from(v as Map);
        final out = <_RowItem>[];

        map.forEach((id, value) {
          if (value is Map) {
            final m = Map<dynamic, dynamic>.from(value);
            final ownerId = (m['ownerId'] ?? m['userId'] ?? '').toString();
            final status = (m['status'] ?? 'active').toString();

            if (ownerId == widget.uid && status != 'deleted') {
              out.add(
                _RowItem(
                  id: id.toString(),
                  title: (m['title'] ?? '').toString(),
                  subtitle: _buildSubtitle(m),
                  photo: _firstPhoto(m),
                  ts: _toInt(m['createdAt']),
                  raw: m,
                ),
              );
            }
          }
        });

        out.sort((a, b) => b.ts.compareTo(a.ts));
        return out;
      });
    }

    // FAVORİ / RECENT: users/.../favorites veya users/.../recent altından oku
    final ref = _isFav ? _favModuleRef : _recentModuleRef;

    return ref.onValue.map((ev) {
      final v = ev.snapshot.value;
      if (v == null) return <_RowItem>[];

      final map = Map<dynamic, dynamic>.from(v as Map);
      final out = <_RowItem>[];

      map.forEach((id, value) {
        if (value is Map) {
          final m = Map<dynamic, dynamic>.from(value);

          // fav: savedAt, recent: viewedAt/lastSeen
          final ts = _toInt(m['savedAt']) != 0
              ? _toInt(m['savedAt'])
              : (_toInt(m['viewedAt']) != 0
              ? _toInt(m['viewedAt'])
              : _toInt(m['lastSeen']));

          out.add(
            _RowItem(
              id: id.toString(),
              title: (m['title'] ?? '').toString(),
              subtitle: (m['subtitle'] ?? '').toString(),
              photo: (m['photo'] ?? '').toString(),
              ts: ts,
              raw: m,
            ),
          );
        } else {
          // bazı yerlerde sadece timestamp tutulmuş olabilir
          out.add(
            _RowItem(
              id: id.toString(),
              title: '',
              subtitle: '',
              photo: '',
              ts: 0,
              raw: const {},
            ),
          );
        }
      });

      out.sort((a, b) => b.ts.compareTo(a.ts));
      return out;
    });
  }

  // Eğer fav/recent içinde title boş gelirse, itemsPath'ten ilanı çekip doldur.
  Future<_RowItem?> _fetchFromItems(String id, _RowItem fallback) async {
    try {
      final snap = await _itemsRef.child(id).get();
      if (!snap.exists || snap.value == null) return fallback;

      final m = Map<dynamic, dynamic>.from(snap.value as Map);
      return _RowItem(
        id: id,
        title: (m['title'] ?? fallback.title).toString(),
        subtitle: fallback.subtitle.isNotEmpty ? fallback.subtitle : _buildSubtitle(m),
        photo: fallback.photo.isNotEmpty ? fallback.photo : _firstPhoto(m),
        ts: fallback.ts != 0 ? fallback.ts : _toInt(m['createdAt']),
        raw: m,
      );
    } catch (_) {
      return fallback;
    }
  }

  // ------------------ ACTIONS ------------------

  Future<void> _removeFromFavOrRecent(String id) async {
    final ref = _isFav ? _favModuleRef.child(id) : _recentModuleRef.child(id);
    await ref.remove();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_isFav ? 'Favorilerden kaldırıldı' : 'Geçmişten kaldırıldı')),
    );
  }

  Future<void> _deleteMyItem(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İlan silinsin mi?'),
        content: const Text('Bu işlem geri alınamaz.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil')),
        ],
      ),
    );
    if (ok != true) return;

    await _itemsRef.child(id).update({'status': 'deleted'});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan silindi')));
  }

  Future<void> _editMyItem(String id) async {
    final snap = await _itemsRef.child(id).get();
    if (!snap.exists || snap.value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan bulunamadı')));
      return;
    }

    final m = Map<dynamic, dynamic>.from(snap.value as Map);

    final titleC = TextEditingController(text: (m['title'] ?? '').toString());
    final descC = TextEditingController(text: (m['desc'] ?? m['description'] ?? '').toString());
    final cityC = TextEditingController(text: (m['city'] ?? '').toString());
    final catC = TextEditingController(text: (m['category'] ?? m['job'] ?? m['type'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('İlanı Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleC,
                decoration: const InputDecoration(labelText: 'Başlık', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: catC,
                decoration: const InputDecoration(labelText: 'Kategori / Tür', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: cityC,
                decoration: const InputDecoration(labelText: 'Şehir', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descC,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Vazgeç')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kaydet')),
        ],
      ),
    );

    if (ok != true) return;

    final title = titleC.text.trim();
    final desc = descC.text.trim();
    final city = cityC.text.trim();
    final cat = catC.text.trim();

    final upd = <String, dynamic>{};
    if (title.isNotEmpty) upd['title'] = title;

    if (m.containsKey('desc')) {
      upd['desc'] = desc;
    } else if (m.containsKey('description')) {
      upd['description'] = desc;
    } else {
      upd['desc'] = desc;
    }

    if (m.containsKey('city') || city.isNotEmpty) upd['city'] = city;

    if (m.containsKey('category')) {
      upd['category'] = cat;
    } else if (m.containsKey('job')) {
      upd['job'] = cat;
    } else if (m.containsKey('type')) {
      upd['type'] = cat;
    } else {
      upd['category'] = cat;
    }

    await _itemsRef.child(id).update(upd);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan güncellendi ✅')));
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.groupTitle} • ${widget.moduleTitle}'),
      ),
      body: StreamBuilder<List<_RowItem>>(
        stream: _streamRows(),
        builder: (context, snap) {
          final items = snap.data ?? const <_RowItem>[];

          if (snap.connectionState == ConnectionState.waiting && items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                _isMy ? 'Bu modülde henüz ilanın yok.' : 'Burada kayıt yok.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.black.withOpacity(.06)),
            itemBuilder: (context, i) {
              final base = items[i];

              if (!_isMy && base.title.trim().isEmpty) {
                return FutureBuilder<_RowItem?>(
                  future: _fetchFromItems(base.id, base),
                  builder: (context, ss) {
                    final x = ss.data ?? base;
                    return _tile(x);
                  },
                );
              }

              return _tile(base);
            },
          );
        },
      ),
    );
  }

  Widget _tile(_RowItem x) {
    final title = x.title.trim().isEmpty ? '(Başlıksız)' : x.title;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: x.photo.trim().isEmpty
          ? const Icon(Icons.image_outlined)
          : ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          x.photo,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        x.subtitle.trim().isEmpty ? widget.moduleTitle : x.subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _isMy
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _editMyItem(x.id),
          ),
          IconButton(
            tooltip: 'Sil',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteMyItem(x.id),
          ),
        ],
      )
          : IconButton(
        tooltip: _isFav ? 'Favoriden kaldır' : 'Geçmişten kaldır',
        icon: const Icon(Icons.close),
        onPressed: () => _removeFromFavOrRecent(x.id),
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tıklandı: ${widget.moduleKey} / ${x.id}')),
        );
      },
    );
  }

  // ------------------ HELPERS ------------------

  static String _buildSubtitle(Map<dynamic, dynamic> m) {
    final cat = (m['category'] ?? m['petType'] ?? m['type'] ?? m['job'] ?? '').toString();
    final city = (m['city'] ?? '').toString();
    final parts = <String>[];
    if (cat.trim().isNotEmpty) parts.add(cat);
    if (city.trim().isNotEmpty) parts.add(city);
    return parts.join(' • ');
  }

  static String _firstPhoto(Map<dynamic, dynamic> m) {
    final raw = m['photoUrls'];
    if (raw is List && raw.isNotEmpty) return raw.first.toString();
    return '';
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse((v ?? '0').toString()) ?? 0;
  }
}

// ------------------ MODEL ------------------

class _RowItem {
  final String id;
  final String title;
  final String subtitle;
  final String photo;
  final int ts;
  final Map<dynamic, dynamic> raw;

  _RowItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.photo,
    required this.ts,
    required this.raw,
  });
}