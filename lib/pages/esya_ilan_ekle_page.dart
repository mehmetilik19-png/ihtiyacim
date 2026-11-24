import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';

import '../models/ilan_model.dart';
import '../services/ai_image_service.dart';
import '../features/auth/login_page.dart';

class EsyaIlanEklePage extends StatefulWidget {
  const EsyaIlanEklePage({super.key});

  @override
  State<EsyaIlanEklePage> createState() => _EsyaIlanEklePageState();
}

class _EsyaIlanEklePageState extends State<EsyaIlanEklePage> {
  static const Color _bgColor = Color(0xFFF4F1E8);
  static const Color _cardColor = Color(0xFFFFFCF4);
  static const Color _primaryColor = Color(0xFF5F7867);
  static const Color _primarySoft = Color(0xFFDDE6DC);
  static const Color _borderColor = Color(0xFFD5DDD2);
  static const Color _textColor = Color(0xFF26352C);
  static const Color _mutedColor = Color(0xFF6D786F);

  static const int _maxImageCount = 6;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref('esya_paylas/items');

  final TextEditingController _titleC = TextEditingController();
  final TextEditingController _descC = TextEditingController();
  final TextEditingController _phoneC = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final AiImageService _imageService = AiImageService();

  final List<File> _pickedFiles = <File>[];

  String selectedAnaKategori = 'Beyaz Eşya';
  String? selectedAltKategori;
  String? selectedSehir;

  String _tradeType = 'free';
  bool _saving = false;

  final Map<String, List<String>> kategoriMap = const {
    'Beyaz Eşya': [
      'Buzdolabı',
      'Çamaşır Makinesi',
      'Bulaşık Makinesi',
      'Fırın',
      'Ocak',
      'Derin Dondurucu',
    ],
    'Mobilya': [
      'Koltuk',
      'Kanepe',
      'Yatak',
      'Masa',
      'Sandalye',
      'Dolap',
    ],
    'Elektronik': [
      'Telefon',
      'Tablet',
      'Bilgisayar',
      'Televizyon',
      'Küçük Ev Aleti',
    ],
    'Giyim': [
      'Kadın',
      'Erkek',
      'Çocuk',
      'Ayakkabı',
      'Mont',
    ],
    'Mutfak': [
      'Tencere',
      'Tabak',
      'Bardak',
      'Çatal Kaşık',
      'Mutfak Robotu',
    ],
    'Kitap': [
      'Roman',
      'Ders Kitabı',
      'Çocuk Kitabı',
      'Kırtasiye',
    ],
    'Diğer': [
      'Oyuncak',
      'Bebek Ürünü',
      'Spor',
      'Bahçe',
      'Diğer',
    ],
  };

