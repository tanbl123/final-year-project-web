import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer/features/cart/models/cart.dart';
import 'package:customer/features/auth/state/auth_provider.dart';
import 'package:customer/features/cart/state/cart_provider.dart';
import 'package:customer/core/widgets/product_image.dart';
import 'package:customer/core/utils/snackbar.dart';
import 'package:customer/features/checkout/screens/checkout_screen.dart';
import 'package:customer/core/widgets/sign_in_prompt.dart';
import 'package:customer/features/catalog/screens/product_detail_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Selected cart-item ids (Shopee-style partial checkout). null = "not yet
  // touched" → treated as everything selected. We intersect with the live cart
  // so removed items drop out automatically.
  Set<String>? _selected;

  @override
  void initState() {
    super.initState();
    if (context.read<AuthProvider>().isLoggedIn) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.read<CartProvider>().refresh());
    }
  }

  // The effective selection given the current cart (defaults to all).
  Set<String> _effectiveSelection(Cart cart) {
    final ids = cart.items.map((i) => i.cartItemId).toSet();
    if (_selected == null) return ids;
    return _selected!.intersection(ids);
  }

  void _toggleItem(Cart cart, String id) {
    final sel = {..._effectiveSelection(cart)};
    sel.contains(id) ? sel.remove(id) : sel.add(id);
    setState(() => _selected = sel);
  }

  void _toggleGroup(Cart cart, List<CartItem> group, bool selectAll) {
    final sel = {..._effectiveSelection(cart)};
    for (final it in group) {
      selectAll ? sel.add(it.cartItemId) : sel.remove(it.cartItemId);
    }
    setState(() => _selected = sel);
  }

  void _toggleAll(Cart cart, bool selectAll) {
    setState(() => _selected = selectAll ? cart.items.map((i) => i.cartItemId).toSet() : <String>{});
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    }
  }

  Future<bool> _confirmRemove(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Remove item?'),
            content: const Text('Remove this item from your cart?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final cartProvider = context.watch<CartProvider>();
    final itemCount = cartProvider.cart?.items.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(itemCount > 0 ? 'Your Cart ($itemCount)' : 'Your Cart'),
        actions: [
          if (loggedIn && itemCount > 0)
            TextButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear cart?'),
                    content: const Text('Remove all items from your cart?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      FilledButton(
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  final cart = context.read<CartProvider>().cart;
                  if (cart == null) return;
                  for (final item in cart.items) {
                    await _run(
                        () => context.read<CartProvider>().remove(item.cartItemId));
                  }
                }
              },
              child: const Text('Clear all'),
            ),
        ],
      ),
      body: !loggedIn ? _signInPrompt(context) : _cartBody(context),
    );
  }

  Widget _signInPrompt(BuildContext context) => const SignInPrompt(
        icon: Icons.shopping_cart_outlined,
        title: 'Sign in to view your cart',
        subtitle: 'Items you add will be saved here',
      );

  Widget _cartBody(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final cart = cartProvider.cart;

    if (cartProvider.loading && cart == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (cartProvider.error != null && cart == null) {
      return _ErrorView(
          message: cartProvider.error!, onRetry: () => cartProvider.refresh());
    }
    if (cart == null || cart.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => cartProvider.refresh(),
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Center(
              child: Text('Your cart is empty',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text('Add items from the store to get started',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            ),
          ],
        ),
      );
    }

    // group items by seller (Shopee/Lazada multi-seller cart)
    final groups = <String, List<CartItem>>{};
    final names = <String, String>{};
    for (final it in cart.items) {
      groups.putIfAbsent(it.supplierId, () => []).add(it);
      names[it.supplierId] = it.supplierName.isEmpty ? 'Seller' : it.supplierName;
    }
    final selected = _effectiveSelection(cart);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => cartProvider.refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              children: [
                for (final entry in groups.entries) ...[
                  _SellerHeader(
                    name: names[entry.key]!,
                    allSelected: entry.value.every((i) => selected.contains(i.cartItemId)),
                    onToggle: (v) => _toggleGroup(cart, entry.value, v),
                  ),
                  for (final item in entry.value)
                    _CartCard(
                      item: item,
                      selected: selected.contains(item.cartItemId),
                      onToggleSelect: () => _toggleItem(cart, item.cartItemId),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: item.productId)),
                      ),
                      onDecrease: () => _run(() => cartProvider.updateQuantity(
                          item.cartItemId, item.quantity - 1)),
                      onIncrease: () => _run(() => cartProvider.updateQuantity(
                          item.cartItemId, item.quantity + 1)),
                      onRemove: () async {
                        final ok = await _confirmRemove(context);
                        if (ok) _run(() => cartProvider.remove(item.cartItemId));
                      },
                    ),
                ],
              ],
            ),
          ),
        ),
        _summaryBar(context, cart, selected),
      ],
    );
  }

  Widget _summaryBar(BuildContext context, Cart cart, Set<String> selected) {
    final theme = Theme.of(context);
    final chosen = cart.items.where((i) => selected.contains(i.cartItemId)).toList();
    final selectedUnits = chosen.fold<int>(0, (s, i) => s + i.quantity);
    final selectedTotal = chosen.fold<double>(0, (s, i) => s + i.subtotal);
    final allSelected = chosen.length == cart.items.length && cart.items.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 20, 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, -3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Select-all + selected total ────────────────────────────────
            Row(
              children: [
                Checkbox(
                  value: allSelected,
                  onChanged: (v) => _toggleAll(cart, v ?? false),
                  visualDensity: VisualDensity.compact,
                ),
                Text('All', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const Spacer(),
                Text('Selected ($selectedUnits): ',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                Text('RM ${selectedTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            // ── Checkout (selected only) ───────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: chosen.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CheckoutScreen(
                              selectedCartItemIds: chosen.map((i) => i.cartItemId).toList(),
                            ),
                          ),
                        ),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: Text(chosen.isEmpty
                    ? 'Select items to checkout'
                    : 'Checkout (${chosen.length})  ·  RM ${selectedTotal.toStringAsFixed(2)}'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Seller group header with a select-all-for-this-seller checkbox.
class _SellerHeader extends StatelessWidget {
  final String name;
  final bool allSelected;
  final ValueChanged<bool> onToggle;
  const _SellerHeader({required this.name, required this.allSelected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Checkbox(
              value: allSelected,
              onChanged: (v) => onToggle(v ?? false),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.storefront_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _CartCard extends StatelessWidget {
  final CartItem item;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onTap;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onRemove;

  const _CartCard({
    required this.item,
    required this.selected,
    required this.onToggleSelect,
    required this.onTap,
    required this.onDecrease,
    required this.onIncrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final atMax = item.quantity >= item.stock;
    final atMin = item.quantity <= 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // ── Top row: checkbox + image + info + delete ──────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // selection checkbox
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onToggleSelect(),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 4),
                // product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: ProductImage(url: item.imageUrl),
                  ),
                ),
                const SizedBox(width: 12),
                // brand / name / size
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.brand.toUpperCase(),
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 2),
                      Text(item.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Size: ${item.size}',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
                // delete button
                GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(Icons.close,
                        size: 20, color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // ── Bottom row: unit price + stepper + subtotal ─────────────────
            Row(
              children: [
                // unit price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Unit price',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text('RM ${item.unitPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
                const Spacer(),
                // quantity stepper
                Row(
                  children: [
                    _StepBtn(
                        icon: Icons.remove,
                        onTap: atMin ? null : onDecrease,
                        active: !atMin),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    _StepBtn(
                        icon: Icons.add,
                        onTap: atMax ? null : onIncrease,
                        active: !atMax),
                  ],
                ),
                const SizedBox(width: 16),
                // subtotal
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Subtotal',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text('RM ${item.subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.primary)),
                  ],
                ),
              ],
            ),

            // stock warning
            if (atMax) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 13, color: Colors.orange.shade600),
                  const SizedBox(width: 4),
                  Text('Max stock reached',
                      style: TextStyle(
                          fontSize: 11, color: Colors.orange.shade600)),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool active;

  const _StepBtn(
      {required this.icon, required this.onTap, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active
        ? Theme.of(context).colorScheme.primary
        : Colors.grey.shade300;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
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
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
