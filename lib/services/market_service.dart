import '../models/market_item_model.dart';

class MarketService {
  static final List<MarketItemModel> dummy = [
    MarketItemModel(
      id: '1',
      title: 'Mavi Kadife Koltuk',
      price: 3500,
      imageUrl:
      'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=800',
      category: 'mobilya',
      tag: '1.el',
      brand: '—',
      createdAt: DateTime.now().millisecondsSinceEpoch - 10000,
    ),
    MarketItemModel(
      id: '2',
      title: 'Çocuk Yatak Seti',
      price: 2200,
      imageUrl:
      'https://images.unsplash.com/photo-1549497538-303791108f95?w=800',
      category: 'cocuk-odasi',
      tag: '2.el',
      brand: '—',
      createdAt: DateTime.now().millisecondsSinceEpoch - 20000,
    ),
    MarketItemModel(
      id: '3',
      title: 'Şarjlı Matkap Seti',
      price: 750,
      imageUrl:
      'https://images.unsplash.com/photo-1586864387967-d02ef85d93e8?w=800',
      category: 'hirdavat',
      tag: '1.el',
      brand: '—',
      createdAt: DateTime.now().millisecondsSinceEpoch - 30000,
    ),
    MarketItemModel(
      id: '4',
      title: 'Beyaz Gardırop',
      price: 1700,
      imageUrl:
      'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=800',
      category: 'mobilya',
      tag: '2.el',
      brand: '—',
      createdAt: DateTime.now().millisecondsSinceEpoch - 40000,
    ),
  ];

  Future<List<MarketItemModel>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return dummy;
  }
}