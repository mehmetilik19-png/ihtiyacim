import 'dart:math';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'market_catalog.dart';
import '../models/market_listing_model.dart';
import '../services/imgbb_service.dart';
import '../services/market_rtdb_service.dart';

class MarketIlanEklePage extends StatefulWidget {
  const MarketIlanEklePage({super.key});

  @override
  State<MarketIlanEklePage> createState() => _MarketIlanEklePageState();
}

class _MarketIlanEklePageState extends State<MarketIlanEklePage> {
  final _formKey = GlobalKey<FormState>();

  final _titleC = TextEditingController();
  final _oldPriceC = TextEditingController();
  final _priceC = TextEditingController();
  final _yearC = TextEditingController();

  final _picker = ImagePicker();

  String condition = '1el';
  String city = MarketCatalog.cities.first;

  String categoryMain = MarketCatalog.categoryMap.keys.first;
  late String categorySub =
  (MarketCatalog.categoryMap[categoryMain] ?? const <String>[]).isNotEmpty
      ? (MarketCatalog.categoryMap[categoryMain] ?? const <String>[]).first
      : '';

  late String brand = (MarketCatalog.brandsForMain(categoryMain)).isNotEmpty
      ? MarketCatalog.brandsForMain(categoryMain).first
      : 'Diğer';

  String vehicleBrand = MarketCatalog.autoBrands.first;
  late String vehicleModel =
      (MarketCatalog.autoModels[vehicleBrand] ?? const <String>['Diğer']).first;

  String partType =
      (MarketCatalog.categoryMap['Oto Parça'] ?? const <String>['Motor']).first;

  String motorMode = 'Komple Motor';
  String? motorVolume;
  String? motorPart;

  late String subPart =
      (MarketCatalog.autoParts[partType] ?? const <String>['Diğer']).first;

  final List<Uint8List> pickedBytes = [];
  bool loading = false;
  int uploadedCount = 0;

  bool get isAuto => categoryMain == 'Oto Parça';

  @override
  void initState() {
    super.initState();
    subPart = (MarketCatalog.autoParts[partType] ?? const <String>['Diğer']).first;
  }

  @override
  void dispose() {
    _titleC.dispose();
    _oldPriceC.dispose();
    _priceC.dispose();
    _yearC.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _generateIlanCode() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random().nextInt(900) + 100;
    return 'MKT-${now.substring(now.length - 6)}$random';
  }

