import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../l10n.dart';
import '../main.dart';
import 'reader_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static void open(BuildContext context, Mushaf mushaf, int page, {Aya? focus}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReaderScreen(mushaf: mushaf, page: page, focus: focus),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppState.of(context);
    final riwaya = app.settings.riwaya;
    return FutureBuilder<Mushaf>(
      future: app.mushaf(riwaya),
      builder: (context, snap) {
        final m = snap.data;
        if (m == null || m.riwaya != riwaya) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _Home(mushaf: m);
      },
    );
  }
}

class _Home extends StatelessWidget {
  const _Home({required this.mushaf});

  final Mushaf mushaf;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final settings = AppState.of(context).settings;
    final last = settings.lastPage(mushaf.riwaya);
    final font = mushaf.riwaya.fontFamily;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.appName),
          actions: [
            IconButton(
              tooltip: s.search,
              icon: const Icon(Icons.search),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SearchScreen(mushaf: mushaf))),
            ),
            IconButton(
              tooltip: s.settings,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: s.suras),
              Tab(text: s.ajza),
              Tab(text: s.bookmarks),
            ],
          ),
        ),
        body: Column(
          children: [
            Card(
              margin: const EdgeInsets.all(12),
              child: ListTile(
                key: const ValueKey('continue'),
                leading: const Icon(Icons.menu_book),
                title: Text(s.continueReading),
                subtitle: Text(
                  '${mushaf.sura(mushaf.ayatOnPage(last).first.sura).nameAr} · ${s.page(last)} · ${s.riwaya(mushaf.riwaya)}',
                ),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => HomeScreen.open(context, mushaf, last),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    itemCount: mushaf.suras.length,
                    itemBuilder: (context, i) {
                      final sura = mushaf.suras[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text(s.num(sura.no))),
                        title: Text(
                          sura.nameAr,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontFamily: font, fontSize: 20),
                        ),
                        subtitle: Text('${s.ar ? '' : '${sura.nameEn} · '}${s.ayatCount(sura.ayatCount)}'),
                        trailing: Text(s.num(sura.page)),
                        onTap: () => HomeScreen.open(context, mushaf, sura.page),
                      );
                    },
                  ),
                  ListView.builder(
                    itemCount: 30,
                    itemBuilder: (context, i) {
                      final page = mushaf.firstPageOfJuz(i + 1);
                      return ListTile(
                        title: Text(s.juz(i + 1)),
                        subtitle: Text(
                          mushaf.sura(mushaf.ayatOnPage(page).first.sura).nameAr,
                          style: TextStyle(fontFamily: font, fontSize: 16),
                        ),
                        trailing: Text(s.num(page)),
                        onTap: () => HomeScreen.open(context, mushaf, page),
                      );
                    },
                  ),
                  _Bookmarks(mushaf: mushaf),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bookmarks extends StatelessWidget {
  const _Bookmarks({required this.mushaf});

  final Mushaf mushaf;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final app = AppState.of(context);
    final list = app.settings.bookmarks;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(s.noBookmarks, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      children: [
        for (final b in list)
          FutureBuilder<Mushaf>(
            future: app.mushaf(b.riwaya),
            builder: (context, snap) {
              final m = snap.data;
              if (m == null) return const SizedBox(height: 56);
              final aya = m.nearest(b.sura, b.aya);
              return ListTile(
                title: Text(s.ayaRef(m.sura(b.sura).nameAr, b.aya)),
                subtitle: Text(
                  aya.bareText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: m.riwaya.fontFamily, fontSize: 18),
                ),
                trailing: Text(s.riwaya(b.riwaya), style: Theme.of(context).textTheme.bodySmall),
                onTap: () => HomeScreen.open(context, m, aya.page, focus: aya),
              );
            },
          ),
      ],
    );
  }
}
