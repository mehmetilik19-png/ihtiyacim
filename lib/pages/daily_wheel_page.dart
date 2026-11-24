import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:ihtiyacim/features/orders/order_model.dart';
import 'package:ihtiyacim/features/orders/order_repository.dart';

class DailyWheelTheme {
  static const Color bgTop = Color(0xFF0F4CFF);
  static const Color bgMid = Color(0xFF5F7CFF);
  static const Color bgBottom = Color(0xFFF3F7FF);
  static const Color text = Color(0xFF10132E);
  static const Color muted = Color(0xFF66708D);
  static const Color accent = Color(0xFF246BFF);
  static const Color accentDark = Color(0xFF6B45FF);
}

class DailyWheelMiniButton extends StatelessWidget {
  final VoidCallback onTap;

  const DailyWheelMiniButton({
    super.key,
    required this.onTap,
  });

  static const int _targetPoint = 20;

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: _pill(
          '🎡',
          '0/$_targetPoint',
          false,
        ),
      );
    }

    final ref = FirebaseDatabase.instance.ref(
      'cark_kullanicilari/${user.uid}',
    );

    return StreamBuilder<DatabaseEvent>(
      stream: ref.onValue,
      builder: (context, snapshot) {
        int puan = 0;
        bool hediyeHakki = false;
        bool bugunCevirdi = false;

        final value = snapshot.data?.snapshot.value;

        if (value is Map) {
          final data = Map<dynamic, dynamic>.from(value);

          puan = _intValue(data['puan']);
          hediyeHakki = data['hediyeHakki'] == true;
          bugunCevirdi =
              (data['sonCarkTarihi'] ?? '').toString() ==
                  _dateKey(DateTime.now());
        }

        final displayPuan = puan.clamp(0, _targetPoint);

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: _pill(
            hediyeHakki ? '🎁' : '🎡',
            hediyeHakki
                ? 'Hazır'
                : '$displayPuan/$_targetPoint',
            bugunCevirdi || hediyeHakki,
          ),
        );
      },
    );
  }

  Widget _pill(
      String icon,
      String text,
      bool active,
      ) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(
          active ? 0.96 : 0.82,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.90),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: DailyWheelTheme.accentDark,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class DailyWheelPage extends StatefulWidget {
  const DailyWheelPage({super.key});

  @override
  State<DailyWheelPage> createState() => _DailyWheelPageState();
}

class _DailyWheelPageState extends State<DailyWheelPage> {
  final math.Random _random = math.Random();

  bool _loading = true;
  bool _spinning = false;

  bool _adLoading = false;
  bool _rewardProcessing = false;

  int _adRetryCount = 0;
  int _puan = 0;
  int _reklamSayisi = 0;

  int? _sonKazanc;

  bool _bugunCevirdi = false;
  bool _hediyeHakki = false;

  double _turns = 0;

  RewardedAd? _rewardedAd;

  static const bool _testMode = false;
  static const bool _unlimitedSpinForTest = false;

  // true: Google test reklamı
  // false: gerçek AdMob reklamı
  static const bool _useTestAd = false;

  static const int _targetPoint = 20;
  static const int _requiredAds = 2;

  static const String _testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  static const String _realRewardedAdUnitId =
      'ca-app-pub-9918745845375809/3725697986';

  String get _rewardedAdUnitId {
    return _useTestAd
        ? _testRewardedAdUnitId
        : _realRewardedAdUnitId;
  }

  DatabaseReference? get _userRef {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return null;

    return FirebaseDatabase.instance.ref(
      'cark_kullanicilari/${user.uid}',
    );
  }