  Future<void> pickPhotos() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 75);
      if (files.isEmpty) return;

      final bytesList = await Future.wait(files.map((f) => f.readAsBytes()));
      if (!mounted) return;

      setState(() => pickedBytes.addAll(bytesList));
    } catch (e) {
      _snack('Foto seçme hatası: $e');
    }
  }

  Future<void> pickFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (file == null) return;

      final b = await file.readAsBytes();
      if (!mounted) return;

      setState(() => pickedBytes.add(b));
    } catch (e) {
      _snack('Kamera açılamadı.');
    }
  }

  void removePhoto(int index) {
    setState(() => pickedBytes.removeAt(index));
  }

  String _makeId(String s) {
    return s
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      _snack('Zorunlu alanları doldur.');
      return;
    }

    if (pickedBytes.isEmpty) {
      _snack('En az 1 foto seç');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Giriş yapılmamış');
      return;
    }

    int? year;

    if (isAuto) {
      year = int.tryParse(_yearC.text.trim());

      if (year == null || year < 1950 || year > DateTime.now().year + 1) {
        _snack('Oto için model yılı zorunlu');
        return;
      }

      if (partType == 'Motor') {
        if (motorMode == 'Komple Motor') {
          if ((motorVolume ?? '').trim().isEmpty) {
            _snack('Komple motor için motor hacmi seç');
            return;
          }
        } else {
          if ((motorPart ?? '').trim().isEmpty) {
            _snack('Motor parçası seç');
            return;
          }
        }
      }
    }

    setState(() {
      loading = true;
      uploadedCount = 0;
    });

    try {
      final imgbb = ImgbbService();
      final urls = <String>[];

      for (final b in pickedBytes) {
        final url = await imgbb.uploadBytes(b);
        urls.add(url);

        if (mounted) {
          setState(() {
            uploadedCount = min(uploadedCount + 1, pickedBytes.length);
          });
        }
      }

      String finalCategorySub = categorySub;
      String finalBrand = brand;

      if (isAuto) {
        finalCategorySub = partType;
        finalBrand = vehicleBrand;
      }

      final String otoSelection = (partType == 'Motor')
          ? (motorMode == 'Komple Motor'
          ? 'Komple Motor | ${motorVolume ?? ''}'
          : 'Motor Parçası | ${motorPart ?? ''}')
          : subPart;

      final categoryPath = isAuto
          ? 'Oto Parça > $vehicleBrand > $vehicleModel > $partType > $otoSelection > ${year ?? ''}'
          : '$categoryMain > $finalCategorySub > $finalBrand';

      final categoryId = isAuto
          ? 'cat_${_makeId('oto_parca')}_${_makeId(vehicleBrand)}_${_makeId(vehicleModel)}_${_makeId(partType)}_${_makeId(otoSelection)}_${_makeId((year ?? 0).toString())}'
          : 'cat_${_makeId(categoryMain)}_${_makeId(finalCategorySub)}_${_makeId(finalBrand)}';

      final price = int.parse(_priceC.text.trim());
      final oldPrice = int.tryParse(_oldPriceC.text.trim()) ?? 0;
      final ilanCode = _generateIlanCode();

      final attrs = <String, dynamic>{
        'ownerUid': user.uid,
        'main': categoryMain,
        'sub': finalCategorySub,
        'brand': finalBrand,
        'city': city,
        'condition': condition,
        'oldPrice': oldPrice,
        'ilanCode': ilanCode,
      };

      if (isAuto) {
        attrs.addAll({
          'vehicleBrand': vehicleBrand,
          'vehicleModel': vehicleModel,
          'group': partType,
          'year': year,
          'motorMode': (partType == 'Motor') ? motorMode : null,
          'motorVolume':
          (partType == 'Motor' && motorMode == 'Komple Motor') ? motorVolume : null,
          'motorPart':
          (partType == 'Motor' && motorMode == 'Motor Parçası') ? motorPart : null,
          'part': (partType == 'Motor') ? null : subPart,
        });
      }

      final model = MarketListingModel(
        id: '',
        title: _titleC.text.trim(),
        price: price,
        condition: condition,
        categoryMain: categoryMain,
        categorySub: finalCategorySub,
        brand: finalBrand,
        city: city,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        photoUrls: urls,
        categoryId: categoryId,
        categoryPath: categoryPath,
        attrs: attrs,
      );

      await MarketRtdbService().addListing(model);

      if (mounted) {
        _snack('İlan eklendi ✅');
        Navigator.pop(context);
      }
    } catch (e) {
      _snack('Hata: $e');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          uploadedCount = 0;
        });
      }
    }
  }

  Text _ddText(String s) => Text(
    s,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context) {
    final subs = MarketCatalog.categoryMap[categoryMain] ?? const <String>[];
    final normalBrands = MarketCatalog.brandsForMain(categoryMain);

    final autoModels =
        MarketCatalog.autoModels[vehicleBrand] ?? const <String>['Diğer'];
    final partTypes =
        MarketCatalog.categoryMap['Oto Parça'] ?? const <String>['Motor'];

    final motorsForBrand = MarketCatalog.autoMotors[vehicleBrand] ?? const <String>[];
    final motorParts = MarketCatalog.autoParts['Motor'] ?? const <String>['Diğer'];

    final subPartsNonMotor =
        MarketCatalog.autoParts[partType] ?? const <String>['Diğer'];

    final total = pickedBytes.length;
    final progress = total == 0 ? 0.0 : (uploadedCount / total).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Market İlan Ekle')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Foto yükleniyor: $uploadedCount / $total'),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: Text(loading ? 'Yükleniyor...' : 'Yayınla'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            const _SectionTitle('İlan Bilgileri'),

            TextFormField(
              controller: _titleC,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Başlık zorunlu';
                if (t.length < 3) return 'Başlık çok kısa';
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _oldPriceC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Eski Fiyat (TL)',
                hintText: 'Örn: 1000',
                helperText: 'Boş bırakılırsa üstü çizili fiyat gösterilmez.',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final oldPrice = int.tryParse((v ?? '').trim()) ?? 0;
                final price = int.tryParse(_priceC.text.trim()) ?? 0;

                if (oldPrice > 0 && price > 0 && oldPrice <= price) {
                  return 'Eski fiyat, indirimli fiyattan yüksek olmalı';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _priceC,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'İndirimli / Satış Fiyatı (TL)',
                hintText: 'Örn: 500',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final p = int.tryParse((v ?? '').trim()) ?? 0;
                if (p <= 0) return 'Fiyat zorunlu';

                final oldPrice = int.tryParse(_oldPriceC.text.trim()) ?? 0;
                if (oldPrice > 0 && oldPrice <= p) {
                  return 'İndirim için eski fiyat daha yüksek olmalı';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: condition,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: MarketCatalog.conditions
                        .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                        .toList(),
                    onChanged:
                    loading ? null : (v) => setState(() => condition = v ?? '1el'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: city,
                    decoration: const InputDecoration(
                      labelText: 'Şehir',
                      border: OutlineInputBorder(),
                    ),
                    items: MarketCatalog.cities
                        .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                        .toList(),
                    onChanged: loading
                        ? null
                        : (v) => setState(() => city = v ?? MarketCatalog.cities.first),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const _SectionTitle('Kategori'),

            DropdownButtonFormField<String>(
              isExpanded: true,
              value: categoryMain,
              decoration: const InputDecoration(
                labelText: 'Ana Kategori',
                border: OutlineInputBorder(),
              ),
              items: MarketCatalog.categoryMap.keys
                  .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                  .toList(),
              onChanged: loading
                  ? null
                  : (v) {
                final newMain = v ?? MarketCatalog.categoryMap.keys.first;
                setState(() {
                  categoryMain = newMain;

                  final newSubs =
                      MarketCatalog.categoryMap[newMain] ?? const <String>[];
                  categorySub = newSubs.isNotEmpty ? newSubs.first : '';

                  final newBrands = MarketCatalog.brandsForMain(newMain);
                  brand = newBrands.isNotEmpty ? newBrands.first : 'Diğer';

                  if (newMain == 'Oto Parça') {
                    vehicleBrand = MarketCatalog.autoBrands.first;
                    vehicleModel =
                        (MarketCatalog.autoModels[vehicleBrand] ?? const ['Diğer'])
                            .first;
                    partType =
                        (MarketCatalog.categoryMap['Oto Parça'] ??
                            const <String>['Motor'])
                            .first;

                    motorMode = 'Komple Motor';
                    motorVolume = null;
                    motorPart = null;

                    subPart =
                        (MarketCatalog.autoParts[partType] ??
                            const <String>['Diğer'])
                            .first;
                    _yearC.text = '';
                  }
                });
              },
            ),

            const SizedBox(height: 12),

            if (isAuto) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: vehicleBrand,
                decoration: const InputDecoration(
                  labelText: 'Araç Markası',
                  border: OutlineInputBorder(),
                ),
                items: MarketCatalog.autoBrands
                    .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) {
                  final newBrand = v ?? MarketCatalog.autoBrands.first;
                  final models =
                      MarketCatalog.autoModels[newBrand] ?? const <String>['Diğer'];

                  setState(() {
                    vehicleBrand = newBrand;
                    vehicleModel = models.first;
                    motorMode = 'Komple Motor';
                    motorVolume = null;
                    motorPart = null;
                  });
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: vehicleModel,
                decoration: const InputDecoration(
                  labelText: 'Araç Modeli',
                  border: OutlineInputBorder(),
                ),
                items: autoModels
                    .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                    .toList(),
                onChanged:
                loading ? null : (v) => setState(() => vehicleModel = v ?? autoModels.first),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: partType,
                decoration: const InputDecoration(
                  labelText: 'Parça Türü',
                  border: OutlineInputBorder(),
                ),
                items: partTypes
                    .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) {
                  final newType = v ?? partTypes.first;
                  setState(() {
                    partType = newType;
                    subPart =
                        (MarketCatalog.autoParts[newType] ??
                            const <String>['Diğer'])
                            .first;
                    motorMode = 'Komple Motor';
                    motorVolume = null;
                    motorPart = null;
                  });
                },
              ),

              const SizedBox(height: 12),

              if (partType == 'Motor') ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: motorMode,
                  decoration: const InputDecoration(
                    labelText: 'Motor Seçimi',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Komple Motor', child: Text('Komple Motor')),
                    DropdownMenuItem(value: 'Motor Parçası', child: Text('Motor Parçası')),
                  ],
                  onChanged: loading
                      ? null
                      : (v) {
                    setState(() {
                      motorMode = v ?? 'Komple Motor';
                      motorVolume = null;
                      motorPart = null;
                    });
                  },
                ),

                const SizedBox(height: 12),

                if (motorMode == 'Komple Motor') ...[
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: motorVolume,
                    decoration: const InputDecoration(
                      labelText: 'Motor Hacmi',
                      border: OutlineInputBorder(),
                    ),
                    items: motorsForBrand
                        .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                        .toList(),
                    onChanged: loading ? null : (v) => setState(() => motorVolume = v),
                  ),
                  const SizedBox(height: 12),
                ],

                if (motorMode == 'Motor Parçası') ...[
                  DropdownButtonFormField<String?>(
                    isExpanded: true,
                    value: motorPart,
                    decoration: const InputDecoration(
                      labelText: 'Motor Parçası',
                      border: OutlineInputBorder(),
                    ),
                    items: motorParts
                        .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                        .toList(),
                    onChanged: loading ? null : (v) => setState(() => motorPart = v),
                  ),
                  const SizedBox(height: 12),
                ],
              ] else ...[
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: subPart,
                  decoration: const InputDecoration(
                    labelText: 'Alt Parça',
                    border: OutlineInputBorder(),
                  ),
                  items: subPartsNonMotor
                      .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                      .toList(),
                  onChanged:
                  loading ? null : (v) => setState(() => subPart = v ?? subPartsNonMotor.first),
                ),
                const SizedBox(height: 12),
              ],

              TextFormField(
                controller: _yearC,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Model Yılı',
                  border: OutlineInputBorder(),
                  hintText: 'Örn: 2008',
                ),
                validator: (v) {
                  if (!isAuto) return null;
                  final y = int.tryParse((v ?? '').trim());
                  if (y == null) return 'Model yılı zorunlu';
                  if (y < 1950 || y > DateTime.now().year + 1) {
                    return 'Model yılı geçersiz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),
            ] else ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: categorySub.isNotEmpty
                    ? categorySub
                    : (subs.isNotEmpty ? subs.first : ''),
                decoration: const InputDecoration(
                  labelText: 'Alt Kategori',
                  border: OutlineInputBorder(),
                ),
                items: subs
                    .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) => setState(
                      () => categorySub = v ?? (subs.isNotEmpty ? subs.first : ''),
                ),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                isExpanded: true,
                value: brand,
                decoration: const InputDecoration(
                  labelText: 'Marka',
                  border: OutlineInputBorder(),
                ),
                items: normalBrands
                    .map((x) => DropdownMenuItem(value: x, child: _ddText(x)))
                    .toList(),
                onChanged: loading
                    ? null
                    : (v) => setState(
                      () => brand =
                      v ?? (normalBrands.isNotEmpty ? normalBrands.first : 'Diğer'),
                ),
              ),

              const SizedBox(height: 12),
            ],

            const SizedBox(height: 16),
            const _SectionTitle('Fotoğraflar'),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : pickPhotos,
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      pickedBytes.isEmpty ? 'Foto Seç' : 'Galeri (${pickedBytes.length})',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: loading ? null : pickFromCamera,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Foto Çek'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (pickedBytes.isNotEmpty) ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pickedBytes.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          pickedBytes[i],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: loading ? null : () => removePhoto(i),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      if (i == 0)
                        Positioned(
                          bottom: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Kapak',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'İpucu: İlk foto kapak olarak görünür.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}