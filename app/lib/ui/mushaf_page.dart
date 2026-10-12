import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../data/tajweed.dart';
import '../l10n.dart';

/// Colours of the printed page, in day and night.
class PageColors {
  const PageColors({required this.paper, required this.ink, required this.frame, required this.mark});

  final Color paper;
  final Color ink;
  final Color frame;
  final Color mark;

  static PageColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const PageColors(
          paper: Color(0xFF15181A), ink: Color(0xFFE8E4D8), frame: Color(0xFF3E6B57), mark: Color(0x334FB286))
      : const PageColors(
          paper: Color(0xFFFFFCF2), ink: Color(0xFF1A1A1A), frame: Color(0xFF1B6B4A), mark: Color(0x33E0B04A));
}

sealed class _Block {}

class _Header extends _Block {
  _Header(this.sura, this.basmala);
  final Sura sura;
  final bool basmala;
}

class _Text extends _Block {
  _Text(this.ayat);
  final List<Aya> ayat;
}

/// One page of the Mushaf, drawn from the text. The font size is chosen so the
/// whole page fits the space it is given, like a printed page.
class MushafPage extends StatefulWidget {
  const MushafPage({
    super.key,
    required this.mushaf,
    required this.page,
    this.highlighted = const {},
    this.onAyaLongPress,
    this.tajweed = false,
  });

  final Mushaf mushaf;
  final int page;

  /// Colour the text by tajweed rule, when the riwaya has the data.
  final bool tajweed;
  final Set<int> highlighted;
  final void Function(Aya aya)? onAyaLongPress;

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  final List<LongPressGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  List<_Block> _blocks() {
    final m = widget.mushaf;
    final blocks = <_Block>[];
    for (final a in m.ayatOnPage(widget.page)) {
      if (a.no == 1) {
        blocks.add(_Header(m.sura(a.sura), m.printsBasmala(a.sura)));
      }
      if (blocks.isEmpty || blocks.last is! _Text) blocks.add(_Text([]));
      (blocks.last as _Text).ayat.add(a);
    }
    return blocks;
  }

  static const _lineHeight = 2.05;

  double _headerHeight(double fs, _Header h) => fs * 2.4 + (h.basmala ? fs * _lineHeight : 0) + 8;

  List<TajweedSpan>? _coloursOf(Aya a) => widget.tajweed ? widget.mushaf.tajweed?.ayat[a.index] : null;

  TextSpan _span(_Text block, double fs, PageColors c, Brightness b, {bool interactive = false}) {
    return TextSpan(
      children: [
        for (final a in block.ayat) _ayaSpan(a, c, b, interactive),
      ],
      style: TextStyle(
        fontFamily: widget.mushaf.riwaya.fontFamily,
        fontSize: fs,
        height: _lineHeight,
        color: c.ink,
      ),
    );
  }

  TextSpan _ayaSpan(Aya a, PageColors c, Brightness b, bool interactive) {
    final background = widget.highlighted.contains(a.index) ? c.mark : null;
    LongPressGestureRecognizer? recognizer;
    if (interactive && widget.onAyaLongPress != null) {
      recognizer = LongPressGestureRecognizer()..onLongPress = () => widget.onAyaLongPress!(a);
      _recognizers.add(recognizer);
    }
    final colours = _coloursOf(a);
    if (colours == null || colours.isEmpty) {
      return TextSpan(
        text: '${a.text} ',
        style: background == null ? null : TextStyle(backgroundColor: background),
        recognizer: recognizer,
      );
    }
    // A gesture only reaches the innermost span, so every run carries the
    // aya's recognizer.
    return TextSpan(
      style: background == null ? null : TextStyle(backgroundColor: background),
      children: [
        for (final (text, colour) in Tajweed.runs('${a.text} ', colours))
          TextSpan(
            text: text,
            style: colour == null ? null : TextStyle(color: colour.of(b)),
            recognizer: recognizer,
          ),
      ],
    );
  }

