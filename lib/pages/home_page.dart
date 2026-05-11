import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'esya_paylas_page.dart';
import 'market_page.dart';
import 'can_dostum_page.dart';
import 'nobetci_eczane_page.dart';
import 'gecerken_beni_de_al_page.dart';
import 'engelsiz_is_page.dart';
import 'ustam_page.dart';
import 'oyun_menu_page.dart';
import 'market_karsilastirma_page.dart';
import 'tarzim_page.dart';

// ✅ Profil
import 'package:ihtiyacim/pages/profile_page.dart';

// ✅ Admin
import 'package:ihtiyacim/features/admin/admin_orders_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // ✅ İDARÎ / KURUMSAL arka plan (biraz koyulaştırılmış sakin gri-mavi)
  static const Color _bgTop = Color(0xFFE9ECF3);
  static const Color _bgMid = Color(0xFFDDE2EC);
  static const Color _bgBottom = Color(0xFFD1D8E4);

  // Metinler
  static const Color _text = Color(0xFF15122A);
  static const Color _muted = Color(0xFF5B5872);

  // Kurumsal vurgu (mavi)
  static const Color _accent = Color(0xFF2F5CFF);

  // Kart yüzeyi
  static const Color _card = Color(0xFFFFFDFB);
  static const Color _surface = Color(0xFFFFFFFF);

  static const String _adminEmail = 'mehmetilik19@gmail.com';

  void _go(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  bool _isAdmin() {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    return email.toLowerCase() == _adminEmail.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final items = <_HomeItem>[
      _HomeItem(
        title: 'Eşya Paylaşma',
        subtitle: 'Paylaş / bul',
        icon: Icons.inventory_2_outlined,
        iconColor: const Color(0xFFFF6A00),
        onTap: () => _go(context, EsyaPaylasPage()),
      ),
      _HomeItem(
        title: 'Can Dostum',
        subtitle: 'Destek ol',
        icon: Icons.pets_outlined,
        iconColor: const Color(0xFFFF2D55),
        onTap: () => _go(context, CanDostumPage()),
      ),
      _HomeItem(
        title: 'Nöbetçi Eczane',
        subtitle: 'Yakınında',
        icon: Icons.local_hospital_outlined,
        iconColor: const Color(0xFFFFA000),
        onTap: () => _go(context, const NobetciEczanePage()),
      ),
      _HomeItem(
        title: 'Market',
        subtitle: 'Keşfet',
        icon: Icons.storefront_outlined,
        iconColor: const Color(0xFF00C853),
        onTap: () => _go(context, const MarketPage()),
      ),
      _HomeItem(
        title: 'Ustam',
        subtitle: 'Usta çağır',
        icon: Icons.handyman_outlined,
        iconColor: const Color(0xFFFFB300),
        onTap: () => _go(context, UstamPage()),
      ),
      _HomeItem(
        title: 'Engelsiz',
        subtitle: 'Fırsatlar',
        icon: Icons.accessible_forward_outlined,
        iconColor: const Color(0xFF00B0FF),
        onTap: () => _go(context, const EngelsizIsPage()),
      ),
      _HomeItem(
        title: 'Geçerken Al',
        subtitle: 'Yol üstü',
        icon: Icons.directions_car_outlined,
        iconColor: const Color(0xFF6A00FF),
        onTap: () => _go(context, GecerkenBeniDeAlPage()),
      ),
      _HomeItem(
        title: 'Tarzım',
        subtitle: 'Stil',
        icon: Icons.style_outlined,
        iconColor: const Color(0xFFFF2BC2),
        onTap: () => _go(context, const TarzimPage()),
      ),
      _HomeItem(
        title: 'Oyun',
        subtitle: 'Mola',
        icon: Icons.sports_esports_outlined,
        iconColor: const Color(0xFF00D1FF),
        onTap: () => _go(context, const OyunMenuPage()),
      ),
      _HomeItem(
        title: 'Karşılaştırma',
        subtitle: 'Fiyat',
        icon: Icons.compare_arrows_outlined,
        iconColor: const Color(0xFF00E5FF),
        onTap: () => _go(context, const MarketKarsilastirmaPage()),
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_bgTop, _bgMid, _bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black.withOpacity(0.07)),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance, color: _accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.black.withOpacity(0.07)),
                            ),
                            child: Text(
                              'T.C. DİJİTAL HİZMET',
                              style: TextStyle(
                                fontSize: 11.2,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: _muted,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'İHTİYACIM',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black.withOpacity(0.07)),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 16,
                            offset: const Offset(0, 10),
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.person_outline),
                        iconSize: 22,
                        color: _text,
                        onPressed: () => _go(context, ProfilePage()),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniChip(
                      label: 'Usta',
                      icon: Icons.handyman_outlined,
                      onTap: () => _go(context, UstamPage()),
                    ),
                    _MiniChip(
                      label: 'Market',
                      icon: Icons.storefront_outlined,
                      onTap: () => _go(context, const MarketPage()),
                    ),
                    _MiniChip(
                      label: 'Eczane',
                      icon: Icons.local_hospital_outlined,
                      onTap: () => _go(context, const NobetciEczanePage()),
                    ),
                    if (_isAdmin())
                      _MiniChip(
                        label: 'Admin',
                        icon: Icons.admin_panel_settings_outlined,
                        onTap: () => _go(context, AdminOrdersPage()),
                        isAccent: true,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.74,
                    ),
                    itemBuilder: (context, i) => _GridCard(
                      item: items[i],
                      cardColor: _card,
                    ),
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

class _GridCard extends StatelessWidget {
  final _HomeItem item;
  final Color cardColor;

  const _GridCard({
    required this.item,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: item.onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(0.06),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      item.iconColor.withOpacity(0.98),
                      item.iconColor.withOpacity(0.78),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: item.iconColor.withOpacity(0.45),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  size: 30,
                  color: Colors.white,
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.6,
                      fontWeight: FontWeight.w900,
                      height: 1.10,
                      color: HomePage._text,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.8,
                      fontWeight: FontWeight.w700,
                      color: HomePage._muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAccent;

  const _MiniChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isAccent ? HomePage._accent : HomePage._surface;
    final fg = isAccent ? Colors.white : HomePage._text;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isAccent ? Colors.transparent : Colors.black.withOpacity(0.07),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, 10),
                color: (isAccent ? HomePage._accent : Colors.black).withOpacity(0.12),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: fg,
                ),
              ),
            ],
          ),
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