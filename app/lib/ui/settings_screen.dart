import 'package:flutter/material.dart';

import '../data/printed.dart';
import '../data/quran.dart';
import '../data/tajweed.dart';
import '../l10n.dart';
import '../main.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppState.of(context);
    final settings = app.settings;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        children: [
          ListTile(title: Text(s.riwayaLabel)),
          RadioGroup<Riwaya>(
            groupValue: settings.riwaya,
            onChanged: (v) => settings.setRiwaya(v!),
            child: Column(
              children: [for (final r in Riwaya.values) RadioListTile<Riwaya>(value: r, title: Text(s.riwaya(r)))],
            ),
          ),
          const Divider(),
          ListTile(title: Text(s.language)),
          RadioGroup<String>(
            groupValue: settings.language,
            onChanged: (v) => settings.setLanguage(v!),
            child: const Column(
              children: [
                RadioListTile<String>(value: 'ar', title: Text('العربية')),
                RadioListTile<String>(value: 'fr', title: Text('Français')),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(title: Text(s.nightMode), value: settings.night, onChanged: settings.setNight),
          if (PageStore.supported) ...[
            const Divider(),
            SwitchListTile(
              key: const ValueKey('printed-switch'),
              title: Text(s.printed),
              subtitle: Text(s.printedHint),
              value: settings.printed,
              onChanged: settings.setPrinted,
            ),
            if (settings.printed)
              ListenableBuilder(
                listenable: app.pages,
                builder: (context, _) => Column(
                  children: [for (final r in Riwaya.values) _PackTile(store: app.pages, riwaya: r)],
                ),
              ),
          ],
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
          ListTile(subtitle: Text('${s.localOnly}\n${s.sourceNote}\n${s.tajweedSource}\n${s.printedSource}')),
        ],
      ),
    );
  }
}

/// One riwaya's printed pages: download, progress, or delete.
class _PackTile extends StatelessWidget {
  const _PackTile({required this.store, required this.riwaya});

  final PageStore store;
  final Riwaya riwaya;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final done = store.done(riwaya);
    return switch (store.state(riwaya)) {
      PackState.ready => ListTile(
        dense: true,
        leading: const Icon(Icons.check_circle_outline),
        title: Text(s.riwaya(riwaya)),
        subtitle: Text(s.downloaded),
        trailing: TextButton(onPressed: () => store.delete(riwaya), child: Text(s.delete)),
      ),
      PackState.downloading => ListTile(
        dense: true,
        leading: const Icon(Icons.downloading),
        title: Text(s.riwaya(riwaya)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: done / PageStore.pageCount),
            Text(s.progress(done, PageStore.pageCount)),
          ],
        ),
        trailing: TextButton(onPressed: () => store.cancel(riwaya), child: Text(s.cancel)),
      ),
      PackState.absent => ListTile(
        dense: true,
        leading: const Icon(Icons.cloud_download_outlined),
        title: Text(s.riwaya(riwaya)),
        subtitle: Text(
          [s.sizeMb(PageStore.sizeMb[riwaya]!), if (done > 0) s.progress(done, PageStore.pageCount)].join(' · '),
        ),
        trailing: TextButton(
          key: ValueKey('download-${riwaya.name}'),
          onPressed: () => _download(context),
          child: Text(s.download),
        ),
      ),
    };
  }

  Future<void> _download(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await store.download(riwaya);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}
