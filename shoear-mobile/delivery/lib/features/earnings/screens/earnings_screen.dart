import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:delivery/core/utils/snackbar.dart';
import 'package:delivery/features/earnings/services/earnings_service.dart';

/// Courier earnings: accrued balance, lifetime earned, Stripe payout setup and
/// payout history. Payouts themselves are initiated by the admin; here the
/// courier connects their Stripe account so they can be paid.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  Future<Map<String, dynamic>>? _future;
  bool _connecting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= context.read<EarningsService>().earnings();
  }

  void _reload() => setState(() => _future = context.read<EarningsService>().earnings());

  String _rm(num v) => 'RM ${v.toStringAsFixed(2)}';

  Future<void> _connectPayouts() async {
    setState(() => _connecting = true);
    try {
      final url = await context.read<EarningsService>().onboardUrl();
      if (url.isEmpty) throw Exception('Could not start payout setup.');
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok && mounted) context.showSnack('Could not open the payout setup page.');
    } catch (e) {
      if (mounted) context.showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My earnings')),
      body: RefreshIndicator(
        onRefresh: () async => _reload(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load earnings.\n${snap.error}',
                      textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ),
              ]);
            }
            final d = snap.data!;
            final balance = (d['balance'] as num?)?.toDouble() ?? 0;
            final lifetime = (d['lifetimeEarned'] as num?)?.toDouble() ?? 0;
            final fee = (d['feePerDelivery'] as num?)?.toDouble() ?? 0;
            final pendingCount = (d['pendingCount'] as int?) ?? 0;
            final connected = d['connected'] == true;
            final payoutsEnabled = d['payoutsEnabled'] == true;
            final payouts = (d['payouts'] as List?) ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Balance card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Pending balance', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(_rm(balance), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('$pendingCount delivery(s) · ${_rm(fee)} each', style: const TextStyle(color: Colors.grey)),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Lifetime earned', style: TextStyle(color: Colors.grey)),
                            Text(_rm(lifetime), style: const TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Payout account status
                _payoutStatusCard(connected, payoutsEnabled),
                const SizedBox(height: 16),

                Text('Payout history', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (payouts.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('No payouts yet.', style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...payouts.map((p) => _payoutTile(p as Map<String, dynamic>)),
                const SizedBox(height: 24),
                Text(
                  'Earnings are paid out by ShoeAR to your connected account. '
                  'Each completed delivery adds ${_rm(fee)} to your balance.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _payoutStatusCard(bool connected, bool payoutsEnabled) {
    final ready = connected && payoutsEnabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(ready ? Icons.check_circle : Icons.account_balance_outlined,
                    color: ready ? Colors.green : Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ready
                        ? 'Payout account connected'
                        : connected
                            ? 'Finish connecting your payout account'
                            : 'Set up payouts to get paid',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (!ready) ...[
              const SizedBox(height: 8),
              const Text(
                'Connect a bank account through Stripe so ShoeAR can pay your earnings.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _connecting ? null : _connectPayouts,
                icon: _connecting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.link),
                label: Text(connected ? 'Continue setup' : 'Set up payouts'),
              ),
              const SizedBox(height: 4),
              TextButton(onPressed: _reload, child: const Text("I've finished — refresh status")),
            ],
          ],
        ),
      ),
    );
  }

  Widget _payoutTile(Map<String, dynamic> p) {
    final amount = (p['amount'] as num?)?.toDouble() ?? 0;
    final status = p['payoutStatus']?.toString() ?? '';
    final count = (p['deliveryCount'] as int?) ?? 0;
    final date = p['created_at']?.toString() ?? '';
    final isAuto = (p['isAuto'] == 1 || p['isAuto'] == true);
    final color = status == 'Paid' ? Colors.green : status == 'Failed' ? Colors.red : Colors.orange;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.payments_outlined, color: color),
      title: Text(_rm(amount), style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('$count delivery(s) · ${date.split(' ').first} · ${isAuto ? 'Auto' : 'Manual'}'),
      trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
