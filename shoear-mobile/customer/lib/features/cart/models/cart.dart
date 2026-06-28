/// One line in the shopping cart (GET /cart → items[]).
class CartItem {
  final String cartItemId;
  final String variantId;
  final String productId;
  final String productName;
  final String brand;
  final String supplierId;
  final String supplierName;
  final String? imageUrl;
  final String size;
  final double unitPrice;
  final int quantity;
  final int stock;
  final double subtotal;

  CartItem({
    required this.cartItemId,
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.brand,
    this.supplierId = '',
    this.supplierName = '',
    this.imageUrl,
    required this.size,
    required this.unitPrice,
    required this.quantity,
    required this.stock,
    required this.subtotal,
  });

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        cartItemId: j['cartItemId'] as String,
        variantId: j['variantId'] as String? ?? '',
        productId: j['productId'] as String? ?? '',
        productName: j['productName'] as String? ?? '',
        brand: j['brand'] as String? ?? '',
        supplierId: j['supplierId'] as String? ?? '',
        supplierName: j['supplierName'] as String? ?? '',
        imageUrl: (j['imageUrl'] as String?)?.isNotEmpty == true ? j['imageUrl'] as String : null,
        size: j['size']?.toString() ?? '',
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        stock: (j['stock'] as num?)?.toInt() ?? 0,
        subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
      );
}

/// The whole cart (GET /cart).
class Cart {
  final String cartId;
  final List<CartItem> items;
  final int itemCount;
  final double total;

  Cart({required this.cartId, required this.items, required this.itemCount, required this.total});

  factory Cart.fromJson(Map<String, dynamic> j) => Cart(
        cartId: j['cartId'] as String? ?? '',
        items: ((j['items'] as List?) ?? [])
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        itemCount: (j['itemCount'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}
