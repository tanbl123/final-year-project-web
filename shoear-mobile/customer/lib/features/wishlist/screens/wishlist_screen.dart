import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer/features/auth/state/auth_provider.dart';
import 'package:customer/features/wishlist/state/wishlist_provider.dart';
import 'package:customer/core/widgets/product_image.dart';
import 'package:customer/core/utils/snackbar.dart';
import 'package:customer/core/widgets/sign_in_prompt.dart';
import 'package:customer/features/catalog/screens/product_detail_screen.dart';

/// The customer's saved products. Tap to view; tap the heart to remove.
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    if (context.read<AuthProvider>().isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.read<WishlistProvider>().refresh());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.hasClients && _scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      context.read<WishlistProvider>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    final unavailable = context.select<WishlistProvider, int>((w) => w.unavailableCount);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        actions: [
          if (loggedIn && unavailable > 0)
            TextButton(
              onPressed: _removeUnavailable,
              child: Text('Remove unavailable ($unavailable)',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      body: !loggedIn ? _signInPrompt(context) : _body(context),
    );
  }

  Future<void> _removeUnavailable() async {
    final wl = context.read<WishlistProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove unavailable items?'),
        content: const Text(
            'This removes products that are no longer available from your wishlist. '
            'Out-of-stock items are kept (they may come back).'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await wl.removeUnavailable();
      if (mounted) context.showSnack('Removed unavailable items.');
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    }
  }

  Widget _signInPrompt(BuildContext context) => const SignInPrompt(
        icon: Icons.favorite_border,
        title: 'Sign in to save products',
        subtitle: 'Your wishlist will be saved here',
      );

  Widget _body(BuildContext context) {
    final wl = context.watch<WishlistProvider>();
    final items = wl.wishlist?.items ?? [];

    if (wl.loading && wl.wishlist == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => wl.refresh(),
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.favorite_border, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Center(child: Text('Your wishlist is empty.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => wl.refresh(),
      child: CustomScrollView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final it = items[i];
                  return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                // A removed product can't open its (Approved-only) detail page.
                if (!it.available) {
                  context.showSnack('This product is no longer available.');
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ProductDetailScreen(productId: it.productId)),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProductImage(url: it.imageUrl),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Material(
                            color: Colors.white70,
                            shape: const CircleBorder(),
                            child: IconButton(
                              iconSize: 20,
                              icon: const Icon(Icons.favorite, color: Colors.red),
                              tooltip: 'Remove',
                              onPressed: () async {
                                try {
                                  await context.read<WishlistProvider>().remove(it.productId);
                                } catch (e) {
                                  if (context.mounted) {
                                    context.showSnack(e.toString());
                                  }
                                }
                              },
                            ),
                          ),
                        ),
                        if (!it.available || !it.inStock)
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              color: !it.available ? Colors.black54 : Colors.orange.shade800,
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                  !it.available ? 'No longer available' : 'Out of stock',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.brand.toUpperCase(),
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, letterSpacing: 0.5)),
                        Text(it.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('RM ${it.price.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
                },
                childCount: items.length,
              ),
            ),
          ),
          if (wl.loadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
