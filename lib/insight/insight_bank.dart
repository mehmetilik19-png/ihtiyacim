import 'insight_context.dart';

class InsightBank {
  static const Map<InsightContext, List<String>> pool = {
    InsightContext.business: [
      'İnsanların sizi neden tercih ettiği buradan bile anlaşılıyor.',
      'Bu gerçekten iyi bir işletmecilik.',
      'Burada ciddi bir zevk ve bilinç var.',
      'Bu düzen tesadüf değil.',
      'İşini bilen bir el izi var.',
    ],
    InsightContext.homeOffice: [
      'Detaylara bakışın çok temiz.',
      'Sade ama akıllı seçimler var.',
      'Burada özenli bir düzen hissi var.',
      'İşlevi düşünmen çok yerinde.',
    ],
    InsightContext.fashion: [
      'Bunda güzel olan şey sadece parça değil, duruşun.',
      'Aslında zaten iyi taşıyorsun.',
      'Değiştirmemek de bazen en doğru seçim.',
      'Bu seçim seni yormuyor.',
    ],
    InsightContext.beautyHair: [
      'Burada en güçlü şey doğallık.',
      'Küçük dokunuşlarla çok iyi sonuç alıyorsun.',
      'Denge sende daha iyi duruyor.',
      'Abartı değil, uyum.',
    ],
    InsightContext.general: [
      'Bunu söylemeden geçemedim.',
      'Görmemek olmazdı.',
      'Burada “tamam” dedirten bir şey var.',
    ],
  };
}
