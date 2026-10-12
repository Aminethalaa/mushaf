import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../l10n.dart';
import '../main.dart';

/// First launch: the reader picks a riwaya and an interface language.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  Riwaya? _riwaya;
  String _language = 'ar';

  @override
  Widget build(BuildContext context) {
    final s = S(_language);
    final theme = Theme.of(context);
    return Directionality(
      textDirection: s.ar ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                shrinkWrap: true,
                children: [
                  Text(s.welcome, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 32),
                  Text(s.chooseLanguage, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                      ButtonSegment(value: 'fr', label: Text('Français')),
                    ],
                    selected: {_language},
                    onSelectionChanged: (v) => setState(() => _language = v.first),
                  ),
                  const SizedBox(height: 32),
                  Text(s.chooseRiwaya, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final r in Riwaya.values)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      color: _riwaya == r ? theme.colorScheme.primaryContainer : null,
                      child: ListTile(
                        key: ValueKey('riwaya-${r.name}'),
                        title: Text(s.riwaya(r)),
                        subtitle: FutureBuilder<Mushaf>(
                          future: AppState.of(context).mushaf(r),
                          builder: (context, snap) => Text(
                            snap.data?.basmala ?? '',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(fontFamily: r.fontFamily, fontSize: 22, height: 1.8),
                          ),
                        ),
                        trailing: _riwaya == r ? const Icon(Icons.check_circle) : null,
                        onTap: () => setState(() => _riwaya = r),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(s.changeLater, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const ValueKey('start'),
                    onPressed: _riwaya == null
                        ? null
                        : () => AppState.of(context)
                            .settings
                            .completeOnboarding(riwaya: _riwaya!, language: _language),
                    child: Text(s.start),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
