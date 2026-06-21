/// Result of POST /orders (checkout) — the order is created (Placed) and the
/// cart is cleared server-side; payment is the next step.
class CheckoutResult {
  final String orderId;
  final double total;
  final String deliveryAddress;
  final int itemCount;

  CheckoutResult({required this.orderId, required this.total, required this.deliveryAddress, required this.itemCount});

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
        orderId: j['orderId'] as String,
        total: (j['total'] as num?)?.toDouble() ?? 0,
        deliveryAddress: j['deliveryAddress'] as String? ?? '',
        itemCount: (j['itemCount'] as num?)?.toInt() ?? 0,
      );
}

/// One line on a receipt.
class ReceiptItem {
  final String productName;
  final String brand;
  final String size;
  final int qty;
  final double unitPrice;
  final double subtotal;

  ReceiptItem({required this.productName, required this.brand, required this.size, required this.qty, required this.unitPrice, required this.subtotal});

  factory ReceiptItem.fromJson(Map<String, dynamic> j) => ReceiptItem(
        productName: j['productName'] as String? ?? '',
        brand: j['brand'] as String? ?? '',
        size: j['size']?.toString() ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
        subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
      );
}

/// GET /orders/{id}/receipt — shown after a successful payment.
class Receipt {
  final String receiptId;
  final String orderId;
  final double total;
  final String deliveryAddress;
  final String? paymentMethod;
  final String? transactionId;
  final double? paymentAmount;
  final String? paymentDate;
  final List<ReceiptItem> items;

  Receipt({
    required this.receiptId,
    required this.orderId,
    required this.total,
    required this.deliveryAddress,
    this.paymentMethod,
    this.transactionId,
    this.paymentAmount,
    this.paymentDate,
    required this.items,
  });

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        receiptId: j['receiptId'] as String? ?? '',
        orderId: j['orderId'] as String? ?? '',
        total: (j['orderTotalAmount'] as num?)?.toDouble() ?? 0,
        deliveryAddress: j['orderDeliveryAddress'] as String? ?? '',
        paymentMethod: j['paymentMethod'] as String?,
        transactionId: j['transactionId'] as String?,
        paymentAmount: (j['paymentAmount'] as num?)?.toDouble(),
        paymentDate: j['paymentDate'] as String?,
        items: ((j['items'] as List?) ?? [])
            .map((e) => ReceiptItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
