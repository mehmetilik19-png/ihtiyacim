import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDuyuruReklamPage extends StatefulWidget {
  const AdminDuyuruReklamPage({super.key});

  @override
  State<AdminDuyuruReklamPage> createState() =>
      _AdminDuyuruReklamPageState();
}

class _AdminDuyuruReklamPageState extends State<AdminDuyuruReklamPage> {
  final titleC = TextEditingController();
  final descC = TextEditingController();
  final buttonC = TextEditingController();
  final targetC = TextEditingController();

  String type = 'duyuru';
  String display = 'slider';
  String effect = 'konfeti';
  String popupStyle = 'gift';
  String priority = 'normal';
  String frequency = 'once';
  String actionType = 'none';
  String pageTarget = 'market';

  final ref = FirebaseFirestore.instance.collection('admin_ads');

  @override
  void dispose() {
    titleC.dispose();
    descC.dispose();
    buttonC.dispose();
    targetC.dispose();
    super.dispose();
  }

  int _priorityValue(String p) {
    switch (p) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  Future<void> _save() async {
    final title = titleC.text.trim();
    final desc = descC.text.trim();
    final buttonText = buttonC.text.trim();
    final targetValue = targetC.text.trim();

    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve açıklama zorunlu')),
      );
      return;
    }

    await ref.add({
      'title': title,
      'desc': desc,
      'buttonText': buttonText,
      'type': type,
      'display': display,
      'effect': effect,
      'popupStyle': popupStyle,
      'priority': _priorityValue(priority),
      'frequency': frequency,
      'actionType': actionType,
      'pageTarget': pageTarget,
      'targetValue': targetValue,
      'active': true,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    titleC.clear();
    descC.clear();
    buttonC.clear();
    targetC.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kaydedildi ✅')),
    );
  }

