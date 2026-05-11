import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'esya_paylas_page.dart';
import 'market_page.dart';
import 'market_detay_page.dart';
import 'can_dostum_page.dart';
import 'nobetci_eczane_page.dart';
import 'gecerken_beni_de_al_page.dart';
import 'engelsiz_is_page.dart';
import 'ustam_page.dart';
import 'oyun_menu_page.dart';
import 'market_karsilastirma_page.dart';
import 'tarzim_page.dart';

import 'package:ihtiyacim/models/market_listing_model.dart';
import 'package:ihtiyacim/pages/profile_page.dart';
import 'package:ihtiyacim/features/admin/admin_orders_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color bgTop = Color(0xFF145CFF);
  static const Color bgMid = Color(0xFF76A8FF);
  static const Color bgBottom = Color(0xFFF1F6FF);

  static const Color text = Color(0xFF10132E);
  static const Color muted = Color(0xFF66708D);

  static const Color accent = Color(0xFF246BFF);
  static const Color accentDark = Color(0xFF5F45FF);

  static const Color card = Color(0xFFF8FAFF);
  static const Color cardInner = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _adminEmail = 'mehmetilik19@gmail.com';

  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  bool _searching = false;
  bool _popupChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAdminPopupIfNeeded();
    });
  }

  Future<void> _showAdminPopupIfNeeded() async {
    if (_popupChecked) return;
    _popupChecked = true;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('admin_ads')
          .where('active', isEqualTo: true)
          .where('display', isEqualTo: 'popup')
          .get();

      if (!mounted) return;
      if (snap.docs.isEmpty) return;

      final docs = snap.docs.toList();

      docs.sort((a, b) {
        final am = a.data();
        final bm = b.data();

        final ap = am['priority'] is int ? am['priority'] as int : 1;
        final bp = bm['priority'] is int ? bm['priority'] as int : 1;
        if (bp != ap) return bp.compareTo(ap);

        final ac = am['createdAt'] is int ? am['createdAt'] as int : 0;
        final bc = bm['createdAt'] is int ? bm['createdAt'] as int : 0;
        return bc.compareTo(ac);
      });

      for (final doc in docs) {
        final data = doc.data();
        final frequency = (data['frequency'] ?? 'once').toString();

        final canShow = await _canShowPopup(doc.id, frequency);
        if (!canShow) continue;

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _AdminPopupAd(
            id: doc.id,
            data: data,
            onClose: () async {
              await _markPopupShown(doc.id, frequency);
              if (context.mounted) Navigator.pop(context);
            },
            onAction: () async {
              await _markPopupShown(doc.id, frequency);
              if (context.mounted) Navigator.pop(context);
              await _handleAdAction(data);
            },
          ),
        );

        break;
      }
    } catch (_) {}
  }

  Future<bool> _canShowPopup(String id, String frequency) async {
    if (frequency == 'always') return true;

    final prefs = await SharedPreferences.getInstance();

    if (frequency == 'once') {
      final closed = prefs.getBool('admin_popup_closed_$id') ?? false;
      return !closed;
    }

    final lastShown = prefs.getInt('admin_popup_last_$id') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    int waitMs = 0;

    if (frequency == '3h') {
      waitMs = 3 * 60 * 60 * 1000;
    } else if (frequency == '6h') {
      waitMs = 6 * 60 * 60 * 1000;
    } else if (frequency == '12h') {
      waitMs = 12 * 60 * 60 * 1000;
    } else if (frequency == 'daily') {
      waitMs = 24 * 60 * 60 * 1000;
    }

    return now - lastShown >= waitMs;
  }

  Future<void> _markPopupShown(String id, String frequency) async {
    if (frequency == 'always') return;

    final prefs = await SharedPreferences.getInstance();

    if (frequency == 'once') {
      await prefs.setBool('admin_popup_closed_$id', true);
    } else {
      await prefs.setInt(
        'admin_popup_last_$id',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _handleAdAction(Map<String, dynamic> data) async {
    final actionType = (data['actionType'] ?? 'none').toString();
    final pageTarget = (data['pageTarget'] ?? '').toString();
    final targetValue = (data['targetValue'] ?? '').toString().trim();

    if (actionType == 'none') return;

    if (actionType == 'page') {
      if (!mounted) return;

      if (pageTarget == 'market') {
        _go(context, const MarketPage());
      } else if (pageTarget == 'free') {
        _go(context, EsyaPaylasPage());
      } else if (pageTarget == 'canDostum') {
        _go(context, CanDostumPage());
      } else if (pageTarget == 'eczane') {
        _go(context, const NobetciEczanePage());
      } else if (pageTarget == 'ustam') {
        _go(context, UstamPage());
      } else if (pageTarget == 'tarzim') {
        _go(context, const TarzimPage());
      }

      return;
    }

    if (targetValue.isEmpty) return;

    Uri? uri;

    if (actionType == 'whatsapp') {
      final phone = targetValue.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.isEmpty) return;
      uri = Uri.parse('https://wa.me/$phone');
    } else if (actionType == 'web') {
      final link = targetValue.startsWith('http')
          ? targetValue
          : 'https://$targetValue';
      uri = Uri.parse(link);
    } else if (actionType == 'phone') {
      final phone = targetValue.replaceAll(RegExp(r'[^0-9+]'), '');
      if (phone.isEmpty) return;
      uri = Uri.parse('tel:$phone');
    }

    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _track(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
  }

  bool _isAdmin() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.toLowerCase() == _adminEmail.toLowerCase();
  }

  String _s(dynamic v) => (v ?? '').toString().trim();

  Future<void> _searchByCode() async {
    final code = _searchController.text.trim().toUpperCase();

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen ilan kodu girin')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _searching = true);

    try {
      final ref = FirebaseDatabase.instance.ref('market_listings');
      final snap = await ref.get();

      if (!snap.exists || snap.value is! Map) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Henüz market ilanı bulunamadı')),
        );
        return;
      }

      final raw = Map<dynamic, dynamic>.from(snap.value as Map);
      MarketListingModel? found;

      raw.forEach((key, value) {
        if (found != null) return;

        if (value is Map) {
          final map = Map<dynamic, dynamic>.from(value);
          final attrsRaw = map['attrs'];
          final attrs =
          attrsRaw is Map ? Map<dynamic, dynamic>.from(attrsRaw) : {};

          final ilanCode = _s(
            map['ilanCode'] ??
                attrs['ilanCode'] ??
                map['listingCode'] ??
                attrs['listingCode'] ??
                map['code'] ??
                attrs['code'],
          ).toUpperCase();

          final model = MarketListingModel.fromMap(key.toString(), map);
          final fallbackCode = model.ilanCode.toUpperCase();

          if (ilanCode == code || fallbackCode == code) {
            found = model;
          }
        }
      });

      if (!mounted) return;

      if (found == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$code kodlu ilan bulunamadı')),
        );
        return;
      }

      _searchController.clear();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarketDetayPage(item: found!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arama hatası: $e')),
      );
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      _HomeItem(
        title: 'Ücretsiz\nAl & Ver',
        subtitle: 'Paylaş / bul',
        icon: Icons.inventory_2_outlined,
        iconColor: const Color(0xFFFF5A00),
        onTap: () async {
          await _track('esya');
          if (!context.mounted) return;
          _go(context, EsyaPaylasPage());
        },
      ),
      _HomeItem(
        title: 'Can Dostum',
        subtitle: 'Destek ol',
        icon: Icons.pets_outlined,
        iconColor: const Color(0xFFFF2E7A),
        onTap: () async {
          await _track('can_dostum');
          if (!context.mounted) return;
          _go(context, CanDostumPage());
        },
      ),
      _HomeItem(
        title: 'Nöbetçi\nEczane',
        subtitle: 'Yakınında',
        icon: Icons.local_hospital_outlined,
        iconColor: const Color(0xFFFF9800),
        onTap: () => _go(context, const NobetciEczanePage()),
      ),
      _HomeItem(
        title: 'Market',
        subtitle: 'Keşfet',
        icon: Icons.storefront_outlined,
        iconColor: const Color(0xFF14C76F),
        onTap: () async {
          await _track('market');
          if (!context.mounted) return;
          _go(context, const MarketPage());
        },
      ),
      _HomeItem(
        title: 'Ustam',
        subtitle: 'Usta çağır',
        icon: Icons.handyman_outlined,
        iconColor: const Color(0xFF7A4DFF),
        onTap: () => _go(context, UstamPage()),
      ),
      _HomeItem(
        title: 'Engelsiz',
        subtitle: 'Fırsatlar',
        icon: Icons.accessible_forward_outlined,
        iconColor: const Color(0xFF168BFF),
        onTap: () => _go(context, const EngelsizIsPage()),
      ),
      _HomeItem(
        title: 'Geçerken Al',
        subtitle: 'Yol üstü',
        icon: Icons.directions_car_outlined,
        iconColor: const Color(0xFF762CFF),
        onTap: () => _go(context, GecerkenBeniDeAlPage()),
      ),
      _HomeItem(
        title: 'Tarzım',
        subtitle: 'Stil',
        icon: Icons.style_outlined,
        iconColor: const Color(0xFFFF2E8A),
        onTap: () => _go(context, const TarzimPage()),
      ),
      _HomeItem(
        title: 'Oyun',
        subtitle: 'Mola',
        icon: Icons.sports_esports_outlined,
        iconColor: const Color(0xFF18C7C7),
        onTap: () => _go(context, const OyunMenuPage()),
      ),
    ];

    return Scaffold(
      extendBody: true,
      backgroundColor: HomePage.bgBottom,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            _go(context, const KesfetPage());
          } else if (index == 2) {
            _go(context, const OneriPage());
          } else if (index == 3) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bildirimler yakında aktif olacak')),
            );
          } else if (index == 4) {
            _go(context, ProfilePage());
          }
        },
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.34, 0.68, 1.0],
            colors: [
              HomePage.bgTop,
              HomePage.bgMid,
              Color(0xFFEAF2FF),
              HomePage.bgBottom,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: _Header(
                  isAdmin: _isAdmin(),
                  onAdminTap: () => _go(context, const AdminOrdersPage()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: _SearchBox(
                  controller: _searchController,
                  onSearch: _searchByCode,
                  searching: _searching,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 170),
                  children: [
                    const _HomeAdSlider(),
                    const SizedBox(height: 14),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 11,
                        mainAxisSpacing: 13,
                        childAspectRatio: 0.86,
                      ),
                      itemBuilder: (context, i) => _GridCard(item: items[i]),
                    ),
                    const SizedBox(height: 14),
                    _CompareBanner(
                      onTap: () => _go(
                        context,
                        const MarketKarsilastirmaPage(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPopupAd extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onClose;
  final VoidCallback onAction;

  const _AdminPopupAd({
    required this.id,
    required this.data,
    required this.onClose,
    required this.onAction,
  });

  Color _color(String type) {
    switch (type) {
      case 'indirim':
        return const Color(0xFF14C76F);
      case 'yardim':
        return const Color(0xFFFF9800);
      case 'reklam':
        return const Color(0xFF7A4DFF);
      case 'acil':
        return const Color(0xFFD32F2F);
      default:
        return HomePage.accent;
    }
  }

  IconData _popupIcon(String style) {
    switch (style) {
      case 'heart':
        return Icons.favorite_rounded;
      case 'discount':
        return Icons.percent_rounded;
      case 'store':
        return Icons.storefront_rounded;
      case 'help':
        return Icons.volunteer_activism_rounded;
      case 'medicine':
        return Icons.local_hospital_rounded;
      default:
        return Icons.card_giftcard_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (data['type'] ?? 'duyuru').toString();
    final effect = (data['effect'] ?? 'konfeti').toString();
    final popupStyle =
    (data['popupStyle'] ?? data['imageType'] ?? 'gift').toString();

    final title = (data['title'] ?? '').toString();
    final desc = (data['desc'] ?? '').toString();
    final buttonText = (data['buttonText'] ?? '').toString();

    final actionType = (data['actionType'] ?? 'none').toString();
    final hasAction = actionType != 'none';

    final color = _color(type);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              blurRadius: 30,
              offset: const Offset(0, 18),
              color: Colors.black.withOpacity(0.18),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (effect == 'parlama')
              Positioned(
                right: -28,
                top: -28,
                child: Icon(
                  Icons.blur_on,
                  size: 110,
                  color: color.withOpacity(0.16),
                ),
              ),
            if (effect == 'neon')
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: color.withOpacity(0.45),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onClose,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF66708D),
                        size: 28,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 138,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 178,
                        height: 118,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      if (effect == 'konfeti') ...const [
                        Positioned(
                          top: 10,
                          left: 54,
                          child: _ConfettiDot(color: Color(0xFFFFB300)),
                        ),
                        Positioned(
                          top: 18,
                          right: 48,
                          child: _ConfettiDot(color: Color(0xFFFF5B91)),
                        ),
                        Positioned(
                          bottom: 25,
                          left: 42,
                          child: _ConfettiDot(color: Color(0xFF18C7E8)),
                        ),
                        Positioned(
                          bottom: 18,
                          right: 58,
                          child: _ConfettiDot(color: Color(0xFF14C76F)),
                        ),
                      ],
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                              color: color.withOpacity(0.22),
                            ),
                          ],
                        ),
                        child: Icon(
                          _popupIcon(popupStyle),
                          color: color,
                          size: 54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title.isEmpty ? 'Duyuru' : title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: HomePage.text,
                    fontSize: 14.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.favorite,
                        color: color,
                        size: 18,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Colors.black.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (hasAction) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: onAction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 10,
                        shadowColor: color.withOpacity(0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            buttonText.isEmpty ? 'Devam Et' : buttonText,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                TextButton(
                  onPressed: onClose,
                  child: const Text(
                    'Kapat',
                    style: TextStyle(
                      color: HomePage.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  final Color color;

  const _ConfettiDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.7,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _HomeAdSlider extends StatelessWidget {
  const _HomeAdSlider();

  Color _color(String type) {
    switch (type) {
      case 'indirim':
        return const Color(0xFF14C76F);
      case 'yardim':
        return const Color(0xFFFF9800);
      case 'reklam':
        return const Color(0xFF7A4DFF);
      case 'acil':
        return const Color(0xFFD32F2F);
      default:
        return HomePage.accent;
    }
  }

  IconData _icon(String type) {
    switch (type) {
      case 'indirim':
        return Icons.local_offer_outlined;
      case 'yardim':
        return Icons.volunteer_activism_outlined;
      case 'reklam':
        return Icons.storefront_outlined;
      case 'acil':
        return Icons.warning_amber_rounded;
      default:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('admin_ads')
        .where('active', isEqualTo: true);

    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final docs = snap.data!.docs.where((d) {
          final m = d.data() as Map<String, dynamic>;
          final display = (m['display'] ?? 'slider').toString();
          return display == 'slider' || display == 'small';
        }).toList();

        if (docs.isEmpty) return const SizedBox.shrink();

        docs.sort((a, b) {
          final am = a.data() as Map<String, dynamic>;
          final bm = b.data() as Map<String, dynamic>;

          final ap = am['priority'] is int ? am['priority'] as int : 1;
          final bp = bm['priority'] is int ? bm['priority'] as int : 1;
          if (bp != ap) return bp.compareTo(ap);

          final ac = am['createdAt'] is int ? am['createdAt'] as int : 0;
          final bc = bm['createdAt'] is int ? bm['createdAt'] as int : 0;
          return bc.compareTo(ac);
        });

        return SizedBox(
          height: 92,
          child: PageView.builder(
            itemCount: docs.length,
            controller: PageController(viewportFraction: 0.94),
            itemBuilder: (context, i) {
              final m = docs[i].data() as Map<String, dynamic>;

              final type = (m['type'] ?? 'duyuru').toString();
              final effect = (m['effect'] ?? 'normal').toString();
              final title = (m['title'] ?? '').toString();
              final desc = (m['desc'] ?? '').toString();
              final color = _color(type);

              return Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.72),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                      color: color.withOpacity(0.24),
                    ),
                  ],
                  border: effect == 'neon'
                      ? Border.all(
                    color: Colors.white.withOpacity(0.85),
                    width: 1.5,
                  )
                      : null,
                ),
                child: Stack(
                  children: [
                    if (effect == 'konfeti')
                      Positioned(
                        right: 8,
                        top: 4,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white.withOpacity(0.70),
                          size: 22,
                        ),
                      ),
                    if (effect == 'parlama')
                      Positioned(
                        right: 15,
                        bottom: 4,
                        child: Icon(
                          Icons.blur_on,
                          color: Colors.white.withOpacity(0.35),
                          size: 44,
                        ),
                      ),
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _icon(type),
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                desc,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final bool isAdmin;
  final VoidCallback onAdminTap;

  const _Header({required this.isAdmin, required this.onAdminTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HeaderIcon(
          icon: Icons.account_balance,
          onTap: () {},
          gradient: const [Color(0xFF5A8CFF), Color(0xFF235DFF)],
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İHTİYACIM',
                style: TextStyle(
                  fontSize: 31,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'İhtiyacın olan her şey burada',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 9),
              _HeaderLine(),
            ],
          ),
        ),
        _HeaderIcon(
          icon: isAdmin
              ? Icons.admin_panel_settings_outlined
              : Icons.health_and_safety_outlined,
          onTap: isAdmin ? onAdminTap : () {},
          solidWhite: true,
        ),
      ],
    );
  }
}

class _HeaderLine extends StatelessWidget {
  const _HeaderLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF8FD8),
            Color(0xFF5BE4FF),
          ],
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final bool searching;

  const _SearchBox({
    required this.controller,
    required this.onSearch,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 24,
            offset: const Offset(0, 12),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        decoration: InputDecoration(
          hintText: 'İlan kodu veya ihtiyaç ara...',
          hintStyle: const TextStyle(
            color: HomePage.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: HomePage.muted,
            size: 28,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: searching ? null : onSearch,
              child: Container(
                width: 46,
                height: 46,
                margin: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      HomePage.accentDark,
                      HomePage.accent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      color: HomePage.accent.withOpacity(0.30),
                    ),
                  ],
                ),
                child: searching
                    ? const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
                    : const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  final _HomeItem item;

  const _GridCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HomePage.cardInner,
                HomePage.card,
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.95)),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 13),
                color: const Color(0xFF40508A).withOpacity(0.13),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconTile(
                    icon: item.icon,
                    color1: item.iconColor.withOpacity(0.92),
                    color2: item.iconColor,
                    size: 52,
                    iconSize: 28,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                          color: HomePage.text,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w700,
                          color: HomePage.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                right: -2,
                bottom: -1,
                child: _SmallArrow(color: item.iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _CompareBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 74,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF5C9DFF),
                Color(0xFF7B73FF),
                Color(0xFFD783FF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 24,
                offset: const Offset(0, 13),
                color: const Color(0xFF6C70FF).withOpacity(0.25),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              _IconTile(
                icon: Icons.compare_arrows_outlined,
                color1: const Color(0xFF20D6E8),
                color2: const Color(0xFF087BFF),
                size: 54,
                iconSize: 30,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Karşılaştırma',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Fiyat & ürün',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color1;
  final Color color2;
  final double size;
  final double iconSize;

  const _IconTile({
    required this.icon,
    required this.color1,
    required this.color2,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 16,
            offset: const Offset(0, 8),
            color: color2.withOpacity(0.30),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class _SmallArrow extends StatelessWidget {
  final Color color;

  const _SmallArrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: color,
        size: 21,
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool solidWhite;
  final List<Color>? gradient;

  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.solidWhite = false,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: solidWhite ? Colors.white.withOpacity(0.94) : null,
          gradient: solidWhite
              ? null
              : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient ??
                const [
                  HomePage.accent,
                  HomePage.accentDark,
                ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 10),
              color: Colors.black.withOpacity(0.10),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: solidWhite ? HomePage.accentDark : Colors.white,
          size: 31,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.88)),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 14),
            color: const Color(0xFF3B5BBB).withOpacity(0.16),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavItem(
            icon: Icons.home_rounded,
            label: 'Ana Sayfa',
            active: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _BottomNavItem(
            icon: Icons.explore_outlined,
            label: 'Keşfet',
            active: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _BottomNavItem(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Öneri',
            active: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
          _BottomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Bildirim',
            active: selectedIndex == 3,
            badge: true,
            onTap: () => onTap(3),
          ),
          _BottomNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            active: selectedIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? HomePage.accent : HomePage.muted;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: SizedBox(
        width: 62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 25),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 10.8,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: active ? 38 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: HomePage.accentDark,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
            if (badge)
              Positioned(
                top: 17,
                right: 12,
                child: Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF2D55),
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class KesfetPage extends StatefulWidget {
  const KesfetPage({super.key});

  @override
  State<KesfetPage> createState() => _KesfetPageState();
}

class _KesfetPageState extends State<KesfetPage> {
  Map<String, int> data = {};

  final Map<String, _DiscoverItem> discoverItems = {
    'esya': _DiscoverItem(
      title: 'Ücretsiz Al & Ver',
      subtitle:
      'En çok ilgilendiğin alanlardan biri. İhtiyaç fazlası eşyaları keşfet.',
      icon: Icons.inventory_2_outlined,
      color: const Color(0xFFFF5A00),
      page: EsyaPaylasPage(),
    ),
    'market': const _DiscoverItem(
      title: 'Market',
      subtitle: 'Uygun ürünleri ve ihtiyaçlarını buradan keşfet.',
      icon: Icons.storefront_outlined,
      color: Color(0xFF14C76F),
      page: MarketPage(),
    ),
    'can_dostum': _DiscoverItem(
      title: 'Can Dostum',
      subtitle: 'Can dostlarımız için destek ve ilanları gör.',
      icon: Icons.pets_outlined,
      color: const Color(0xFFFF2E7A),
      page: CanDostumPage(),
    ),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final map = <String, int>{
      'esya': prefs.getInt('esya') ?? 0,
      'market': prefs.getInt('market') ?? 0,
      'can_dostum': prefs.getInt('can_dostum') ?? 0,
    };

    setState(() => data = map);
  }

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final hasData = sorted.any((e) => e.value > 0);

    final list = hasData
        ? sorted.where((e) => e.value > 0).toList()
        : [
      const MapEntry('esya', 0),
      const MapEntry('market', 0),
      const MapEntry('can_dostum', 0),
    ];

    return Scaffold(
      backgroundColor: HomePage.bgBottom,
      appBar: AppBar(
        title: const Text('Keşfet'),
        backgroundColor: HomePage.accent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: HomePage.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              hasData
                  ? 'İlgi alanlarına göre sana uygun bölümleri öne çıkardık.'
                  : 'Sen kullandıkça Keşfet sana özel hale gelecek.',
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: HomePage.text,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ...list.map((entry) {
            final item = discoverItems[entry.key]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: HomePage.card,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.page),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.color.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: HomePage.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                style: const TextStyle(
                                  color: HomePage.muted,
                                  fontSize: 12.5,
                                  height: 1.3,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (entry.value > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${entry.value} kez ziyaret ettin',
                                  style: TextStyle(
                                    color: item.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DiscoverItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _DiscoverItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}

class OneriPage extends StatefulWidget {
  const OneriPage({super.key});

  @override
  State<OneriPage> createState() => _OneriPageState();
}

class _OneriPageState extends State<OneriPage> {
  final TextEditingController _messageC = TextEditingController();

  @override
  void dispose() {
    _messageC.dispose();
    super.dispose();
  }

  Future<void> _sendMail() async {
    final message = _messageC.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen öneri veya şikayetinizi yazın')),
      );
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: 'ihtiyacim2026@gmail.com',
      queryParameters: {
        'subject': 'İhtiyacım - Öneri / Şikayet',
        'body': message,
      },
    );

    final ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mail uygulaması açılamadı')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.bgBottom,
      appBar: AppBar(
        title: const Text('Öneri ve Şikayet'),
        backgroundColor: HomePage.accent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: HomePage.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Text(
              'Öneri, şikayet veya geliştirme fikrini bize gönderebilirsin. Gönder butonuna bastığında mail uygulaman açılır.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w700,
                color: HomePage.muted,
              ),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _messageC,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Öneri veya şikayetinizi yazın...',
              filled: true,
              fillColor: HomePage.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: HomePage.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _sendMail,
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text(
                'Mail Olarak Gönder',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  _HomeItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
  });
}
