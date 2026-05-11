import 'package:ihtiyacim/models/market_listing_model.dart';

class CartLine {
  final MarketListingModel item;
  int qty;
  CartLine({required this.item, required this.qty});
}

class MarketCart {
  static final List<CartLine> lines = [];

  static void add(MarketListingModel item, {int qty = 1}) {
    final i = lines.indexWhere((x) => x.item.id == item.id);
    if (i >= 0) {
      lines[i].qty += qty;
    } else {
      lines.add(CartLine(item: item, qty: qty));
    }
  }

  static void setQty(String itemId, int qty) {
    final i = lines.indexWhere((x) => x.item.id == itemId);
    if (i < 0) return;

    if (qty <= 0) {
      lines.removeAt(i);
    } else {
      lines[i].qty = qty;
    }
  }

  static void remove(String itemId) {
    lines.removeWhere((x) => x.item.id == itemId);
  }

  static void clear() {
    lines.clear();
  }

  static int get totalTl {
    var s = 0;
    for (final l in lines) {
      s += (l.item.price * l.qty);
    }
    return s;
  }

  static List<Map<String, dynamic>> toJsonItems() {
    return lines
        .map((l) => {
      'id': l.item.id,
      'title': l.item.title,
      'price': l.item.price,
      'qty': l.qty,
    })
        .toList();
  }
}