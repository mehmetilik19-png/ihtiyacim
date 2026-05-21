import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'my_listings_page.dart';
import 'package:ihtiyacim/features/orders/orders_page.dart';
import 'package:ihtiyacim/features/auth/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance;

  final Map<String, String> modulePaths = const {
    'esya_paylas': 'esya_paylas/items',
    'can_dostum': 'can_dostum/items',
    'engelsiz_is': 'engelsiz_is/items',
    'ustam': 'ustam/items',
    'gecerken_beni_de_al': 'gecerken_beni_de_al/items',
  };

  DatabaseReference _favRoot(String uid) => _db.ref('users/$uid/favorites');
  DatabaseReference _recentRoot(String uid) => _db.ref('users/$uid/recent');

  String _titleOf(String key) {
    switch (key) {
      case 'esya_paylas':
        return 'Eşya Paylaş';
      case 'can_dostum':
        return 'Can Dostum';
      case 'engelsiz_is':
        return 'Engelsiz İş';
      case 'ustam':
        return 'Ustam';
      case 'gecerken_beni_de_al':
        return 'Geçerken Beni de Al';
      default:
        return key;
    }
  }

  Stream<Map<String, int>> _favCounts(String uid) {
    return _moduleCountStream(_favRoot(uid));
  }

  Stream<Map<String, int>> _recentCounts(String uid) {
    return _moduleCountStream(_recentRoot(uid));
  }

  Stream<Map<String, int>> _myListingCounts(String uid) {
    final streams = modulePaths.entries.map((e) {
      final moduleKey = e.key;
      final path = e.value;

      return _db.ref(path).onValue.map((ev) {
        final v = ev.snapshot.value;
        if (v == null) return <String, int>{moduleKey: 0};

        final map = Map<dynamic, dynamic>.from(v as Map);
        int count = 0;

        map.forEach((id, value) {
          if (value is Map) {
            final m = Map<dynamic, dynamic>.from(value);
            final ownerId = (m['ownerId'] ?? m['userId'] ?? '').toString();
            final status = (m['status'] ?? 'active').toString();

            if (ownerId == uid && status != 'deleted') {
              count++;
            }
          }
        });

        return <String, int>{moduleKey: count};
      });
    }).toList();

    return _combineCountStreams(streams);
  }

  Stream<Map<String, int>> _moduleCountStream(DatabaseReference rootRef) {
    return rootRef.onValue.map((event) {
      final v = event.snapshot.value;
      if (v == null) return <String, int>{};

      final root = Map<dynamic, dynamic>.from(v as Map);
      final out = <String, int>{};

      root.forEach((moduleKey, moduleVal) {
        if (moduleVal is Map) {
          out[moduleKey.toString()] =
              Map<dynamic, dynamic>.from(moduleVal).length;
        }
      });

      return out;
    });
  }

  Stream<Map<String, int>> _combineCountStreams(
    List<Stream<Map<String, int>>> streams,
  ) {
    final ctrl = StreamController<Map<String, int>>.broadcast();
    final latest = <String, int>{};
    final subs = <StreamSubscription>[];

    void emit() => ctrl.add(Map<String, int>.from(latest));

    for (final s in streams) {
      subs.add(
        s.listen((data) {
          data.forEach((k, v) => latest[k] = v);
          emit();
        }),
      );
    }

    ctrl.onCancel = () async {
      for (final sub in subs) {
        await sub.cancel();
      }
      await ctrl.close();
    };

    return ctrl.stream;
  }

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openMyOrders() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrdersPage()),
    );
  }

  void _openModuleList({
    required String moduleKey,
    required String groupTitle,
  }) {
    final uid = _auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final itemsPath = modulePaths[moduleKey];
    if (itemsPath == null) return;

    final String mode = groupTitle == 'İlanlarım'
        ? 'my'
        : (groupTitle == 'Favoriler' ? 'fav' : 'recent');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyListingsPage(
          uid: uid,
          moduleKey: moduleKey,
          moduleTitle: _titleOf(moduleKey),
          groupTitle: groupTitle,
          itemsPath: itemsPath,
          mode: mode,
        ),
      ),
    );
  }

  Widget _loginRequiredView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 72,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              const Text(
                'Profilini görmek için giriş yapmalısın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'İlanların, favorilerin, siparişlerin ve son baktıkların burada görünür.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.login),
                  label: const Text('Giriş Yap / Kayıt Ol'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final uid = user?.uid ?? '';
    final email = user?.email ?? '';

    if (uid.isEmpty) {
      return _loginRequiredView();
    }

    final modules = modulePaths.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _UserCard(email: email, uid: uid),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: Colors.black.withOpacity(.06)),
            ),
            child: ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: const Text(
                'Siparişlerim',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              subtitle: const Text('Market siparişlerini görüntüle'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openMyOrders,
            ),
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'İlanlarım', icon: Icons.list_alt),
          StreamBuilder<Map<String, int>>(
            stream: _myListingCounts(uid),
            builder: (context, snap) {
              final counts = snap.data ?? const <String, int>{};

              return _ModuleMenu(
                modules: modules,
                titleOf: _titleOf,
                counts: counts,
                onTap: (moduleKey) => _openModuleList(
                  moduleKey: moduleKey,
                  groupTitle: 'İlanlarım',
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Favoriler', icon: Icons.star_border),
          StreamBuilder<Map<String, int>>(
            stream: _favCounts(uid),
            builder: (context, snap) {
              final counts = snap.data ?? const <String, int>{};

              return _ModuleMenu(
                modules: modules,
                titleOf: _titleOf,
                counts: counts,
                onTap: (moduleKey) => _openModuleList(
                  moduleKey: moduleKey,
                  groupTitle: 'Favoriler',
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          const _SectionTitle(title: 'Son Baktıklarım', icon: Icons.history),
          StreamBuilder<Map<String, int>>(
            stream: _recentCounts(uid),
            builder: (context, snap) {
              final counts = snap.data ?? const <String, int>{};

              return _ModuleMenu(
                modules: modules,
                titleOf: _titleOf,
                counts: counts,
                onTap: (moduleKey) => _openModuleList(
                  moduleKey: moduleKey,
                  groupTitle: 'Son Baktıklarım',
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış Yap'),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String email;
  final String uid;

  const _UserCard({
    required this.email,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email.isEmpty ? 'Kullanıcı' : email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'UID: $uid',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleMenu extends StatelessWidget {
  final List<String> modules;
  final String Function(String) titleOf;
  final Map<String, int> counts;
  final void Function(String moduleKey) onTap;

  const _ModuleMenu({
    required this.modules,
    required this.titleOf,
    required this.counts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(.06)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < modules.length; i++) ...[
            ListTile(
              title: Text(
                titleOf(modules[i]),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: Text(
                (counts[modules[i]] ?? 0).toString(),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              onTap: () => onTap(modules[i]),
            ),
            if (i != modules.length - 1)
              Divider(
                height: 1,
                color: Colors.black.withOpacity(.06),
              ),
          ],
        ],
      ),
    );
  }
}
