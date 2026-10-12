import 'package:flutter/material.dart';

import '../data/quran.dart';
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
          ListTile(subtitle: Text('${s.localOnly}\n${s.sourceNote}')),
        ],
      ),
    );
  }
}
