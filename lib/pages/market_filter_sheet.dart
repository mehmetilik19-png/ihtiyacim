import 'package:flutter/material.dart';

@immutable
class MarketFilterResult {
  final String? main;
  final String? sub;
  final String? brand;
  final String? city;

  final int? minPrice;
  final int? maxPrice;

  // Oto için
  final String? model;
  final String? group;
  final String? part;
  final int? year;

  const MarketFilterResult({
    this.main,
    this.sub,
    this.brand,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.model,
    this.group,
    this.part,
    this.year,
  });

  const MarketFilterResult.empty() : this();
}

class MarketFilterSheet extends StatefulWidget {
  final MarketFilterResult initial;

  const MarketFilterSheet({super.key, required this.initial});

  @override
  State<MarketFilterSheet> createState() => _MarketFilterSheetState();
}

class _MarketFilterSheetState extends State<MarketFilterSheet> {
  late final TextEditingController _main =
  TextEditingController(text: widget.initial.main ?? '');
  late final TextEditingController _sub =
  TextEditingController(text: widget.initial.sub ?? '');
  late final TextEditingController _brand =
  TextEditingController(text: widget.initial.brand ?? '');
  late final TextEditingController _city =
  TextEditingController(text: widget.initial.city ?? '');

  late final TextEditingController _minPrice =
  TextEditingController(text: widget.initial.minPrice?.toString() ?? '');
  late final TextEditingController _maxPrice =
  TextEditingController(text: widget.initial.maxPrice?.toString() ?? '');

  // oto
  late final TextEditingController _model =
  TextEditingController(text: widget.initial.model ?? '');
  late final TextEditingController _group =
  TextEditingController(text: widget.initial.group ?? '');
  late final TextEditingController _part =
  TextEditingController(text: widget.initial.part ?? '');
  late final TextEditingController _year =
  TextEditingController(text: widget.initial.year?.toString() ?? '');

  @override
  void dispose() {
    _main.dispose();
    _sub.dispose();
    _brand.dispose();
    _city.dispose();
    _minPrice.dispose();
    _maxPrice.dispose();
    _model.dispose();
    _group.dispose();
    _part.dispose();
    _year.dispose();
    super.dispose();
  }

  int? _tryInt(String s) => int.tryParse(s.trim());

  void _apply() {
    Navigator.pop(
      context,
      MarketFilterResult(
        main: _main.text.trim().isEmpty ? null : _main.text.trim(),
        sub: _sub.text.trim().isEmpty ? null : _sub.text.trim(),
        brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        minPrice: _minPrice.text.trim().isEmpty ? null : _tryInt(_minPrice.text),
        maxPrice: _maxPrice.text.trim().isEmpty ? null : _tryInt(_maxPrice.text),
        model: _model.text.trim().isEmpty ? null : _model.text.trim(),
        group: _group.text.trim().isEmpty ? null : _group.text.trim(),
        part: _part.text.trim().isEmpty ? null : _part.text.trim(),
        year: _year.text.trim().isEmpty ? null : _tryInt(_year.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('Filtrele', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 12),

            TextField(controller: _main, decoration: const InputDecoration(labelText: 'Ana Kategori (main)')),
            TextField(controller: _sub, decoration: const InputDecoration(labelText: 'Alt Kategori (sub)')),
            TextField(controller: _brand, decoration: const InputDecoration(labelText: 'Marka (brand)')),
            TextField(controller: _city, decoration: const InputDecoration(labelText: 'Şehir')),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _minPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Fiyat'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _maxPrice, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Fiyat'))),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 6),

            TextField(controller: _model, decoration: const InputDecoration(labelText: 'Araç Modeli (vehicleModel)')),
            TextField(controller: _group, decoration: const InputDecoration(labelText: 'Grup (group)')),
            TextField(controller: _part, decoration: const InputDecoration(labelText: 'Parça (part)')),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Yıl')),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, widget.initial),
                    child: const Text('Vazgeç'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _apply,
                    child: const Text('Uygula'),
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