  Future<void> _toggle(String id, bool active) async {
    await ref.doc(id).update({'active': !active});
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Silinsin mi?'),
        content: const Text('Bu içerik kalıcı olarak silinecek.'),
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

    if (ok == true) {
      await ref.doc(id).delete();
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'indirim':
        return const Color(0xFF14C76F);
      case 'yardim':
        return const Color(0xFFFF9800);
      case 'reklam':
        return const Color(0xFF7A4DFF);
      case 'acil':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF246BFF);
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
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

  String _typeName(String t) {
    switch (t) {
      case 'indirim':
        return 'İndirim';
      case 'yardim':
        return 'Yardım';
      case 'reklam':
        return 'Sponsor Reklam';
      case 'acil':
        return 'Acil';
      default:
        return 'Duyuru';
    }
  }

  String _displayName(String d) {
    switch (d) {
      case 'popup':
        return 'Büyük Popup';
      case 'small':
        return 'Küçük Reklam';
      default:
        return 'Ana Ekran Slider';
    }
  }

  String _frequencyName(String f) {
    switch (f) {
      case 'always':
        return 'Her açılışta';
      case '3h':
        return '3 saatte 1';
      case '6h':
        return '6 saatte 1';
      case '12h':
        return '12 saatte 1';
      case 'daily':
        return 'Günde 1';
      default:
        return 'Sadece 1 kere';
    }
  }

  String _actionName(String a) {
    switch (a) {
      case 'page':
        return 'Uygulama içi sayfa';
      case 'whatsapp':
        return 'WhatsApp';
      case 'web':
        return 'Web sitesi';
      case 'phone':
        return 'Telefon';
      default:
        return 'Yönlendirme yok';
    }
  }

  bool get _needsButton => actionType != 'none';

  bool get _needsTarget =>
      actionType == 'whatsapp' || actionType == 'web' || actionType == 'phone';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Duyuru / Reklam Yönetimi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                TextField(
                  controller: titleC,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: descC,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(
                    labelText: 'Tür',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'duyuru', child: Text('Duyuru')),
                    DropdownMenuItem(value: 'indirim', child: Text('İndirim')),
                    DropdownMenuItem(value: 'yardim', child: Text('Yardım')),
                    DropdownMenuItem(value: 'reklam', child: Text('Sponsor Reklam')),
                    DropdownMenuItem(value: 'acil', child: Text('Acil')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => type = v);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: display,
                  decoration: const InputDecoration(
                    labelText: 'Nerede Görünsün?',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'slider', child: Text('Ana Ekran Slider')),
                    DropdownMenuItem(value: 'popup', child: Text('Büyük Popup Reklam')),
                    DropdownMenuItem(value: 'small', child: Text('Küçük Reklam / Duyuru')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => display = v);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: effect,
                  decoration: const InputDecoration(
                    labelText: 'Efekt',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'konfeti', child: Text('Konfeti')),
                    DropdownMenuItem(value: 'parlama', child: Text('Parlama')),
                    DropdownMenuItem(value: 'neon', child: Text('Neon')),
                    DropdownMenuItem(value: 'pulse', child: Text('Nefes Efekti')),
                    DropdownMenuItem(value: 'shake', child: Text('Sallanma')),
                    DropdownMenuItem(value: 'uyari', child: Text('Uyarı')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => effect = v);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: popupStyle,
                  decoration: const InputDecoration(
                    labelText: 'Popup / Görsel Tarzı',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'gift', child: Text('Hediye')),
                    DropdownMenuItem(value: 'heart', child: Text('Kalp')),
                    DropdownMenuItem(value: 'discount', child: Text('İndirim')),
                    DropdownMenuItem(value: 'store', child: Text('Mağaza')),
                    DropdownMenuItem(value: 'help', child: Text('Yardım')),
                    DropdownMenuItem(value: 'medicine', child: Text('Eczane')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => popupStyle = v);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Gösterme Sıklığı',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'always', child: Text('Her açılışta')),
                    DropdownMenuItem(value: '3h', child: Text('3 saatte 1')),
                    DropdownMenuItem(value: '6h', child: Text('6 saatte 1')),
                    DropdownMenuItem(value: '12h', child: Text('12 saatte 1')),
                    DropdownMenuItem(value: 'daily', child: Text('Günde 1')),
                    DropdownMenuItem(value: 'once', child: Text('Sadece 1 kere')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => frequency = v);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Öncelik',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'medium', child: Text('Orta')),
                    DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => priority = v);
                  },
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(
                    labelText: 'Buton / Yönlendirme',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'none', child: Text('Yok - Sadece bilgilendirme')),
                    DropdownMenuItem(value: 'page', child: Text('Uygulama içi sayfa')),
                    DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                    DropdownMenuItem(value: 'web', child: Text('Web sitesi')),
                    DropdownMenuItem(value: 'phone', child: Text('Telefon')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => actionType = v);
                  },
                ),

                if (_needsButton) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: buttonC,
                    decoration: const InputDecoration(
                      labelText: 'Buton Yazısı',
                      hintText: 'Örn: Hemen Keşfet / WhatsApp’tan Yaz',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],

                if (actionType == 'page') ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: pageTarget,
                    decoration: const InputDecoration(
                      labelText: 'Hangi Sayfa?',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'market', child: Text('Market')),
                      DropdownMenuItem(value: 'free', child: Text('Ücretsiz Al & Ver')),
                      DropdownMenuItem(value: 'canDostum', child: Text('Can Dostum')),
                      DropdownMenuItem(value: 'eczane', child: Text('Nöbetçi Eczane')),
                      DropdownMenuItem(value: 'ustam', child: Text('Ustam')),
                      DropdownMenuItem(value: 'tarzim', child: Text('Tarzım')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => pageTarget = v);
                    },
                  ),
                ],

                if (_needsTarget) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: targetC,
                    keyboardType: actionType == 'web'
                        ? TextInputType.url
                        : TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: actionType == 'web'
                          ? 'Web Linki'
                          : actionType == 'whatsapp'
                          ? 'WhatsApp Numarası'
                          : 'Telefon Numarası',
                      hintText: actionType == 'web'
                          ? 'https://site.com'
                          : '905xxxxxxxxx',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Kaydet',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          StreamBuilder<QuerySnapshot>(
            stream: ref.orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snap.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: Text('Henüz içerik yok')),
                );
              }

              return Column(
                children: [
                  for (final d in docs)
                    _AdminAdCard(
                      id: d.id,
                      data: d.data() as Map<String, dynamic>,
                      color: _typeColor(
                        ((d.data() as Map<String, dynamic>)['type'] ?? '')
                            .toString(),
                      ),
                      icon: _typeIcon(
                        ((d.data() as Map<String, dynamic>)['type'] ?? '')
                            .toString(),
                      ),
                      typeName: _typeName(
                        ((d.data() as Map<String, dynamic>)['type'] ?? '')
                            .toString(),
                      ),
                      displayName: _displayName(
                        ((d.data() as Map<String, dynamic>)['display'] ??
                            'slider')
                            .toString(),
                      ),
                      frequencyName: _frequencyName(
                        ((d.data() as Map<String, dynamic>)['frequency'] ??
                            'once')
                            .toString(),
                      ),
                      actionName: _actionName(
                        ((d.data() as Map<String, dynamic>)['actionType'] ??
                            'none')
                            .toString(),
                      ),
                      onToggle: () => _toggle(
                        d.id,
                        ((d.data() as Map<String, dynamic>)['active'] == true),
                      ),
                      onDelete: () => _delete(d.id),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdminAdCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final Color color;
  final IconData icon;
  final String typeName;
  final String displayName;
  final String frequencyName;
  final String actionName;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _AdminAdCard({
    required this.id,
    required this.data,
    required this.color,
    required this.icon,
    required this.typeName,
    required this.displayName,
    required this.frequencyName,
    required this.actionName,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = data['active'] == true;
    final title = (data['title'] ?? '').toString();
    final desc = (data['desc'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Başlıksız' : title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.58),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniTag(text: typeName, color: color),
              _MiniTag(text: displayName, color: const Color(0xFF246BFF)),
              _MiniTag(text: frequencyName, color: const Color(0xFF607D8B)),
              _MiniTag(text: actionName, color: const Color(0xFF7A4DFF)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onToggle,
                icon: Icon(active ? Icons.visibility : Icons.visibility_off),
                label: Text(active ? 'Aktif' : 'Pasif'),
              ),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Sil',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String text;
  final Color color;

  const _MiniTag({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