  static const List<String> sehirler = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Amasya',
    'Ankara',
    'Antalya',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Isparta',
    'Mersin',
    'İstanbul',
    'İzmir',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Kahramanmaraş',
    'Mardin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Şanlıurfa',
    'Uşak',
    'Van',
    'Yozgat',
    'Zonguldak',
    'Aksaray',
    'Bayburt',
    'Karaman',
    'Kırıkkale',
    'Batman',
    'Şırnak',
    'Bartın',
    'Ardahan',
    'Iğdır',
    'Yalova',
    'Karabük',
    'Kilis',
    'Osmaniye',
    'Düzce',
  ];

  @override
  void dispose() {
    _titleC.dispose();
    _descC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  Future<void> _goLogin() async {
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }

  Future<void> _pickMultiImages() async {
    try {
      final remainingCount = _maxImageCount - _pickedFiles.length;

      if (remainingCount <= 0) {
        _snack('En fazla $_maxImageCount fotoğraf ekleyebilirsin.');
        return;
      }

      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (images.isEmpty || !mounted) return;

      final selectedImages = images.take(remainingCount).toList();

      setState(() {
        _pickedFiles.addAll(
          selectedImages.map((image) => File(image.path)),
        );
      });

      if (images.length > remainingCount) {
        _snack(
          'En fazla $_maxImageCount fotoğraf eklenebilir. '
              'İlk $remainingCount fotoğraf seçildi.',
        );
      }
    } catch (error) {
      _snack('Galeriden fotoğraf seçilemedi: $error');
    }
  }

  Future<void> _takePhoto() async {
    try {
      if (_pickedFiles.length >= _maxImageCount) {
        _snack('En fazla $_maxImageCount fotoğraf ekleyebilirsin.');
        return;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null || !mounted) return;

      setState(() {
        _pickedFiles.add(File(image.path));
      });
    } catch (error) {
      _snack('Kamera açılamadı: $error');
    }
  }

  Future<void> _showImageSourceSheet() async {
    if (_saving) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardColor,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fotoğraf Ekle',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'En fazla $_maxImageCount fotoğraf ekleyebilirsin.',
                  style: const TextStyle(
                    color: _mutedColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _ImageSourceTile(
                  icon: Icons.camera_alt_rounded,
                  title: 'Kamerayla çek',
                  subtitle: 'Şimdi yeni bir fotoğraf çek',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _takePhoto();
                  },
                ),
                const SizedBox(height: 10),
                _ImageSourceTile(
                  icon: Icons.photo_library_rounded,
                  title: 'Galeriden seç',
                  subtitle: 'Bir veya birden fazla fotoğraf seç',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickMultiImages();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeImage(int index) {
    if (_saving) return;

    setState(() {
      _pickedFiles.removeAt(index);
    });
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  Future<void> _saveIlan() async {
    if (_saving) return;

    final bool valid = _formKey.currentState?.validate() ?? false;

    if (!valid) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _snack('İlan eklemek için giriş yapmalısın.');
      await _goLogin();
      return;
    }

    if (selectedAltKategori == null) {
      _snack('Alt kategori seçmelisin.');
      return;
    }

    if (selectedSehir == null) {
      _snack('Şehir seçmelisin.');
      return;
    }

    if (_pickedFiles.isEmpty) {
      _snack('En az 1 fotoğraf eklemelisin.');
      return;
    }

    final String title = _titleC.text.trim();
    final String desc = _descC.text.trim();
    final String phone = _normalizePhone(_phoneC.text.trim());

    setState(() {
      _saving = true;
    });

    try {
      final List<String> photoUrls =
      await _imageService.uploadMultiple(_pickedFiles);

      if (photoUrls.isEmpty) {
        throw Exception('Fotoğraflar yüklenemedi.');
      }

      final DatabaseReference ref = _dbRef.push();
      final int now = DateTime.now().millisecondsSinceEpoch;
      final String id = ref.key ?? '';

      if (id.isEmpty) {
        throw Exception('İlan kimliği oluşturulamadı.');
      }

      final IlanModel ilan = IlanModel(
        id: id,
        title: title,
        category: selectedAltKategori!,
        city: selectedSehir!,
        desc: desc,
        createdAt: now,
        photoUrls: photoUrls,
        ownerId: user.uid,
        status: 'active',
        tradeType: _tradeType,
      );

      final Map<String, dynamic> data =
      Map<String, dynamic>.from(ilan.toMap());

      data.addAll({
        'id': id,
        'ownerId': user.uid,
        'userId': user.uid,
        'createdBy': user.uid,
        'ownerEmail': user.email ?? '',
        'ownerName': user.displayName ?? '',
        'phone': phone,
        'telefon': phone,
        'createdAt': now,
        'updatedAt': now,
        'status': 'active',
        'mainCategory': selectedAnaKategori,
        'subCategory': selectedAltKategori,
        'tradeType': _tradeType,
      });

      await ref.set(data);

      if (!mounted) return;

      _snack('İlan başarıyla eklendi.');

      Navigator.pop(context);
    } catch (error) {
      _snack('İlan eklenemedi: $error');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _snack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: _primaryColor,
      ),
      filled: true,
      fillColor: _cardColor,
      labelStyle: const TextStyle(
        color: _mutedColor,
        fontWeight: FontWeight.w700,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA49D),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: _borderColor,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: _primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
    );
  }

  Widget _tradeTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.handshake_outlined,
                color: _primaryColor,
              ),
              SizedBox(width: 8),
              Text(
                'Paylaşım Türü',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TradeTypeCard(
                  icon: Icons.card_giftcard_rounded,
                  title: 'Ücretsiz',
                  subtitle: 'Karşılıksız paylaş',
                  selected: _tradeType == 'free',
                  onTap: _saving
                      ? null
                      : () {
                    setState(() {
                      _tradeType = 'free';
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TradeTypeCard(
                  icon: Icons.swap_horiz_rounded,
                  title: 'Takas',
                  subtitle: 'Başka ürünle değiştir',
                  selected: _tradeType == 'swap',
                  onTap: _saving
                      ? null
                      : () {
                    setState(() {
                      _tradeType = 'swap';
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.photo_camera_back_outlined,
                      color: _primaryColor,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Ürün Fotoğrafları',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${_pickedFiles.length}/$_maxImageCount',
                style: const TextStyle(
                  color: _mutedColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'İlk fotoğraf ilanın kapak fotoğrafı olarak gösterilir.',
            style: TextStyle(
              color: _mutedColor,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _saving ? null : _showImageSourceSheet,
              icon: const Icon(
                Icons.add_a_photo_rounded,
              ),
              label: const Text(
                'Kamera veya Galeriden Ekle',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: const BorderSide(
                  color: _primaryColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
          ),
          if (_pickedFiles.isNotEmpty) ...[
            const SizedBox(height: 15),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedFiles.length,
                separatorBuilder: (_, __) {
                  return const SizedBox(width: 10);
                },
                itemBuilder: (context, index) {
                  final File image = _pickedFiles[index];

                  return Stack(
                    children: [
                      Container(
                        width: 112,
                        height: 112,
                        decoration: BoxDecoration(
                          color: _primarySoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: index == 0
                                ? _primaryColor
                                : _borderColor,
                            width: index == 0 ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.file(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                color: _primaryColor,
                                size: 32,
                              ),
                            );
                          },
                        ),
                      ),
                      if (index == 0)
                        Positioned(
                          left: 5,
                          bottom: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Kapak',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            _removeImage(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> altKategoriler =
        kategoriMap[selectedAnaKategori] ?? const <String>[];

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Yeni İlan Oluştur',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            14,
            16,
            14,
            110,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: _primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _borderColor,
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.volunteer_activism_rounded,
                      color: _primaryColor,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ürününü doğru bilgiler ve net fotoğraflarla '
                            'paylaş. Böylece gerçekten ihtiyacı olan kişilere '
                            'daha kolay ulaşabilirsin.',
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 13.5,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _titleC,
                enabled: !_saving,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: _inputDecoration(
                  label: 'İlan Başlığı',
                  hint: 'Örnek: Temiz durumda çocuk yatağı',
                  icon: Icons.title_rounded,
                ),
                validator: (value) {
                  final String text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'İlan başlığı zorunludur.';
                  }

                  if (text.length < 3) {
                    return 'Başlık en az 3 karakter olmalıdır.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              _tradeTypeSelector(),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedAnaKategori,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Ana Kategori',
                  icon: Icons.category_outlined,
                ),
                items: kategoriMap.keys.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                  if (value == null) return;

                  setState(() {
                    selectedAnaKategori = value;
                    selectedAltKategori = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedAltKategori,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Alt Kategori',
                  icon: Icons.list_alt_rounded,
                ),
                items: altKategoriler.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                  setState(() {
                    selectedAltKategori = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alt kategori seçmelisin.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSehir,
                isExpanded: true,
                decoration: _inputDecoration(
                  label: 'Şehir',
                  icon: Icons.location_city_outlined,
                ),
                items: sehirler.map((city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
                  setState(() {
                    selectedSehir = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şehir seçmelisin.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneC,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 15,
                decoration: _inputDecoration(
                  label: 'Telefon Numarası',
                  hint: '05xx xxx xx xx',
                  icon: Icons.phone_outlined,
                ),
                validator: (value) {
                  final String phone =
                  _normalizePhone(value?.trim() ?? '');

                  if (phone.isEmpty) {
                    return 'Telefon numarası zorunludur.';
                  }

                  if (phone.length < 10 || phone.length > 11) {
                    return 'Geçerli bir telefon numarası gir.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descC,
                enabled: !_saving,
                minLines: 4,
                maxLines: 7,
                maxLength: 1000,
                decoration: _inputDecoration(
                  label: 'Açıklama',
                  hint:
                  'Ürünün durumu, ölçüsü, teslim şekli ve diğer bilgileri yaz.',
                  icon: Icons.description_outlined,
                ),
                validator: (value) {
                  final String text = value?.trim() ?? '';

                  if (text.isEmpty) {
                    return 'Açıklama zorunludur.';
                  }

                  if (text.length < 10) {
                    return 'Açıklama en az 10 karakter olmalıdır.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              _photoSection(),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveIlan,
                  icon: _saving
                      ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.publish_rounded,
                  ),
                  label: Text(
                    _saving ? 'İlan Yayınlanıyor...' : 'İlanı Yayınla',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    _primaryColor.withOpacity(0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
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

class _TradeTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const _TradeTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFFDDE6DC)
          : const Color(0xFFFFFCF4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFF5F7867)
                  : const Color(0xFFD5DDD2),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: const Color(0xFF5F7867),
                size: 29,
              ),
              const SizedBox(height: 7),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF26352C),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6D786F),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFDDE6DC),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: const BoxDecoration(
                  color: Color(0xFF5F7867),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF26352C),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6D786F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF5F7867),
              ),
            ],
          ),
        ),
      ),
    );
  }
}