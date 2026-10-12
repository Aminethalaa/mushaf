import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/printed.dart';
import '../data/quran.dart';
import '../l10n.dart';
import '../main.dart';
import '../settings.dart';
import 'mushaf_page.dart';
import 'printed_page.dart';
import 'settings_screen.dart';

/// Free reading. Turning pages only updates this device's last page; nothing
/// here is synced. The wird has its own mode in phase 2.
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.mushaf, required this.page, this.focus});

  final Mushaf mushaf;
  final int page;

  /// An aya to highlight on arrival, from search or a bookmark.
  final Aya? focus;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Mushaf _mushaf = widget.mushaf;
  late int _page = widget.page;
  late Set<int> _highlighted = {if (widget.focus != null) widget.focus!.index};
  PageController? _controller;
  bool? _spread;

  static bool _isSpread(Size size) => size.width > size.height && size.width >= 840;

  int _indexOf(int page, bool spread) => spread ? (page - 1) ~/ 2 : page - 1;

  void _ensureController(bool spread) {
    if (_spread == spread && _controller != null) return;
    _controller?.dispose();
    _spread = spread;
    _controller = PageController(initialPage: _indexOf(_page, spread));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onIndex(int index) {
    final page = _spread! ? index * 2 + 1 : index + 1;
    setState(() {
      _page = page;
      _highlighted = {};
    });
    AppState.of(context).settings.setLastPage(_mushaf.riwaya, page);
  }

  Future<void> _pickRiwaya() async {
    final s = S.of(context);
    final picked = await showModalBottomSheet<Riwaya>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(s.switchRiwaya)),
            for (final r in Riwaya.values)
              ListTile(
                key: ValueKey('pick-${r.name}'),
                title: Text(s.riwaya(r)),
                trailing: r == _mushaf.riwaya ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, r),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != _mushaf.riwaya) await _switchRiwaya(picked);
  }

  /// Opens [to] at the aya this page starts with. Counts differ between
  /// riwayat, so the place is matched by sura and aya number, not by page.
  Future<void> _switchRiwaya(Riwaya to) async {
    final app = AppState.of(context);
    final current = _mushaf.ayatOnPage(_page).first;
    final other = await app.mushaf(to);
    final target = other.nearest(current.sura, current.no);
    await app.settings.setRiwaya(other.riwaya);
    if (!mounted) return;
    setState(() {
      _mushaf = other;
      _page = target.page;
      _highlighted = {};
      _controller?.jumpToPage(_indexOf(_page, _spread!));
    });
  }

  void _ayaMenu(Aya aya) {
    final s = S.of(context);
    final settings = AppState.of(context).settings;
    final bookmark = Bookmark(_mushaf.riwaya, aya.sura, aya.no);
    final saved = settings.isBookmarked(bookmark);
    setState(() => _highlighted = {aya.index});
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(s.ayaRef(_mushaf.sura(aya.sura).nameAr, aya.no))),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(s.copy),
              onTap: () {
                Clipboard.setData(
                  ClipboardData(
                    text:
                        '${aya.bareText}\n[${s.ayaRef(_mushaf.sura(aya.sura).nameAr, aya.no)} · ${s.riwaya(_mushaf.riwaya)}]',
                  ),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(s.copied)));
              },
            ),
            ListTile(
              leading: Icon(saved ? Icons.bookmark_remove : Icons.bookmark_add),
              title: Text(saved ? s.removeBookmark : s.addBookmark),
              onTap: () {
                settings.toggleBookmark(bookmark);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      if (mounted) setState(() => _highlighted = {});
    });
  }

  bool get _showPrinted {
    final app = AppState.of(context);
    return app.settings.printed && app.pages.state(_mushaf.riwaya) == PackState.ready;
  }

  Widget _buildPage(int page) {
    if (page > _mushaf.pageCount) return const SizedBox.shrink();
    final app = AppState.of(context);
    if (_showPrinted) {
      return PrintedPage(
        key: ValueKey('printed-${_mushaf.riwaya.name}-$page'),
        store: app.pages,
        mushaf: _mushaf,
        page: page,
        highlighted: _highlighted,
        onAyaLongPress: _ayaMenu,
      );
    }
    return MushafPage(
      key: ValueKey('${_mushaf.riwaya.name}-$page'),
      mushaf: _mushaf,
      page: page,
      highlighted: _highlighted,
      onAyaLongPress: _ayaMenu,
      tajweed: app.settings.tajweed,
    );
  }

  /// Shown when printed pages are on but this riwaya's are not downloaded.
  Widget? _missingPagesBanner() {
    final app = AppState.of(context);
    if (!app.settings.printed || !PageStore.supported) return null;
    if (app.pages.state(_mushaf.riwaya) == PackState.ready) return null;
    final s = S.of(context);
    return MaterialBanner(
      content: Text(s.printedMissing),
      actions: [
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          child: Text(s.download),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final first = _mushaf.ayatOnPage(_page).first;
    return Scaffold(
      appBar: AppBar(
        title: Text('${_mushaf.sura(first.sura).nameAr} · ${s.page(_page)}'),
        actions: [
          TextButton.icon(
            key: const ValueKey('switch-riwaya'),
            onPressed: _pickRiwaya,
            icon: const Icon(Icons.swap_horiz),
            label: Text(s.riwaya(_mushaf.riwaya)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: AppState.of(context).pages,
          builder: (context, _) => Column(
            children: [
              ?_missingPagesBanner(),
              Expanded(child: _pages()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pages() => LayoutBuilder(
    builder: (context, box) {
      final spread = _isSpread(box.biggest);
      _ensureController(spread);
      final count = spread ? (_mushaf.pageCount + 1) ~/ 2 : _mushaf.pageCount;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: PageView.builder(
          key: ValueKey('${_mushaf.riwaya.name}-$spread'),
          controller: _controller,
          itemCount: count,
          onPageChanged: _onIndex,
          itemBuilder: (context, index) => spread
              ? Row(
                  children: [
                    Expanded(child: _buildPage(index * 2 + 1)),
                    const VerticalDivider(width: 1),
                    Expanded(child: _buildPage(index * 2 + 2)),
                  ],
                )
              : _buildPage(index + 1),
        ),
      );
    },
  );
}
