import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/order_service.dart';
import '../state/cart_provider.dart';
import 'receipt_screen.dart';

/// Review the cart, confirm a delivery address, pick a (simulated) payment
/// method, then place + pay the order in one step.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressCtrl = TextEditingController();
  String _method = 'Stripe';
  bool _loadingAddr = true;
  bool _placing = false;
  String? _addrError;

  @override
  void initState() {
    super.initState();
    _prefillAddress();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _prefillAddress() async {
    try {
      final saved = await context.read<OrderService>().savedShippingAddress();
      if (mounted && saved != null && _addressCtrl.text.isEmpty) _addressCtrl.text = saved;
    } catch (_) {
      // non-fatal — they can just type the address
    } finally {
      if (mounted) setState(() => _loadingAddr = false);
    }
  }

  Future<void> _placeOrder() async {
    final address = _addressCtrl.text.trim();
    if (address.isEmpty) {
      setState(() => _addrError = 'A delivery address is required.');
      return;
    }
    setState(() {
      _addrError = null;
      _placing = true;
    });
    final orders = context.read<OrderService>();
    final cart = context.read<CartProvider>();
    try {
      final created = await orders.checkout(address);
      await orders.pay(created.orderId, _method);
      final receipt = await orders.getReceipt(created.orderId);
      await cart.refresh(); // cart was cleared server-side
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ReceiptScreen(receipt: receipt)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>().cart;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: (cart == null || cart.items.isEmpty)
          ? const Center(child: Text('Your cart is empty.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Order summary', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final it in cart.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('${it.productName}  ·  ${it.size}  ·  x${it.quantity}',
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text('RM ${it.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium),
                    Text('RM ${cart.total.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                  ],
                ),

                const SizedBox(height: 24),
                Text('Delivery address', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _loadingAddr
                    ? const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator())
                    : TextField(
                        controller: _addressCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Where should we deliver your order?',
                          border: const OutlineInputBorder(),
                          errorText: _addrError,
                        ),
                        onChanged: (_) {
                          if (_addrError != null) setState(() => _addrError = null);
                        },
                      ),

                const SizedBox(height: 24),
                Text('Payment method', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                RadioListTile<String>(
                  value: 'Stripe',
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('Card (Stripe)'),
                  secondary: const Icon(Icons.credit_card),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile<String>(
                  value: 'PayPal',
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text('PayPal'),
                  secondary: const Icon(Icons.account_balance_wallet),
                  contentPadding: EdgeInsets.zero,
                ),
                Text('Payment is simulated for this demo — no real charge is made.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
      bottomNavigationBar: (cart == null || cart.items.isEmpty)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _placing ? null : _placeOrder,
                  icon: _placing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock),
                  label: Text(_placing ? 'Processing…' : 'Place order · RM ${cart.total.toStringAsFixed(2)}'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ),
    );
  }
}
