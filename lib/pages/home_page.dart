import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ihtiyacim/pages/notification_page.dart';
import 'package:ihtiyacim/features/admin/admin_menu_page.dart';

import 'esya_paylas_page.dart';
import 'market_page.dart';
import 'market_detay_page.dart';
import 'can_dostum_page.dart';
import 'nobetci_eczane_page.dart';
import 'gecerken_beni_de_al_page.dart';
import 'engelsiz_is_page.dart';
import 'ustam_page.dart';
import 'oyun_menu_page.dart';
import 'tarzim_page.dart';
import 'daily_wheel_page.dart';

import 'package:ihtiyacim/models/market_listing_model.dart';
import 'package:ihtiyacim/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color bgTop = Color(0xFF0F4CFF);
  static const Color bgMid = Color(0xFF5F7CFF);
  static const Color bgBottom = Color(0xFFF3F7FF);
  static const Color text = Color(0xFF10132E);
  static const Color muted = Color(0xFF66708D);
  static const Color accent = Color(0xFF246BFF);
  static const Color accentDark = Color(0xFF6B45FF);
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
  bool _hasNotification = false;

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
      final link =
      targetValue.startsWith('http') ? targetValue : 'https://$targetValue';
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

  String _userName() {
    final user = FirebaseAuth.instance.currentUser;
    final display = user?.displayName?.trim() ?? '';

    if (display.isNotEmpty) {
      return display.split(' ').first;
    }

    final email = user?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'Dostum';
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      _HomeItem(
        title: 'Ücretsiz\nAl & Ver',
        subtitle: 'Paylaş / bul',
        icon: Icons.inventory_2_rounded,
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
        icon: Icons.pets_rounded,
        iconColor: const Color(0xFF19C95C),
        onTap: () async {
          await _track('can_dostum');
          if (!context.mounted) return;
          _go(context, CanDostumPage());
        },
      ),
      _HomeItem(
        title: 'Nöbetçi Eczane',
        subtitle: 'Yakınında',
        icon: Icons.local_pharmacy_rounded,
        iconColor: const Color(0xFFFF3125),
        onTap: () => _go(context, const NobetciEczanePage()),
      ),
      _HomeItem(
        title: 'İhtiyacım',
        subtitle: 'Keşfet',
        icon: Icons.card_giftcard_rounded,
        iconColor: const Color(0xFFFFA500),
        onTap: () async {
          await _track('market');
          if (!context.mounted) return;
          _go(context, const MarketPage());
        },
      ),
      _HomeItem(
        title: 'Ustam',
        subtitle: 'Usta çağır',
        icon: Icons.construction_rounded,
        iconColor: const Color(0xFF7A36FF),
        onTap: () => _go(context, UstamPage()),
      ),
      _HomeItem(
        title: 'Engelsiz',
        subtitle: 'Fırsatlar',
        icon: Icons.accessible_forward_rounded,
        iconColor: const Color(0xFF18C7D8),
        onTap: () => _go(context, const EngelsizIsPage()),
      ),
      _HomeItem(
        title: 'Geçerken Al',
        subtitle: 'Yol üstü',
        icon: Icons.directions_car_filled_rounded,
        iconColor: const Color(0xFF1677FF),
        onTap: () => _go(context, GecerkenBeniDeAlPage()),
      ),
      _HomeItem(
        title: 'Tarzım',
        subtitle: 'Stil',
        icon: Icons.checkroom_rounded,
        iconColor: const Color(0xFFFF4F9A),
        onTap: () => _go(context, const TarzimPage()),
      ),
      _HomeItem(
        title: 'Bilgi Oyunu',
        subtitle: 'Mola',
        icon: Icons.psychology_alt_rounded,
        iconColor: const Color(0xFF12BFAF),
        onTap: () => _go(context, const OyunMenuPage()),
      ),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: HomePage.bgBottom,
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        hasNotification: _hasNotification,
        onTap: (index) {
          setState(() => _selectedIndex = index);

          if (index == 1) {
            _go(context, const KesfetPage());
          } else if (index == 2) {
            _go(context, const OyunMenuPage());
          } else if (index == 3) {
            setState(() {
              _hasNotification = false;
            });

            _go(context, const NotificationPage());
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
            stops: [0.0, 0.30, 0.62, 1.0],
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
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: _Header(
                  isAdmin: _isAdmin(),
                  userName: _userName(),
                  onAdminTap: () => _go(context, const AdminMenuPage()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: _SearchBox(
                  controller: _searchController,
                  onSearch: _searchByCode,
                  searching: _searching,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                  children: [
                    _IhtiyacimdaBugunBanner(
                      onTap: () => _go(
                        context,
                        const IhtiyacimdaBugunPage(),
                      ),
                    ),
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
                        childAspectRatio: 1.18,
                      ),
                      itemBuilder: (context, i) => _GridCard(item: items[i]),
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
        return Icons.local_pharmacy_rounded;
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

class _Header extends StatelessWidget {
  final bool isAdmin;
  final String userName;
  final VoidCallback onAdminTap;

  const _Header({
    required this.isAdmin,
    required this.userName,
    required this.onAdminTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _HeaderIcon(
              icon: Icons.feedback_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OneriPage(),
                  ),
                );
              },
              gradient: const [
                Color(0xFFFF4F9A),
                Color(0xFF7A4DFF),
              ],
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                children: [
                  _GradientTitle(),
                  SizedBox(height: 6),
                  Text(
                    'her gün bir şey, bir gün her şey değişir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8),
                  _HeaderLine(),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              children: [
                _HeaderIcon(
                  icon: isAdmin
                      ? Icons.admin_panel_settings_rounded
                      : Icons.health_and_safety_rounded,
                  onTap: isAdmin ? onAdminTap : () {},
                  gradient: const [Color(0xFF235DFF), Color(0xFF5F45FF)],
                ),
                const SizedBox(height: 7),
                DailyWheelMiniButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DailyWheelPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Merhaba $userName 👋\nBugün neye ihtiyacın var?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.35,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientTitle extends StatelessWidget {
  const _GradientTitle();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          colors: [
            Colors.white,
            Color(0xFF9DEBFF),
            Color(0xFFFF7AC8),
          ],
        ).createShader(bounds);
      },
      child: const Text(
        'İHTİYACIM',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 28,
          height: 1,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;

  const _MiniBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFFF2D55),
        shape: BoxShape.circle,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HeaderLine extends StatelessWidget {
  const _HeaderLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
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
      height: 66,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(28),
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
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: HomePage.muted,
            size: 31,
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 7),
            child: GestureDetector(
              onTap: searching ? null : onSearch,
              child: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.all(7),
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
                  size: 31,
                ),
              ),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 22),
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.iconColor.withOpacity(0.90),
                item.iconColor,
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 22,
                offset: const Offset(0, 12),
                color: item.iconColor.withOpacity(0.28),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.35)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  item.icon,
                  size: 47,
                  color: Colors.white.withOpacity(0.92),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                right: 34,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.4,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 11.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.17),
                    border: Border.all(color: Colors.white.withOpacity(0.70)),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        width: 52,
        height: 52,
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.16)),
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
          size: 28,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final bool hasNotification;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.selectedIndex,
    required this.hasNotification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF7FAFF),
            Color(0xFFEAF2FF),
            Color(0xFFFFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.90)),
        boxShadow: [
          BoxShadow(
            blurRadius: 26,
            offset: const Offset(0, 14),
            color: const Color(0xFF3B5BBB).withOpacity(0.18),
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
          GestureDetector(
            onTap: () => onTap(2),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7A4DFF),
                    Color(0xFF246BFF),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                    color: HomePage.accentDark.withOpacity(0.30),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
          ),
          _BottomNavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Bildirimler',
            active: selectedIndex == 3,
            badge: hasNotification,
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
        width: 66,
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
                    fontSize: 10.5,
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
              const Positioned(
                top: 17,
                right: 10,
                child: _MiniBadge(text: '3'),
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
      title: 'İhtiyacım',
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
  final TextEditingController _contactC = TextEditingController();
  String _type = 'Öneri';

  @override
  void dispose() {
    _messageC.dispose();
    _contactC.dispose();
    super.dispose();
  }

  Future<void> _sendMail() async {
    final message = _messageC.text.trim();
    final contact = _contactC.text.trim();

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen öneri veya şikayetinizi yazın')),
      );
      return;
    }

    final fullBody = '''
Konu türü: $_type

Mesaj:
$message

İletişim:
${contact.isEmpty ? 'Belirtilmedi' : contact}
''';

    final uri = Uri(
      scheme: 'mailto',
      path: 'ihtiyacim2026@gmail.com',
      queryParameters: {
        'subject': 'İhtiyacım - $_type',
        'body': fullBody,
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
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF246BFF),
                  Color(0xFF7A4DFF),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                  color: HomePage.accent.withOpacity(0.22),
                ),
              ],
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.feedback_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Fikrini bize gönder. Uygulamayı birlikte daha iyi hale getirelim.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: HomePage.card,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    text: 'Öneri',
                    active: _type == 'Öneri',
                    icon: Icons.lightbulb_outline_rounded,
                    onTap: () => setState(() => _type = 'Öneri'),
                  ),
                ),
                Expanded(
                  child: _TypeButton(
                    text: 'Şikayet',
                    active: _type == 'Şikayet',
                    icon: Icons.report_problem_outlined,
                    onTap: () => setState(() => _type = 'Şikayet'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageC,
            maxLines: 7,
            decoration: InputDecoration(
              hintText: 'Mesajınızı yazın...',
              filled: true,
              fillColor: HomePage.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactC,
            decoration: InputDecoration(
              hintText: 'İletişim bilginiz (isteğe bağlı)',
              prefixIcon: const Icon(Icons.person_outline_rounded),
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
            height: 50,
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

class _TypeButton extends StatelessWidget {
  final String text;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  const _TypeButton({
    required this.text,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        decoration: BoxDecoration(
          color: active ? HomePage.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: active ? Colors.white : HomePage.muted,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: active ? Colors.white : HomePage.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
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

class _IhtiyacimdaBugunBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _IhtiyacimdaBugunBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 92,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF145CFF),
                Color(0xFF7A4DFF),
                Color(0xFFFF7AC8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                offset: const Offset(0, 10),
                color: HomePage.accentDark.withOpacity(0.22),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.today_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'İhtiyacımda Bugün',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Günün ihtiyaçları burada seni bekliyor!',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tümünü Gör',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
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

class IhtiyacimdaBugunPage extends StatelessWidget {
  const IhtiyacimdaBugunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.bgBottom,
      appBar: AppBar(
        title: const Text('İhtiyacımda Bugün'),
        backgroundColor: HomePage.accent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _TodayCard(
            icon: Icons.campaign_outlined,
            title: 'Günün Duyurusu',
            text:
            'İhtiyacım’da güncel duyurular ve yenilikler burada gösterilir.',
          ),
          _TodayCard(
            icon: Icons.inventory_2_outlined,
            title: 'Bugün Verilen İlanlar',
            text:
            'Eşya paylaşımı, yardım ve ihtiyaç ilanlarının özeti burada yer alır.',
          ),
          _TodayCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Market Hareketleri',
            text: 'Yapılan alışverişler ve market hareketleri burada özetlenir.',
          ),
          _TodayCard(
            icon: Icons.accessible_forward_outlined,
            title: 'Engelsiz İş',
            text:
            'İş arayan ve işçi arayan ilanların günlük özeti burada görünür.',
          ),
          _TodayCard(
            icon: Icons.pets_outlined,
            title: 'Can Dostum',
            text:
            'Can dostlarımız için verilen ilanların günlük özeti burada yer alır.',
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _TodayCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: HomePage.accent),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(text),
      ),
    );
  }
}
