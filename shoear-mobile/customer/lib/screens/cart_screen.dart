import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import 'catalog_screen.dart' show ProductImage;
import 'login_screen.dart';

/// The shopping cart: review items, change quantities, remove lines, see the
/// total. Checkout arrives in the next increment.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    // refresh on open if signed in (the cart is server-side, per customer)
    if (context.read<AuthProvider>().isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CartProvider>().refresh());
    }
  }

  // run a cart mutation, surfacing any error (e.g. out of stock) as a snackbar
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: !loggedIn ? _signInPrompt(context) : _cartBody(context),
    );
  }

  Widget _signInPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Sign in to use your cart.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );

  Widget _cartBody(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    if (cartProvider.loading && cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cartProvider.error != null && cart == null) {
      return _ErrorView(message: cartProvider.error!, onRetry: () => cartProvider.refresh());
    }
    if (cart == null || cart.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => cartProvider.refresh(),
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Center(child: Text('Your cart is empty.')),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cartProvider.refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _CartRow(
                item: cart.items[i],
                onDecrease: () => _run(() => cartProvider.updateQuantity(cart.items[i].cartItemId, cart.items[i].quantity - 1)),
                onIncrease: () => _run(() => cartProvider.updateQuantity(cart.items[i].cartItemId, cart.items[i].quantity + 1)),
                onRemove: () => _run(() => cartProvider.remove(cart.items[i].cartItemId)),
              ),
            ),
          ),
        ),
        _summaryBar(context, cart),
      ],
    );
  }

  Widget _summaryBar(BuildContext context, Cart cart) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  Text('RM ${cart.total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Checkout is coming in the next update.')),
              ),
              icon: const Icon(Icons.lock),
              label: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;
  const _CartRow({required this.item, required this.onDecrease, required this.onIncrease, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 64, height: 64, child: ProductImage(url: item.imageUrl)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.brand.toUpperCase(),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5)),
                Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Size ${item.size}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text('RM ${item.subtotal.toStringAsFixed(2)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                Row(
                  children: [
                    _StepperButton(icon: Icons.remove, onTap: item.quantity > 1 ? onDecrease : null),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    _StepperButton(icon: Icons.add, onTap: item.quantity < item.stock ? onIncrease : null),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.grey.shade600,
            onPressed: onRemove,
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade500),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: onTap == null ? Colors.grey.shade300 : Colors.grey.shade800),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
