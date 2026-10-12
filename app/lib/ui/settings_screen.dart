import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/tajweed.dart';
import '../l10n.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = AppState.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          ListTile(title: Text(s.riwayaLabel)),
          RadioGroup<Riwaya>(
            groupValue: settings.riwaya,
            onChanged: (v) => settings.setRiwaya(v!),
            child: Column(children: [
              for (final r in Riwaya.values) RadioListTile<Riwaya>(value: r, title: Text(s.riwaya(r))),
            ]),
          ),
          const Divider(),
          ListTile(title: Text(s.language)),
          RadioGroup<String>(
            groupValue: settings.language,
            onChanged: (v) => settings.setLanguage(v!),
            child: const Column(children: [
              RadioListTile<String>(value: 'ar', title: Text('العربية')),
              RadioListTile<String>(value: 'fr', title: Text('Français')),
            ]),
          ),
          const Divider(),
          SwitchListTile(
            title: Text(s.nightMode),
            value: settings.night,
            onChanged: settings.setNight,
          ),
          const Divider(),
          SwitchListTile(
            key: const ValueKey('tajweed-switch'),
            title: Text(s.tajweed),
            subtitle: Text(s.tajweedHint),
            value: settings.tajweed,
            onChanged: settings.setTajweed,
          ),
          if (settings.tajweed)
            for (final c in TajweedColor.values)
              ListTile(
                dense: true,
                leading: Icon(Icons.circle, color: c.of(Theme.of(context).brightness)),
                title: Text(s.tajweedColor(c)),
              ),
          const Divider(),
          ListTile(subtitle: Text('${s.localOnly}\n${s.sourceNote}\n${s.tajweedSource}')),
        ],
      ),
    );
  }
}
