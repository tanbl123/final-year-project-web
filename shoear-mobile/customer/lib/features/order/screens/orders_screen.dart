import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:customer/features/order/models/order.dart';
import 'package:customer/features/order/services/order_service.dart';
import 'package:customer/features/auth/state/auth_provider.dart';
import 'package:customer/features/auth/screens/login_screen.dart';
import 'package:customer/features/order/screens/order_detail_screen.dart';

const Map<String, Color> kOrderStatusColors = {
  'Placed': Colors.blueGrey,
  'Paid': Colors.indigo,
  'Processing': Colors.indigo,
  'Shipped': Colors.indigo,
  'OutForDelivery': Colors.indigo,
  'Delivered': Colors.green,
  'Completed': Colors.green,
  'Cancelled': Colors.red,
};

String prettyStatus(String s) => s.replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');

/// The customer's order history.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  Future<List<CustomerOrderSummary>>? _future;
  bool _wasLoggedIn = false;

  Future<void> _refresh() async {
    final next = context.read<OrderService>().listOrders();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthProvider>().isLoggedIn;
    if (loggedIn != _wasLoggedIn) {
      _wasLoggedIn = loggedIn;
      _future = null; // reload on login / drop on logout
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: !loggedIn ? _signInPrompt(context) : _ordersBody(context),
    );
  }

  Widget _signInPrompt(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text('Sign in to see your orders.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );

  Widget _ordersBody(BuildContext context) {
    _future ??= context.read<OrderService>().listOrders();
    return FutureBuilder<List<CustomerOrderSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorView(message: snap.error.toString(), onRetry: _refresh);
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Center(child: Text('You have no orders yet.')),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _OrderCard(order: orders[i], onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orders[i].orderId)),
                );
                _refresh(); // status may have changed while viewing
              }),
            ),
          );
        },
      );
  }
}

class _OrderCard extends StatelessWidget {
  final CustomerOrderSummary order;
  final VoidCallback onTap;
  const _OrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dt = order.orderDate == null ? null : DateTime.tryParse(order.orderDate!)?.toLocal();
    final dateStr = dt == null ? '' : '${dt.day}/${dt.month}/${dt.year}';
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Text(order.orderId, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('RM ${order.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$dateStr · ${order.itemCount} item(s)', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _Chip(label: prettyStatus(order.orderStatus), color: kOrderStatusColors[order.orderStatus] ?? Colors.grey),
                if (order.deliveryStatus != null)
                  _Chip(label: 'Parcel: ${prettyStatus(order.deliveryStatus!)}', color: Colors.teal, outlined: true),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  const _Chip({required this.label, required this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        border: outlined ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
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
