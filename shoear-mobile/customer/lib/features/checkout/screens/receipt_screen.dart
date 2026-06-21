import 'package:flutter/material.dart';

import 'package:customer/features/order/models/order.dart';

/// Order confirmation + receipt, shown after a successful payment.
class ReceiptScreen extends StatelessWidget {
  final Receipt receipt;
  const ReceiptScreen({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false, // it's a terminal screen — use the Done button, not back
      child: Scaffold(
        appBar: AppBar(title: const Text('Order confirmed'), automaticallyImplyLeading: false),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Center(child: Icon(Icons.check_circle, color: Colors.green.shade600, size: 72)),
            const SizedBox(height: 12),
            Center(
              child: Text('Payment successful', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 4),
            Center(child: Text('Order ${receipt.orderId}', style: TextStyle(color: Colors.grey.shade600))),
            const SizedBox(height: 24),

            _section(context, 'Items'),
            for (final it in receipt.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(it.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${it.brand} · Size ${it.size} · x${it.qty}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text('RM ${it.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total paid', style: theme.textTheme.titleMedium),
                Text('RM ${receipt.total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ],
            ),

            const SizedBox(height: 20),
            _section(context, 'Payment'),
            _kv('Method', receipt.paymentMethod ?? '—'),
            _kv('Reference', receipt.transactionId ?? '—'),
            if (receipt.paymentDate != null) _kv('Date', _fmt(receipt.paymentDate!)),

            const SizedBox(height: 20),
            _section(context, 'Delivery address'),
            Text(receipt.deliveryAddress),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Continue shopping')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v)),
          ],
        ),
      );

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
