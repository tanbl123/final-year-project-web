import 'package:flutter/material.dart';

import 'package:customer/features/order/models/order.dart';
import 'package:customer/features/order/screens/order_detail_screen.dart';
import 'package:customer/features/order/services/receipt_pdf.dart';
import 'package:customer/features/shell/main_shell.dart';

/// Order confirmation + receipt. Shown once after a successful payment
/// (`confirmation: true`, the terminal success screen) and also re-openable
/// later from the order detail as a plain receipt (`confirmation: false`).
class ReceiptScreen extends StatelessWidget {
  final Receipt receipt;
  final bool confirmation; // true = post-payment success; false = re-viewing
  const ReceiptScreen({super.key, required this.receipt, this.confirmation = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final itemCount = receipt.items.fold<int>(0, (s, i) => s + i.qty);

    final scaffold = Scaffold(
      backgroundColor: Colors.grey.shade100,
      // Re-view mode gets a normal app bar + back button; the success screen is
      // chromeless and exits via its action buttons instead.
      appBar: confirmation
          ? null
          : AppBar(title: Text('Receipt · ${receipt.orderId}'), backgroundColor: Colors.white, elevation: 0),
      body: SafeArea(
        top: !confirmation ? false : true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            // ── Header ─────────────────────────────────────────────────
            if (confirmation) ...[
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_rounded,
                      color: Colors.green.shade600, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text('Payment successful',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Thank you! Weʼve received your order and itʼs being prepared.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
              const SizedBox(height: 12),
              // Order id pill
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Order ${receipt.orderId}',
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Re-view: a small "Paid" badge instead of the big success hero.
              Row(
                children: [
                  Icon(Icons.verified_outlined, size: 18, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text('Paid',
                      style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 16),
            ],

              // ── Items ──────────────────────────────────────────────────
              _Card(
                icon: Icons.shopping_bag_outlined,
                title: 'Order Summary ($itemCount item${itemCount == 1 ? '' : 's'})',
                child: Column(
                  children: [
                    for (int i = 0; i < receipt.items.length; i++) ...[
                      if (i > 0) const Divider(height: 18),
                      _ItemRow(item: receipt.items[i], primary: primary),
                    ],
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total paid',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('RM ${receipt.total.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: primary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Sold by / Billed to ────────────────────────────────────
              if (receipt.sellers.isNotEmpty || (receipt.customerName ?? '').isNotEmpty) ...[
                _Card(
                  icon: Icons.storefront_outlined,
                  title: 'Details',
                  child: Column(
                    children: [
                      if (receipt.sellers.isNotEmpty) _kv('Sold by', receipt.sellers.join(', ')),
                      if ((receipt.customerName ?? '').isNotEmpty) _kv('Billed to', receipt.customerName!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // ── Payment ────────────────────────────────────────────────
              _Card(
                icon: Icons.payment_outlined,
                title: 'Payment',
                child: Column(
                  children: [
                    _kv('Method', receipt.paymentMethod ?? '—'),
                    _kv('Reference', receipt.transactionId ?? '—', mono: true),
                    if (receipt.paymentDate != null)
                      _kv('Date', _fmt(receipt.paymentDate!)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Delivery address ───────────────────────────────────────
              _Card(
                icon: Icons.location_on_outlined,
                title: 'Delivery Address',
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(receipt.deliveryAddress,
                      style: const TextStyle(height: 1.4)),
                ),
              ),
              const SizedBox(height: 12),

              // ── Track hint ─────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 18, color: primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Track your order anytime under My Orders.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Save / share / print this receipt — the OS sheet covers saving
              // to Files, emailing it, and printing, all from one button.
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    await shareReceiptPdf(receipt);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..removeCurrentSnackBar()
                        ..showSnackBar(const SnackBar(content: Text('Could not generate the receipt.')));
                    }
                  }
                },
                icon: const Icon(Icons.ios_share),
                label: const Text('Download / Share receipt'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Need help? $kShoearSupportEmail · $kShoearWebsite',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),

        // ── Actions (success screen only; re-view exits via the app bar) ──
        bottomNavigationBar: !confirmation ? null : SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // Land on the Orders tab, then open this order's detail.
                    final nav = Navigator.of(context);
                    mainShellTab.value = MainTab.orders;
                    nav.popUntil((route) => route.isFirst);
                    nav.push(MaterialPageRoute(
                        builder: (_) =>
                            OrderDetailScreen(orderId: receipt.orderId)));
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('View order'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    // Back to Home so the customer can keep shopping (not the
                    // now-empty Cart tab they came from).
                    mainShellTab.value = MainTab.home;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Continue shopping',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
    );

    // The success screen blocks the back gesture (use its buttons); the
    // re-view receipt behaves like any normal pushed screen.
    return confirmation ? PopScope(canPop: false, child: scaffold) : scaffold;
  }

  Widget _kv(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: 90,
                child: Text(k,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
            Expanded(
              child: Text(v,
                  style: TextStyle(
                      fontSize: mono ? 12 : 13,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

  String _fmt(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · $h:$mm $ampm';
  }
}

// ── White section card ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;
  const _Card({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

// ── One receipt item row ────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final ReceiptItem item;
  final Color primary;
  const _ItemRow({required this.item, required this.primary});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.inventory_2_outlined,
              size: 22, color: Colors.grey.shade500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.brand.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      color: primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8)),
              Text(item.productName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              Text('Size ${item.size} · Qty ${item.qty}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('RM ${item.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
