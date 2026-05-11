import 'package:cloud_functions/cloud_functions.dart';

class PaymentService {
  PaymentService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Sepet toplamı kadar "güvenli ödeme linki" üretir
  /// return: { paymentLink, paymentRef }
  Future<({String paymentLink, String paymentRef})> createPaytrPaymentLink({
    required String buyerUid,
    required String buyerEmail,
    required int amountTry, // TL
    required String orderDraftId, // sipariş taslak id (biz üretiriz)
    required List<Map<String, dynamic>> items,
  }) async {
    final callable = _functions.httpsCallable('createPaytrPaymentLink');

    final res = await callable.call({
      'buyerUid': buyerUid,
      'buyerEmail': buyerEmail,
      'amountTry': amountTry,
      'orderDraftId': orderDraftId,
      'items': items,
    });

    final data = Map<String, dynamic>.from(res.data as Map);

    final link = (data['paymentLink'] ?? '').toString();
    final ref = (data['paymentRef'] ?? '').toString();

    if (link.isEmpty || ref.isEmpty) {
      throw Exception('Ödeme linki alınamadı.');
    }

    return (paymentLink: link, paymentRef: ref);
  }

  /// Ödeme tamamlandı mı? (backend doğrular)
  Future<bool> verifyPaytrPaid({required String paymentRef}) async {
    final callable = _functions.httpsCallable('verifyPaytrPaid');
    final res = await callable.call({'paymentRef': paymentRef});
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['paid'] == true;
  }
}