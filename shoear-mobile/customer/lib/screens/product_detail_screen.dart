import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../services/catalog_service.dart';
import '../state/auth_provider.dart';
import '../state/cart_provider.dart';
import 'catalog_screen.dart' show ProductImage;
import 'login_screen.dart';

/// Full detail for one product: images, price, sizes, description, reviews,
/// add-to-cart, and (when enabled) an AR try-on entry point.
class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Future<ProductDetail> _future;
  String? _selectedVariantId;   // the chosen size
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<CatalogService>().getProduct(widget.productId);
  }

  Future<void> _addToCart(ProductDetail p) async {
    // cart needs a signed-in customer — send guests to login first
    if (!context.read<AuthProvider>().isLoggedIn) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    if (_selectedVariantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a size.')));
      return;
    }
    setState(() => _adding = true);
    try {
      await context.read<CartProvider>().add(_selectedVariantId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${p.name}" to your cart.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: FutureBuilder<ProductDetail>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(snap.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ),
            );
          }
          final p = snap.data!;
          return _body(context, p);
        },
      ),
    );
  }

  Widget _body(BuildContext context, ProductDetail p) {
    final theme = Theme.of(context);
    final hasStock = p.variants.any((v) => v.inStock);
    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              SizedBox(
                height: 300,
                child: p.images.isEmpty
                    ? const ProductImage(url: null)
                    : PageView(children: [for (final url in p.images) ProductImage(url: url)]),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.brand.toUpperCase(), style: TextStyle(color: Colors.grey.shade600, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text(p.name, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('RM ${p.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                    if (p.ratingCount > 0) ...[
                      const SizedBox(height: 4),
                      Text('★ ${p.ratingAverage}  ·  ${p.ratingCount} review(s)', style: TextStyle(color: Colors.amber.shade800)),
                    ],

                    if (p.virtualTryOnEnable) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('AR try-on is coming in the next update.')),
                        ),
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('AR Try-On'),
                      ),
                    ],

                    const SizedBox(height: 20),
                    if (p.variants.isNotEmpty) ...[
                      Text('Select size', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final v in p.variants)
                            ChoiceChip(
                              label: Text(v.size),
                              selected: _selectedVariantId == v.variantId,
                              onSelected: v.inStock ? (_) => setState(() => _selectedVariantId = v.variantId) : null,
                              labelStyle: TextStyle(
                                color: v.inStock ? null : Colors.grey,
                                decoration: v.inStock ? null : TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    if ((p.description ?? '').isNotEmpty) ...[
                      Text('Description', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(p.description!),
                      const SizedBox(height: 20),
                    ],

                    if (p.supplierName != null) ...[
                      Text('Sold by ${p.supplierName}', style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 20),
                    ],

                    Text('Reviews', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (p.reviews.isEmpty)
                      Text('No reviews yet.', style: TextStyle(color: Colors.grey.shade600))
                    else
                      for (final r in p.reviews) _ReviewTile(review: r),
                  ],
                ),
              ),
            ],
          ),
        ),
        _addToCartBar(context, p, hasStock),
      ],
    );
  }

  Widget _addToCartBar(BuildContext context, ProductDetail p, bool hasStock) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: (!hasStock || _adding) ? null : () => _addToCart(p),
            icon: _adding
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.add_shopping_cart),
            label: Text(hasStock ? 'Add to cart' : 'Out of stock'),
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text('★' * review.ratingScore, style: TextStyle(color: Colors.amber.shade800)),
            ],
          ),
          if ((review.comment ?? '').isNotEmpty) Text(review.comment!),
          if ((review.supplierReply ?? '').isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6, left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text('Seller reply: ${review.supplierReply}', style: const TextStyle(fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