  double _measure(List<_Block> blocks, double fs, double width, PageColors c, Brightness brightness) {
    var h = 0.0;
    for (final b in blocks) {
      switch (b) {
        case _Header():
          h += _headerHeight(fs, b);
        case _Text():
          final tp = TextPainter(
            text: _span(b, fs, c, brightness),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.justify,
          )..layout(maxWidth: width);
          h += tp.height;
          tp.dispose();
      }
    }
    return h;
  }

  /// The largest font size at which the page fits, found by bisection.
  double _fit(List<_Block> blocks, Size size, PageColors c, Brightness b) {
    // The first two pages are short and centred, as in print; don't let them balloon.
    var lo = 8.0, hi = size.width / (widget.page <= 2 ? 13 : 9);
    for (var i = 0; i < 14; i++) {
      final mid = (lo + hi) / 2;
      if (_measure(blocks, mid, size.width, c, b) <= size.height) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    // A small margin for rounding between the measurement and the real layout.
    return lo * 0.97;
  }

  @override
  Widget build(BuildContext context) {
    final c = PageColors.of(context);
    final brightness = Theme.of(context).brightness;
    final s = S.of(context);
    final m = widget.mushaf;
    final ayat = m.ayatOnPage(widget.page);
    final blocks = _blocks();
    _disposeRecognizers();

    return Container(
      color: c.paper,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: Column(
        children: [
          DefaultTextStyle.merge(
            style: TextStyle(color: c.frame, fontSize: 12, fontWeight: FontWeight.w600),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                children: [
                  Text(m.sura(ayat.first.sura).nameAr, style: TextStyle(fontFamily: m.riwaya.fontFamily, fontSize: 15)),
                  const Spacer(),
                  Text(S('ar').juz(ayat.first.juz)),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: c.frame, width: 1.2)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: LayoutBuilder(builder: (context, box) {
                final fs = _fit(blocks, box.biggest, c, brightness);
                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: Column(
                    mainAxisAlignment:
                        widget.page <= 2 ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final b in blocks)
                        switch (b) {
                          _Header() => _SuraHeader(
                              header: b, fontSize: fs, mushaf: m, colors: c, tajweed: widget.tajweed),
                          _Text() => Text.rich(
                              _span(b, fs, c, brightness, interactive: true),
                              textAlign: TextAlign.justify,
                              textDirection: TextDirection.rtl,
                            ),
                        },
                    ],
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(s.num(widget.page), style: TextStyle(color: c.frame, fontSize: 12)),
          ),
        ],
      ),
    );
  }

}

class _SuraHeader extends StatelessWidget {
  const _SuraHeader({
    required this.header,
    required this.fontSize,
    required this.mushaf,
    required this.colors,
    required this.tajweed,
  });

  final _Header header;
  final double fontSize;
  final Mushaf mushaf;
  final PageColors colors;
  final bool tajweed;

  @override
  Widget build(BuildContext context) {
    final font = mushaf.riwaya.fontFamily;
    return SizedBox(
      height: fontSize * 2.4 + (header.basmala ? fontSize * _MushafPageState._lineHeight : 0) + 8,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: fontSize * 2,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: colors.frame, width: 1.2),
              borderRadius: BorderRadius.circular(fontSize),
              color: colors.frame.withValues(alpha: 0.08),
            ),
            child: Text(
              'سُورَةُ ${header.sura.nameAr}',
              textDirection: TextDirection.rtl,
              style: TextStyle(fontFamily: font, fontSize: fontSize * 0.95, color: colors.ink, height: 1.2),
            ),
          ),
          if (header.basmala)
            Text.rich(
              TextSpan(children: [
                for (final (text, colour) in Tajweed.runs(
                    mushaf.basmala, tajweed ? mushaf.basmalaTajweed : const []))
                  TextSpan(
                      text: text,
                      style: colour == null
                          ? null
                          : TextStyle(color: colour.of(Theme.of(context).brightness))),
              ]),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                  fontFamily: font, fontSize: fontSize, color: colors.ink, height: _MushafPageState._lineHeight),
            ),
        ],
      ),
    );
  }
}
