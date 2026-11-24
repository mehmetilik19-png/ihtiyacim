import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/market_listing_model.dart';
import '../services/market_rtdb_service.dart';

class MarketIlanDuzenlePage extends StatefulWidget {
  final MarketListingModel item;

  const MarketIlanDuzenlePage({
    super.key,
    required this.item,
  });

  @override
  State<MarketIlanDuzenlePage> createState() =>
      _MarketIlanDuzenlePageState();
}

class _MarketIlanDuzenlePageState extends State<MarketIlanDuzenlePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleC;
  late final TextEditingController _oldPriceC;
  late final TextEditingController _priceC;
  late final TextEditingController _descriptionC;
  late final TextEditingController _materialC;
  late final TextEditingController _colorC;
  late final TextEditingController _heightC;
  late final TextEditingController _widthC;
  late final TextEditingController _depthC;
  late final TextEditingController _categoryMainC;
  late final TextEditingController _categorySubC;
  late final TextEditingController _brandC;
  late final TextEditingController _cityC;

  late String condition;
  bool saving = false;

  String _s(dynamic value) => (value ?? '').toString().trim();

  String _attr(List<String> keys) {
    for (final key in keys) {
      final value = _s(widget.item.attrs[key]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();

    _titleC = TextEditingController(text: widget.item.title);
    _oldPriceC = TextEditingController(
      text: widget.item.oldPrice > 0
          ? widget.item.oldPrice.toString()
          : '',
    );
    _priceC = TextEditingController(text: widget.item.price.toString());
    _descriptionC = TextEditingController(
      text: _attr([
        'description',
        'aciklama',
        'productDescription',
        'urunBilgileri',
      ]),
    );
    _materialC = TextEditingController(
      text: _attr(['material', 'materyal']),
    );
    _colorC = TextEditingController(
      text: _attr(['color', 'renk']),
    );
    _heightC = TextEditingController(
      text: _attr(['height', 'yukseklik']),
    );
    _widthC = TextEditingController(
      text: _attr(['width', 'genislik']),
    );
    _depthC = TextEditingController(
      text: _attr(['depth', 'derinlik']),
    );
    _categoryMainC = TextEditingController(text: widget.item.categoryMain);
    _categorySubC = TextEditingController(text: widget.item.categorySub);
    _brandC = TextEditingController(text: widget.item.brand);
    _cityC = TextEditingController(text: widget.item.city);
    condition = widget.item.condition == '1el' ? '1el' : '2el';
  }

  @override
  void dispose() {
    _titleC.dispose();
    _oldPriceC.dispose();
    _priceC.dispose();
    _descriptionC.dispose();
    _materialC.dispose();
    _colorC.dispose();
    _heightC.dispose();
    _widthC.dispose();
    _depthC.dispose();
    _categoryMainC.dispose();
    _categorySubC.dispose();
    _brandC.dispose();
    _cityC.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _putOrRemove(
    Map<String, dynamic> attrs,
    String key,
    String value,
  ) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) {
      attrs.remove(key);
    } else {
      attrs[key] = cleaned;
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPrice = int.parse(_priceC.text.trim());
    int oldPrice = int.tryParse(_oldPriceC.text.trim()) ?? 0;

    if (oldPrice == 0 && newPrice < widget.item.price) {
      oldPrice = widget.item.price;
    }

    if (oldPrice > 0 && oldPrice <= newPrice) {
      oldPrice = 0;
    }

    setState(() => saving = true);

    try {
      final attrs = Map<String, dynamic>.from(widget.item.attrs)
        ..['oldPrice'] = oldPrice
        ..['ilanCode'] = widget.item.ilanCode;

      _putOrRemove(attrs, 'description', _descriptionC.text);
      _putOrRemove(attrs, 'material', _materialC.text);
      _putOrRemove(attrs, 'color', _colorC.text);
      _putOrRemove(attrs, 'height', _heightC.text);
      _putOrRemove(attrs, 'width', _widthC.text);
      _putOrRemove(attrs, 'depth', _depthC.text);

      final patch = <String, dynamic>{
        'title': _titleC.text.trim(),
        'price': newPrice,
        'oldPrice': oldPrice,
        'condition': condition,
        'categoryMain': _categoryMainC.text.trim(),
        'categorySub': _categorySubC.text.trim(),
        'brand': _brandC.text.trim(),
        'categoryPath': '${_categoryMainC.text.trim()} > ${_categorySubC.text.trim()} > ${_brandC.text.trim()}',
        'city': _cityC.text.trim(),
        'attrs': attrs,
      };

      await MarketRtdbService().updateListing(
        widget.item.id,
        patch,
      );

      final updated = widget.item.copyWith(
        title: _titleC.text.trim(),
        price: newPrice,
        oldPrice: oldPrice,
        condition: condition,
        categoryMain: _categoryMainC.text.trim(),
        categorySub: _categorySubC.text.trim(),
        brand: _brandC.text.trim(),
        categoryPath: '${_categoryMainC.text.trim()} > ${_categorySubC.text.trim()} > ${_brandC.text.trim()}',
        city: _cityC.text.trim(),
        attrs: attrs,
      );

      if (!mounted) return;

      _snack('İlan güncellendi ✅');
      Navigator.pop(context, updated);
    } catch (error) {
      _snack('İlan güncellenemedi: $error');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('İlanı Düzenle')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                saving ? 'Kaydediliyor...' : 'Değişiklikleri Kaydet',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            _EditSection(
              title: 'Temel Bilgiler',
              children: [
                TextFormField(
                  controller: _titleC,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.length < 3) return 'Başlık çok kısa';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _oldPriceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Eski fiyat',
                    helperText:
                        'İndirim yoksa boş bırak. Yeni fiyat daha düşükse otomatik doldurulur.',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Yeni satış fiyatı',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final price =
                        int.tryParse((value ?? '').trim()) ?? 0;
                    if (price <= 0) return 'Geçerli fiyat gir';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: condition,
                  decoration: const InputDecoration(
                    labelText: 'Durum',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '1el',
                      child: Text('1. El'),
                    ),
                    DropdownMenuItem(
                      value: '2el',
                      child: Text('2. El'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => condition = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryMainC,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ana kategori',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Ana kategori boş olamaz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categorySubC,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Alt kategori',
                    hintText: 'Örnek: Ayakkabılık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Alt kategori boş olamaz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _brandC,
                  decoration: const InputDecoration(
                    labelText: 'Marka',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityC,
                  decoration: const InputDecoration(
                    labelText: 'Şehir',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            _EditSection(
              title: 'Ürün Bilgileri',
              children: [
                TextFormField(
                  controller: _descriptionC,
                  minLines: 5,
                  maxLines: 12,
                  decoration: const InputDecoration(
                    labelText: 'Açıklama',
                    hintText: 'Her maddeyi ayrı satıra yaz.',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            _EditSection(
              title: 'Ürün Özellikleri',
              children: [
                TextFormField(
                  controller: _materialC,
                  decoration: const InputDecoration(
                    labelText: 'Materyal',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _colorC,
                  decoration: const InputDecoration(
                    labelText: 'Renk',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _heightC,
                  decoration: const InputDecoration(
                    labelText: 'Yükseklik',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _widthC,
                  decoration: const InputDecoration(
                    labelText: 'Genişlik',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _depthC,
                  decoration: const InputDecoration(
                    labelText: 'Derinlik',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _EditSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _EditSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
