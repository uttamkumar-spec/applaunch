import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/progress_provider.dart';

class StravaConnectCard extends ConsumerWidget {
  const StravaConnectCard({super.key});

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final url = await ref.read(stravaServiceProvider).fetchConnectUrl();
    if (url == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't reach the server to connect Strava. Try again shortly.")),
        );
      }
      return;
    }
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectedAsync = ref.watch(stravaConnectedProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: Color(0xFFFFEDE3), shape: BoxShape.circle),
              child: const Icon(Icons.directions_bike_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: connectedAsync.when(
                loading: () => const Text('Checking Strava connection…'),
                error: (error, stackTrace) => const Text('Connect Strava to sync your activities'),
                data: (connected) => Text(
                  connected
                      ? 'Strava connected — activities sync automatically'
                      : 'Connect Strava to bring in your runs & rides',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            connectedAsync.maybeWhen(
              data: (connected) => connected
                  ? const Icon(Icons.check_circle, color: AppColors.primary)
                  : OutlinedButton(
                      onPressed: () => _connect(context, ref),
                      child: const Text('Connect'),
                    ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
