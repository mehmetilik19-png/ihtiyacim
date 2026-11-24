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

  final _descriptionC = TextEditingController();
  final _materialC = TextEditingController();
  final _colorC = TextEditingController();
  final _heightC = TextEditingController();
  final _widthC = TextEditingController();
  final _depthC = TextEditingController();
  final _customCategoryC = TextEditingController();
  final _customBrandC = TextEditingController();

  final _picker = ImagePicker();

  String condition = '1el';
  String city = MarketCatalog.cities.first;

  String categoryMain = MarketCatalog.categoryMap.keys.first;
  late String categorySub =
      (MarketCatalog.categoryMap[categoryMain] ?? const <String>[]).isNotEmpty
          ? (MarketCatalog.categoryMap[categoryMain] ?? const <String>[]).first
          : '';

  late String brand = MarketCatalog.brandsForMain(categoryMain).isNotEmpty
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
    subPart =
        (MarketCatalog.autoParts[partType] ?? const <String>['Diğer']).first;
  }

  @override
  void dispose() {
    _titleC.dispose();
    _oldPriceC.dispose();
    _priceC.dispose();
    _yearC.dispose();
    _descriptionC.dispose();
    _materialC.dispose();
    _colorC.dispose();
    _heightC.dispose();
    _widthC.dispose();
    _depthC.dispose();
    _customCategoryC.dispose();
    _customBrandC.dispose();
    super.dispose();
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

      final bytesList = await Future.wait(
        files.map((file) => file.readAsBytes()),
      );

      if (!mounted) return;
      setState(() => pickedBytes.addAll(bytesList));
    } catch (error) {
      _snack('Fotoğraf seçme hatası: $error');
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

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() => pickedBytes.add(bytes));
    } catch (_) {
      _snack('Kamera açılamadı.');
    }
  }

  void removePhoto(int index) {
    setState(() => pickedBytes.removeAt(index));
  }

  String _makeId(String value) {
    return value
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

  void _putIfNotEmpty(
    Map<String, dynamic> attrs,
    String key,
    String value,
  ) {
    final cleaned = value.trim();
    if (cleaned.isNotEmpty) {
      attrs[key] = cleaned;
    }
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      _snack('Zorunlu alanları doldur.');
      return;
    }

    if (pickedBytes.isEmpty) {
      _snack('En az 1 fotoğraf seç.');
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _snack('Giriş yapılmamış.');
      return;
    }

    int? year;

    if (isAuto) {
      year = int.tryParse(_yearC.text.trim());

      if (year == null ||
          year < 1950 ||
          year > DateTime.now().year + 1) {
        _snack('Oto kategorisi için geçerli model yılı gir.');
        return;
      }

      if (partType == 'Motor') {
        if (motorMode == 'Komple Motor' &&
            (motorVolume ?? '').trim().isEmpty) {
          _snack('Komple motor için motor hacmi seç.');
          return;
        }

        if (motorMode == 'Motor Parçası' &&
            (motorPart ?? '').trim().isEmpty) {
          _snack('Motor parçası seç.');
          return;
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

      for (final bytes in pickedBytes) {
        final url = await imgbb.uploadBytes(bytes);
        urls.add(url);

        if (mounted) {
          setState(() {
            uploadedCount = min(
              uploadedCount + 1,
              pickedBytes.length,
            );
          });
        }
      }

      String finalCategorySub = categorySub == MarketCatalog.other
          ? _customCategoryC.text.trim()
          : categorySub;
      String finalBrand = brand == MarketCatalog.other
          ? _customBrandC.text.trim()
          : brand;

      if (!isAuto && finalCategorySub.isEmpty) {
        throw StateError('Kategori adını yazmalısın.');
      }
      if (!isAuto && finalBrand.isEmpty) {
        throw StateError('Marka adını yazmalısın.');
      }

      if (isAuto) {
        finalCategorySub = partType;
        finalBrand = vehicleBrand;
      }

      final otoSelection = partType == 'Motor'
          ? motorMode == 'Komple Motor'
              ? 'Komple Motor | ${motorVolume ?? ''}'
              : 'Motor Parçası | ${motorPart ?? ''}'
          : subPart;

      final categoryPath = isAuto
          ? 'Oto Parça > $vehicleBrand > $vehicleModel > '
              '$partType > $otoSelection > ${year ?? ''}'
          : '$categoryMain > $finalCategorySub > $finalBrand';

      final categoryId = isAuto
          ? 'cat_${_makeId('oto_parca')}_${_makeId(vehicleBrand)}_'
              '${_makeId(vehicleModel)}_${_makeId(partType)}_'
              '${_makeId(otoSelection)}_${_makeId((year ?? 0).toString())}'
          : 'cat_${_makeId(categoryMain)}_'
              '${_makeId(finalCategorySub)}_${_makeId(finalBrand)}';

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
        'active': true,
      };

      _putIfNotEmpty(attrs, 'description', _descriptionC.text);
      _putIfNotEmpty(attrs, 'material', _materialC.text);
      _putIfNotEmpty(attrs, 'color', _colorC.text);
      _putIfNotEmpty(attrs, 'height', _heightC.text);
      _putIfNotEmpty(attrs, 'width', _widthC.text);
      _putIfNotEmpty(attrs, 'depth', _depthC.text);

      if (isAuto) {
        attrs.addAll({
          'vehicleBrand': vehicleBrand,
          'vehicleModel': vehicleModel,
          'group': partType,
          'year': year,
          if (partType == 'Motor') 'motorMode': motorMode,
          if (partType == 'Motor' && motorMode == 'Komple Motor')
            'motorVolume': motorVolume,
          if (partType == 'Motor' && motorMode == 'Motor Parçası')
            'motorPart': motorPart,
          if (partType != 'Motor') 'part': subPart,
        });
      }

      final model = MarketListingModel(
        id: '',
        title: _titleC.text.trim(),
        price: price,
        oldPrice: oldPrice,
        ilanCode: ilanCode,
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

      if (!mounted) return;

      _snack('İlan eklendi ✅');
      Navigator.pop(context);
    } catch (error) {
      _snack('Hata: $error');
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
          uploadedCount = 0;
        });
      }
    }
  }

  Text _ddText(String value) => Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );

  Widget _fieldGap() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext context) {
    final subs =
        MarketCatalog.categoryMap[categoryMain] ?? const <String>[];
    final normalBrands = MarketCatalog.brandsForMain(categoryMain);
    final autoModels =
        MarketCatalog.autoModels[vehicleBrand] ?? const <String>['Diğer'];
    final partTypes =
        MarketCatalog.categoryMap['Oto Parça'] ?? const <String>['Motor'];
    final motorsForBrand =
        MarketCatalog.autoMotors[vehicleBrand] ?? const <String>[];
    final motorParts =
        MarketCatalog.autoParts['Motor'] ?? const <String>['Diğer'];
    final subPartsNonMotor =
        MarketCatalog.autoParts[partType] ?? const <String>['Diğer'];

    final total = pickedBytes.length;
    final progress =
        total == 0 ? 0.0 : (uploadedCount / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(title: const Text('Market İlan Ekle')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fotoğraf yükleniyor: $uploadedCount / $total',
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : submit,
                  child: Text(
                    loading ? 'Yükleniyor...' : 'Yayınla',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
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
            _CardSection(
              title: 'İlan Bilgileri',
              children: [
                TextFormField(
                  controller: _titleC,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) return 'Başlık zorunlu';
                    if (text.length < 3) return 'Başlık çok kısa';
                    return null;
                  },
                ),
                _fieldGap(),
                TextFormField(
                  controller: _oldPriceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Eski Fiyat (TL)',
                    hintText: 'Örnek: 1000',
                    helperText:
                        'İndirim yoksa boş bırak. Eski fiyat satış fiyatından yüksek olmalı.',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final oldPrice =
                        int.tryParse((value ?? '').trim()) ?? 0;
                    final price =
                        int.tryParse(_priceC.text.trim()) ?? 0;

                    if (oldPrice > 0 &&
                        price > 0 &&
                        oldPrice <= price) {
                      return 'Eski fiyat satış fiyatından yüksek olmalı';
                    }

                    return null;
                  },
                ),
                _fieldGap(),
                TextFormField(
                  controller: _priceC,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Satış Fiyatı (TL)',
                    hintText: 'Örnek: 900',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final price =
                        int.tryParse((value ?? '').trim()) ?? 0;
                    if (price <= 0) return 'Fiyat zorunlu';

                    final oldPrice =
                        int.tryParse(_oldPriceC.text.trim()) ?? 0;
                    if (oldPrice > 0 && oldPrice <= price) {
                      return 'İndirim için eski fiyat daha yüksek olmalı';
                    }

                    return null;
                  },
                ),
                _fieldGap(),
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
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: _ddText(item),
                              ),
                            )
                            .toList(),
                        onChanged: loading
                            ? null
                            : (value) {
                                setState(() {
                                  condition = value ?? '1el';
                                });
                              },
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
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: _ddText(item),
                              ),
                            )
                            .toList(),
                        onChanged: loading
                            ? null
                            : (value) {
                                setState(() {
                                  city =
                                      value ?? MarketCatalog.cities.first;
                                });
                              },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            _CardSection(
              title: 'Ürün Bilgileri',
              children: [
                TextFormField(
                  controller: _descriptionC,
                  minLines: 5,
                  maxLines: 12,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Ürün açıklaması',
                    hintText:
                        'Her özelliği ayrı satıra yaz. Detay sayfasında madde madde görünür.',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
            _CardSection(
              title: 'Ürün Özellikleri',
              children: [
                TextFormField(
                  controller: _materialC,
                  decoration: const InputDecoration(
                    labelText: 'Materyal',
                    hintText: 'Örnek: Metal',
                    border: OutlineInputBorder(),
                  ),
                ),
                _fieldGap(),
                TextFormField(
                  controller: _colorC,
                  decoration: const InputDecoration(
                    labelText: 'Renk',
                    hintText: 'Örnek: Beyaz',
                    border: OutlineInputBorder(),
                  ),
                ),
                _fieldGap(),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightC,
                        decoration: const InputDecoration(
                          labelText: 'Yükseklik',
                          hintText: '104 cm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _widthC,
                        decoration: const InputDecoration(
                          labelText: 'Genişlik',
                          hintText: '50 cm',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                _fieldGap(),
                TextFormField(
                  controller: _depthC,
                  decoration: const InputDecoration(
                    labelText: 'Derinlik',
                    hintText: '15 cm',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            _CardSection(
              title: 'Kategori',
              children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: categoryMain,
                  decoration: const InputDecoration(
                    labelText: 'Ana Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: MarketCatalog.categoryMap.keys
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: _ddText(item),
                        ),
                      )
                      .toList(),
                  onChanged: loading
                      ? null
                      : (value) {
                          final newMain = value ??
                              MarketCatalog.categoryMap.keys.first;

                          setState(() {
                            categoryMain = newMain;
                            _customCategoryC.clear();
                            _customBrandC.clear();

                            final newSubs =
                                MarketCatalog.categoryMap[newMain] ??
                                    const <String>[];
                            categorySub =
                                newSubs.isNotEmpty ? newSubs.first : '';

                            final newBrands =
                                MarketCatalog.brandsForMain(newMain);
                            brand = newBrands.isNotEmpty
                                ? newBrands.first
                                : 'Diğer';

                            if (newMain == 'Oto Parça') {
                              vehicleBrand =
                                  MarketCatalog.autoBrands.first;
                              vehicleModel =
                                  (MarketCatalog.autoModels[vehicleBrand] ??
                                          const <String>['Diğer'])
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
                              _yearC.clear();
                            }
                          });
                        },
                ),
                _fieldGap(),
                if (isAuto) ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: vehicleBrand,
                    decoration: const InputDecoration(
                      labelText: 'Araç Markası',
                      border: OutlineInputBorder(),
                    ),
                    items: MarketCatalog.autoBrands
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: _ddText(item),
                          ),
                        )
                        .toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            final newBrand =
                                value ?? MarketCatalog.autoBrands.first;
                            final models =
                                MarketCatalog.autoModels[newBrand] ??
                                    const <String>['Diğer'];

                            setState(() {
                              vehicleBrand = newBrand;
                              vehicleModel = models.first;
                              motorMode = 'Komple Motor';
                              motorVolume = null;
                              motorPart = null;
                            });
                          },
                  ),
                  _fieldGap(),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: vehicleModel,
                    decoration: const InputDecoration(
                      labelText: 'Araç Modeli',
                      border: OutlineInputBorder(),
                    ),
                    items: autoModels
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: _ddText(item),
                          ),
                        )
                        .toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              vehicleModel = value ?? autoModels.first;
                            });
                          },
                  ),
                  _fieldGap(),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: partType,
                    decoration: const InputDecoration(
                      labelText: 'Parça Türü',
                      border: OutlineInputBorder(),
                    ),
                    items: partTypes
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: _ddText(item),
                          ),
                        )
                        .toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            final newType = value ?? partTypes.first;

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
                  _fieldGap(),
                  if (partType == 'Motor') ...[
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: motorMode,
                      decoration: const InputDecoration(
                        labelText: 'Motor Seçimi',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Komple Motor',
                          child: Text('Komple Motor'),
                        ),
                        DropdownMenuItem(
                          value: 'Motor Parçası',
                          child: Text('Motor Parçası'),
                        ),
                      ],
                      onChanged: loading
                          ? null
                          : (value) {
                              setState(() {
                                motorMode = value ?? 'Komple Motor';
                                motorVolume = null;
                                motorPart = null;
                              });
                            },
                    ),
                    _fieldGap(),
                    if (motorMode == 'Komple Motor') ...[
                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        value: motorVolume,
                        decoration: const InputDecoration(
                          labelText: 'Motor Hacmi',
                          border: OutlineInputBorder(),
                        ),
                        items: motorsForBrand
                            .map(
                              (item) => DropdownMenuItem<String?>(
                                value: item,
                                child: _ddText(item),
                              ),
                            )
                            .toList(),
                        onChanged: loading
                            ? null
                            : (value) {
                                setState(() => motorVolume = value);
                              },
                      ),
                      _fieldGap(),
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
                            .map(
                              (item) => DropdownMenuItem<String?>(
                                value: item,
                                child: _ddText(item),
                              ),
                            )
                            .toList(),
                        onChanged: loading
                            ? null
                            : (value) {
                                setState(() => motorPart = value);
                              },
                      ),
                      _fieldGap(),
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
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: _ddText(item),
                            ),
                          )
                          .toList(),
                      onChanged: loading
                          ? null
                          : (value) {
                              setState(() {
                                subPart =
                                    value ?? subPartsNonMotor.first;
                              });
                            },
                    ),
                    _fieldGap(),
                  ],
                  TextFormField(
                    controller: _yearC,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Model Yılı',
                      hintText: 'Örnek: 2008',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!isAuto) return null;

                      final year =
                          int.tryParse((value ?? '').trim());
                      if (year == null) {
                        return 'Model yılı zorunlu';
                      }

                      if (year < 1950 ||
                          year > DateTime.now().year + 1) {
                        return 'Model yılı geçersiz';
                      }

                      return null;
                    },
                  ),
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
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: _ddText(item),
                          ),
                        )
                        .toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              categorySub = value ??
                                  (subs.isNotEmpty ? subs.first : '');
                            });
                          },
                  ),
                  _fieldGap(),
                  if (categorySub == MarketCatalog.other) ...[
                    TextFormField(
                      controller: _customCategoryC,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Kategori adını kendin yaz',
                        hintText: 'Örnek: Ayakkabılık',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!isAuto &&
                            categorySub == MarketCatalog.other &&
                            (value ?? '').trim().isEmpty) {
                          return 'Kategori adını yaz';
                        }
                        return null;
                      },
                    ),
                    _fieldGap(),
                  ],
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: brand,
                    decoration: const InputDecoration(
                      labelText: 'Marka',
                      border: OutlineInputBorder(),
                    ),
                    items: normalBrands
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: _ddText(item),
                          ),
                        )
                        .toList(),
                    onChanged: loading
                        ? null
                        : (value) {
                            setState(() {
                              brand = value ??
                                  (normalBrands.isNotEmpty
                                      ? normalBrands.first
                                      : 'Diğer');
                            });
                          },
                  ),
                  if (brand == MarketCatalog.other) ...[
                    _fieldGap(),
                    TextFormField(
                      controller: _customBrandC,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Markayı kendin yaz',
                        hintText: 'Örnek: Formood veya Özel Üretim',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (!isAuto &&
                            brand == MarketCatalog.other &&
                            (value ?? '').trim().isEmpty) {
                          return 'Marka adını yaz';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ],
            ),
            _CardSection(
              title: 'Fotoğraflar',
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : pickPhotos,
                        icon: const Icon(Icons.photo_library),
                        label: Text(
                          pickedBytes.isEmpty
                              ? 'Fotoğraf Seç'
                              : 'Galeri (${pickedBytes.length})',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: loading ? null : pickFromCamera,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Fotoğraf Çek'),
                      ),
                    ),
                  ],
                ),
                if (pickedBytes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pickedBytes.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              pickedBytes[index],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: InkWell(
                              onTap: loading
                                  ? null
                                  : () => removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                          if (index == 0)
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
                                  borderRadius:
                                      BorderRadius.circular(999),
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
                    'İlk fotoğraf kapak olarak görünür.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _CardSection({
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