  @override
  void initState() {
    super.initState();

    _loadWheelData();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;

    super.dispose();
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  void _showMessage(String message) {
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

  void _loadRewardedAd() {
    if (!mounted) return;
    if (_adLoading) return;
    if (_rewardedAd != null) return;

    setState(() {
      _adLoading = true;
    });

    debugPrint(
      'Ödüllü reklam yükleniyor: $_rewardedAdUnitId',
    );

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }

          _rewardedAd?.dispose();
          _rewardedAd = ad;
          _adRetryCount = 0;

          debugPrint('========== ADMOB ==========');
          debugPrint('Ödüllü reklam başarıyla yüklendi.');
          debugPrint('ResponseInfo: ${ad.responseInfo}');
          debugPrint('===========================');

          setState(() {
            _adLoading = false;
          });
        },
        onAdFailedToLoad: (LoadAdError error) {
          _rewardedAd = null;

          debugPrint(
            '========== ADMOB YÜKLEME HATASI ==========',
          );
          debugPrint('Code: ${error.code}');
          debugPrint('Message: ${error.message}');
          debugPrint('Domain: ${error.domain}');
          debugPrint(
            'ResponseInfo: ${error.responseInfo}',
          );
          debugPrint(
            '==========================================',
          );

          if (!mounted) return;

          setState(() {
            _adLoading = false;
          });

          if (_adRetryCount < 3) {
            _adRetryCount++;

            final waitSeconds = _adRetryCount * 5;

            debugPrint(
              'Reklam $waitSeconds saniye sonra '
                  'yeniden yüklenecek.',
            );

            Future.delayed(
              Duration(seconds: waitSeconds),
                  () {
                if (!mounted) return;
                if (_rewardedAd != null) return;
                if (_adLoading) return;

                _loadRewardedAd();
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _loadWheelData() async {
    final ref = _userRef;

    if (ref == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }

      return;
    }

    try {
      final snapshot = await ref.get();

      int puan = 0;
      int reklamSayisi = 0;

      bool hediyeHakki = false;

      String sonCarkTarihi = '';
      String reklamTarihi = '';

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(
          snapshot.value as Map,
        );

        puan = _intValue(data['puan']);
        reklamSayisi = _intValue(
          data['reklamSayisi'],
        );

        hediyeHakki = data['hediyeHakki'] == true;

        sonCarkTarihi =
            (data['sonCarkTarihi'] ?? '').toString();

        reklamTarihi =
            (data['reklamTarihi'] ?? '').toString();
      }

      final today = _dateKey(DateTime.now());

      if (reklamTarihi != today) {
        reklamSayisi = 0;

        await ref.update({
          'reklamSayisi': 0,
          'reklamTarihi': today,
        });
      }

      if (!mounted) return;

      setState(() {
        _puan = puan;
        _reklamSayisi = reklamSayisi.clamp(
          0,
          _requiredAds,
        );
        _hediyeHakki = hediyeHakki;
        _bugunCevirdi = _unlimitedSpinForTest
            ? false
            : sonCarkTarihi == today;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Çark bilgisi alınamadı: $error',
      );
    }
  }

  Future<void> _increaseAdCountAfterReward() async {
    final ref = _userRef;

    if (ref == null) return;

    final today = _dateKey(DateTime.now());

    final yeniReklamSayisi =
    (_reklamSayisi + 1).clamp(
      0,
      _requiredAds,
    );

    await ref.update({
      'reklamSayisi': yeniReklamSayisi,
      'reklamTarihi': today,
      'guncellemeZamani': ServerValue.timestamp,
    });

    if (!mounted) return;

    setState(() {
      _reklamSayisi = yeniReklamSayisi;
    });

    if (yeniReklamSayisi >= _requiredAds) {
      _showMessage(
        '2 reklam tamamlandı. Çarkı çevirebilirsin 🎡',
      );
    } else {
      _showMessage(
        '1 reklam tamamlandı. '
            '1 reklam daha izlemen gerekiyor.',
      );
    }
  }

  Future<void> _watchAd() async {
    final ref = _userRef;

    if (ref == null) {
      _showMessage(
        'Reklam izlemek için giriş yapmalısın.',
      );
      return;
    }

    if (_rewardProcessing) {
      return;
    }

    if (_hediyeHakki) {
      _showMessage(
        'Önce hediyeni talep etmelisin.',
      );
      return;
    }

    if (!_unlimitedSpinForTest && _bugunCevirdi) {
      _showMessage(
        'Bugünkü çark hakkını kullandın.',
      );
      return;
    }

    if (_reklamSayisi >= _requiredAds) {
      _showMessage(
        'Çark hakkın hazır.',
      );
      return;
    }

    final RewardedAd? ad = _rewardedAd;

    if (ad == null) {
      if (!_adLoading) {
        _adRetryCount = 0;
        _loadRewardedAd();
      }

      _showMessage(
        _adLoading
            ? 'Reklam hazırlanıyor. Birkaç saniye bekle.'
            : 'Şu anda uygun reklam bulunamadı. '
            'Biraz sonra tekrar dene.',
      );

      return;
    }

    setState(() {
      _rewardedAd = null;
      _rewardProcessing = true;
    });

    bool rewardEarned = false;

    ad.fullScreenContentCallback =
        FullScreenContentCallback(
          onAdShowedFullScreenContent: (RewardedAd ad) {
            debugPrint('Ödüllü reklam gösterildi.');
          },
          onAdImpression: (RewardedAd ad) {
            debugPrint(
              'Ödüllü reklam gösterimi kaydedildi.',
            );
          },
          onAdClicked: (RewardedAd ad) {
            debugPrint('Ödüllü reklama tıklandı.');
          },
          onAdDismissedFullScreenContent: (
              RewardedAd ad,
              ) {
            debugPrint('Ödüllü reklam kapatıldı.');

            ad.dispose();

            if (mounted) {
              setState(() {
                _rewardProcessing = false;
              });
            }

            _adRetryCount = 0;
            _loadRewardedAd();

            if (!rewardEarned) {
              _showMessage(
                'Reklam tamamlanmadığı için hak sayılmadı.',
              );
            }
          },
          onAdFailedToShowFullScreenContent: (
              RewardedAd ad,
              AdError error,
              ) {
            debugPrint(
              '========== ADMOB GÖSTERME HATASI ==========',
            );
            debugPrint('Code: ${error.code}');
            debugPrint('Message: ${error.message}');
            debugPrint('Domain: ${error.domain}');
            debugPrint(
              '===========================================',
            );

            ad.dispose();

            if (mounted) {
              setState(() {
                _rewardProcessing = false;
              });
            }

            _showMessage(
              'Reklam gösterilemedi: ${error.message}',
            );

            _adRetryCount = 0;
            _loadRewardedAd();
          },
        );

    try {
      ad.show(
        onUserEarnedReward: (
            AdWithoutView ad,
            RewardItem reward,
            ) async {
          if (rewardEarned) return;

          rewardEarned = true;

          debugPrint(
            'Ödül kazanıldı: '
                '${reward.amount} ${reward.type}',
          );

          try {
            await _increaseAdCountAfterReward();
          } catch (error) {
            debugPrint(
              'Reklam hakkı kaydedilemedi: $error',
            );

            _showMessage(
              'Reklam izlendi fakat hak kaydedilemedi: '
                  '$error',
            );
          }
        },
      );
    } catch (error) {
      ad.dispose();

      if (mounted) {
        setState(() {
          _rewardProcessing = false;
        });
      }

      _showMessage(
        'Reklam açılırken hata oluştu: $error',
      );

      _adRetryCount = 0;
      _loadRewardedAd();
    }
  }

  Future<void> _spinWheel() async {
    final ref = _userRef;

    if (ref == null) {
      _showMessage(
        'Çark için giriş yapmalısın.',
      );
      return;
    }

    if (_hediyeHakki) {
      _showMessage(
        'Önce hediyeni talep etmelisin.',
      );
      return;
    }

    if (!_unlimitedSpinForTest && _bugunCevirdi) {
      _showMessage(
        'Bugünkü çark hakkını kullandın.',
      );
      return;
    }

    if (_reklamSayisi < _requiredAds) {
      _showMessage(
        'Çarkı çevirmek için 2 reklam izlemelisin.',
      );
      return;
    }

    const puanlar = <int>[2, 3, 4];

    final kazanilanPuan =
    puanlar[_random.nextInt(puanlar.length)];

    final hedefIndex = kazanilanPuan - 1;

    setState(() {
      _spinning = true;
      _sonKazanc = null;
      _turns += 5 + ((10 - hedefIndex) / 10);
    });

    await Future.delayed(
      const Duration(milliseconds: 2300),
    );

    final yeniPuan = _puan + kazanilanPuan;
    final hediyeHakki =
        yeniPuan >= _targetPoint;

    final today = _dateKey(DateTime.now());
    final user = FirebaseAuth.instance.currentUser;

    try {
      await ref.update({
        'uid': user?.uid ?? '',
        'email': user?.email ?? '',
        'ad': user?.displayName ?? '',
        'puan': hediyeHakki
            ? _targetPoint
            : yeniPuan,
        'sonKazanc': kazanilanPuan,
        'sonCarkTarihi': today,
        'hediyeHakki': hediyeHakki,
        'guncellemeZamani': ServerValue.timestamp,
        'reklamSayisi': 0,
        'reklamTarihi': today,
      });

      if (!mounted) return;

      setState(() {
        _sonKazanc = kazanilanPuan;
        _puan = hediyeHakki
            ? _targetPoint
            : yeniPuan;
        _hediyeHakki = hediyeHakki;
        _bugunCevirdi =
        _unlimitedSpinForTest ? false : true;
        _reklamSayisi = 0;
        _spinning = false;
      });

      if (hediyeHakki) {
        await _showGiftWinDialog();
      } else {
        await _showPointDialog(
          kazanilanPuan,
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _spinning = false;
      });

      _showMessage(
        'Çark kaydedilemedi: $error',
      );
    }
  }

  Future<void> _showPointDialog(
      int point,
      ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '🎉 Tebrikler!',
          ),
          content: Text(
            '+$point puan kazandın.\n\n'
                'Toplam puanın: $_puan / $_targetPoint',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showGiftWinDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text(
            '🎊 Sürpriz Hediye Kazandın!',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _ConfettiLine(),
              const SizedBox(height: 12),
              const Text(
                '20 puana ulaştın.\n'
                    'Hediyeni talep etmek için formu '
                    'doldurabilirsin.\n\n'
                    'Hediye içeriği sürprizdir.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _testMode
                    ? 'Test modu açık: '
                    'günlük sınır kapalı.'
                    : '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: DailyWheelTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Sonra'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openGiftForm();
              },
              icon: const Icon(
                Icons.card_giftcard_rounded,
              ),
              label: const Text(
                'Hediyemi Talep Et',
              ),
            ),
          ],
        );
      },
    );
  }

  void _openGiftForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return const GiftRequestPage();
        },
      ),
    ).then((_) {
      _loadWheelData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayPuan = _puan.clamp(
      0,
      _targetPoint,
    );

    final buttonDisabled =
        _spinning ||
            _rewardProcessing ||
            (_adLoading &&
                _reklamSayisi < _requiredAds &&
                !_hediyeHakki);

    return Scaffold(
      backgroundColor: DailyWheelTheme.bgBottom,
      appBar: AppBar(
        title: const Text(
          'Günlük Şans Çarkı',
        ),
        backgroundColor: DailyWheelTheme.accent,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DailyWheelTheme.bgTop,
              DailyWheelTheme.bgMid,
              DailyWheelTheme.bgBottom,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _InfoBox(
              testMode: _testMode,
              useTestAd: _useTestAd,
              unlimitedSpinForTest:
              _unlimitedSpinForTest,
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(
                  0.96,
                ),
                borderRadius:
                BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                    color: Colors.black.withOpacity(
                      0.12,
                    ),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 285,
                    height: 310,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Positioned(
                          top: 0,
                          child: _WheelPointer(),
                        ),
                        Positioned(
                          top: 38,
                          child: AnimatedRotation(
                            turns: _turns,
                            duration: const Duration(
                              milliseconds: 2300,
                            ),
                            curve: Curves.easeOutCubic,
                            child:
                            const _PointWheel(),
                          ),
                        ),
                        Positioned(
                          top: 135,
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(
                                  0xFFFF3D8B,
                                ),
                                width: 5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 18,
                                  offset:
                                  const Offset(
                                    0,
                                    8,
                                  ),
                                  color: Colors.black
                                      .withOpacity(
                                    0.16,
                                  ),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🎡',
                                style: TextStyle(
                                  fontSize: 38,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hediyeHakki
                        ? '🎁 Sürpriz Hediyen Hazır!'
                        : _reklamSayisi <
                        _requiredAds
                        ? 'Çark için 2 reklam izle'
                        : 'Çark hakkın hazır',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color:
                      DailyWheelTheme.text,
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_sonKazanc != null)
                    Text(
                      '+$_sonKazanc puan kazandın',
                      textAlign:
                      TextAlign.center,
                      style: const TextStyle(
                        color: Color(
                          0xFFFF3D8B,
                        ),
                        fontSize: 18,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    )
                  else
                    Text(
                      _reklamSayisi <
                          _requiredAds &&
                          !_hediyeHakki
                          ? 'Reklam durumu: '
                          '$_reklamSayisi/'
                          '$_requiredAds'
                          : 'Çark durduğunda ok '
                          'hangi puanı gösterirse '
                          'o puanı kazanırsın.',
                      textAlign:
                      TextAlign.center,
                      style: const TextStyle(
                        color:
                        DailyWheelTheme.muted,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius:
                          BorderRadius.circular(
                            999,
                          ),
                          child:
                          LinearProgressIndicator(
                            value: displayPuan /
                                _targetPoint,
                            minHeight: 12,
                            backgroundColor:
                            const Color(
                              0xFFE7ECFF,
                            ),
                            valueColor:
                            const AlwaysStoppedAnimation<
                                Color>(
                              Color(0xFFFF3D8B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$displayPuan/'
                            '$_targetPoint',
                        style: const TextStyle(
                          color: DailyWheelTheme
                              .accentDark,
                          fontWeight:
                          FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed:
                      buttonDisabled
                          ? null
                          : _hediyeHakki
                          ? _openGiftForm
                          : _reklamSayisi <
                          _requiredAds
                          ? _watchAd
                          : _spinWheel,
                      icon: _rewardProcessing
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                          : Icon(
                        _hediyeHakki
                            ? Icons
                            .card_giftcard_rounded
                            : _reklamSayisi <
                            _requiredAds
                            ? Icons
                            .ondemand_video_rounded
                            : Icons
                            .play_arrow_rounded,
                      ),
                      label: Text(
                        _spinning
                            ? 'Çark Dönüyor...'
                            : _rewardProcessing
                            ? 'Reklam Açılıyor...'
                            : _adLoading &&
                            _reklamSayisi <
                                _requiredAds
                            ? 'Reklam Hazırlanıyor...'
                            : _hediyeHakki
                            ? 'Hediyemi Talep Et'
                            : _reklamSayisi <
                            _requiredAds
                            ? 'Reklam İzle '
                            '$_reklamSayisi/'
                            '$_requiredAds'
                            : 'Çarkı Çevir',
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(
                          0xFFFF3D8B,
                        ),
                        foregroundColor:
                        Colors.white,
                        disabledBackgroundColor:
                        const Color(
                          0xFFFF3D8B,
                        ).withOpacity(0.45),
                        disabledForegroundColor:
                        Colors.white,
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final bool testMode;
  final bool useTestAd;
  final bool unlimitedSpinForTest;

  const _InfoBox({
    required this.testMode,
    required this.useTestAd,
    required this.unlimitedSpinForTest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        testMode
            ? '🎡 TEST MODU AÇIK.\n\n'
            'Günlük sınır: '
            '${unlimitedSpinForTest ? 'kapalı' : 'açık'}.\n'
            'Reklam tipi: '
            '${useTestAd ? 'Google test reklamı' : 'Gerçek AdMob reklamı'}.\n\n'
            'Reklam gerçekten tamamlanmadan '
            '1/2 sayılmaz.'
            : '🎡 Her gün 1 kez çark çevirebilirsin.\n\n'
            'Çarkı çevirmek için önce 2 reklam '
            'izlemelisin.\n\n'
            '20 puana ulaşınca sürpriz hediye '
            'talep etme hakkı kazanırsın.\n\n'
            'Hediye içeriği sürprizdir.',
        style: const TextStyle(
          color: DailyWheelTheme.text,
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _WheelPointer extends StatelessWidget {
  const _WheelPointer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'DURDUĞU YER',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        CustomPaint(
          size: const Size(42, 42),
          painter: _TrianglePainter(),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint = Paint()
      ..color = const Color(0xFFFF2D55);

    final path = Path()
      ..moveTo(
        size.width / 2,
        size.height,
      )
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawShadow(
      path,
      Colors.black.withOpacity(0.35),
      5,
      true,
    );

    canvas.drawPath(
      path,
      paint,
    );
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

class _PointWheel extends StatelessWidget {
  const _PointWheel();

  static const List<Color> _colors = [
    Color(0xFFFF7A00),
    Color(0xFFFFC400),
    Color(0xFF19C95C),
    Color(0xFF18C7D8),
    Color(0xFF246BFF),
    Color(0xFF7A4DFF),
    Color(0xFFFF4F9A),
    Color(0xFFFF3125),
    Color(0xFF12BFAF),
    Color(0xFFFF8A00),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(230, 230),
      painter: _WheelPainter(
        colors: _colors,
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Color> colors;

  const _WheelPainter({
    required this.colors,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final sweep = 2 * math.pi / 10;
    final startOffset =
        -math.pi / 2 - sweep / 2;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    for (int index = 0; index < 10; index++) {
      final paint = Paint()
        ..color = colors[index % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startOffset + index * sweep,
        sweep,
        true,
        paint,
      );

      final textAngle =
          startOffset +
              index * sweep +
              sweep / 2;

      final textOffset = Offset(
        center.dx +
            math.cos(textAngle) *
                radius *
                0.68,
        center.dy +
            math.sin(textAngle) *
                radius *
                0.68,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${index + 1}\nPUAN',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      canvas.save();
      canvas.translate(
        textOffset.dx,
        textOffset.dy,
      );
      canvas.rotate(
        textAngle + math.pi / 2,
      );

      textPainter.paint(
        canvas,
        Offset(
          -textPainter.width / 2,
          -textPainter.height / 2,
        ),
      );

      canvas.restore();
    }

    canvas.drawCircle(
      center,
      radius - 4,
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(
      covariant _WheelPainter oldDelegate,
      ) {
    return false;
  }
}

class _ConfettiLine extends StatelessWidget {
  const _ConfettiLine();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Text(
          '🎊',
          style: TextStyle(fontSize: 28),
        ),
        Text(
          '🎉',
          style: TextStyle(fontSize: 28),
        ),
        Text(
          '🎁',
          style: TextStyle(fontSize: 28),
        ),
        Text(
          '🎉',
          style: TextStyle(fontSize: 28),
        ),
        Text(
          '🎊',
          style: TextStyle(fontSize: 28),
        ),
      ],
    );
  }
}

class GiftRequestPage extends StatefulWidget {
  const GiftRequestPage({super.key});

  @override
  State<GiftRequestPage> createState() =>
      _GiftRequestPageState();
}

class _GiftRequestPageState
    extends State<GiftRequestPage> {
  final TextEditingController _adSoyadC =
  TextEditingController();

  final TextEditingController _telefonC =
  TextEditingController();

  final TextEditingController _ilC =
  TextEditingController();

  final TextEditingController _ilceC =
  TextEditingController();

  final TextEditingController _adresC =
  TextEditingController();

  final OrderRepository _orderRepo =
  OrderRepository();

  bool _sending = false;

  static const int _targetPoint = 20;

  @override
  void dispose() {
    _adSoyadC.dispose();
    _telefonC.dispose();
    _ilC.dispose();
    _ilceC.dispose();
    _adresC.dispose();

    super.dispose();
  }

  Future<void> _sendRequest() async {
    final adSoyad = _adSoyadC.text.trim();
    final telefon = _telefonC.text.trim();
    final il = _ilC.text.trim();
    final ilce = _ilceC.text.trim();
    final adres = _adresC.text.trim();

    if (adSoyad.isEmpty ||
        telefon.isEmpty ||
        il.isEmpty ||
        ilce.isEmpty ||
        adres.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lütfen tüm alanları doldurun',
          ),
        ),
      );
      return;
    }

    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hediye talebi için giriş yapmanız gerekiyor',
          ),
        ),
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final userRef =
      FirebaseDatabase.instance.ref(
        'cark_kullanicilari/${user.uid}',
      );

      final userSnapshot =
      await userRef.get();

      bool hediyeHakki = false;

      if (userSnapshot.exists &&
          userSnapshot.value is Map) {
        final data =
        Map<dynamic, dynamic>.from(
          userSnapshot.value as Map,
        );

        final puan = data['puan'];

        hediyeHakki =
            data['hediyeHakki'] == true ||
                (puan is num &&
                    puan.toInt() >=
                        _targetPoint);
      }

      if (!hediyeHakki) {
        if (!mounted) return;

        setState(() {
          _sending = false;
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Henüz hediye hakkınız oluşmamış',
            ),
          ),
        );

        return;
      }

      final talepRef =
      FirebaseDatabase.instance
          .ref('hediye_talepleri')
          .push();

      await talepRef.set({
        'talepId': talepRef.key,
        'uid': user.uid,
        'email': user.email ?? '',
        'adSoyad': adSoyad,
        'telefon': telefon,
        'il': il,
        'ilce': ilce,
        'adres': adres,
        'puan': _targetPoint,
        'durum': 'Bekliyor',
        'tarih': ServerValue.timestamp,
      });

      final orderId =
      await _orderRepo.createOrder(
        buyerId: user.uid,
        buyerEmail: user.email ?? '',
        grandTotal: 0,
        address: ShippingAddress(
          name: adSoyad,
          phone: telefon,
          line1: adres,
          city: il,
          district: ilce,
        ),
        items: const [
          OrderItem(
            productId: 'hediye_carki',
            title:
            '🎁 Sürpriz Çark Hediyesi',
            price: 0,
            qty: 1,
          ),
        ],
      );

      await userRef.update({
        'puan': 0,
        'hediyeHakki': false,
        'sonHediyeTalepId':
        talepRef.key,
        'sonHediyeSiparisId': orderId,
        'sonHediyeTalepZamani':
        ServerValue.timestamp,
      });

      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(22),
            ),
            title: const Text(
              'Talebin Alındı 🎁',
            ),
            content: const Text(
              'Sürpriz hediye talebin bize ulaştı. '
                  'Siparişlerim ve admin siparişler '
                  'bölümüne eklendi.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  Navigator.pop(context);
                },
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Talep gönderilemedi: $error',
          ),
        ),
      );
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius:
            BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      DailyWheelTheme.bgBottom,
      appBar: AppBar(
        title: const Text(
          'Hediye Talep Formu',
        ),
        backgroundColor:
        DailyWheelTheme.accent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF7A00),
                  Color(0xFFFF3D8B),
                  Color(0xFF7A4DFF),
                ],
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Sürpriz hediyeni gönderebilmemiz '
                        'için adres bilgilerini doldur.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight:
                      FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _field(
            controller: _adSoyadC,
            hint: 'Ad Soyad',
            icon:
            Icons.person_outline_rounded,
          ),
          _field(
            controller: _telefonC,
            hint: 'Telefon Numarası',
            icon: Icons.phone_outlined,
            keyboardType:
            TextInputType.phone,
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _ilC,
                  hint: 'İl',
                  icon: Icons
                      .location_city_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller: _ilceC,
                  hint: 'İlçe',
                  icon: Icons.map_outlined,
                ),
              ),
            ],
          ),
          _field(
            controller: _adresC,
            hint: 'Açık Adres',
            icon: Icons.home_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed:
              _sending ? null : _sendRequest,
              icon: _sending
                  ? const SizedBox(
                width: 18,
                height: 18,
                child:
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(
                Icons.send_rounded,
              ),
              label: Text(
                _sending
                    ? 'Gönderiliyor...'
                    : 'Talebi Gönder',
                style: const TextStyle(
                  fontWeight:
                  FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                DailyWheelTheme.accent,
                foregroundColor:
                Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}