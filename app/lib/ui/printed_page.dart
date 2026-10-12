import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/printed.dart';
import '../data/quran.dart';
import 'mushaf_page.dart';

/// One page of the printed Madinah Mushaf, drawn from the downloaded artwork.
/// The ink takes the page colours, so night mode works as on text pages, and
/// a long press finds the aya from the bundled region index.
class PrintedPage extends StatelessWidget {
  const PrintedPage({
    super.key,
    required this.store,
    required this.mushaf,
    required this.page,
    this.highlighted = const {},
    this.onAyaLongPress,
  });

  final PageStore store;

  /// The text of the same riwaya, for the running head and for the aya a
  /// long press lands on.
  final Mushaf mushaf;
  final int page;

  /// Highlighted ayat, by [Aya.index] in [mushaf].
  final Set<int> highlighted;
  final void Function(Aya aya)? onAyaLongPress;

  static final _viewBox = RegExp(r'viewBox="([-\d.]+)[ ,]+([-\d.]+)[ ,]+([-\d.]+)[ ,]+([-\d.]+)"');

  @override
  Widget build(BuildContext context) {
    final c = PageColors.of(context);
    final r = mushaf.riwaya;
    return PageFrame(
      mushaf: mushaf,
      page: page,
      ruled: false,
      child: FutureBuilder(
        future: Future.wait([store.index(r), store.svg(r, page)]),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Icon(Icons.broken_image_outlined, color: c.frame));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final index = snap.data![0] as PrintedIndex;
          final svg = snap.data![1] as String;
          final m = _viewBox.firstMatch(svg.substring(0, svg.length.clamp(0, 2000)));
          final box = m == null
              ? const Rect.fromLTWH(0, 0, 345, 550)
              : Rect.fromLTWH(double.parse(m[1]!), double.parse(m[2]!), double.parse(m[3]!), double.parse(m[4]!));
          final marked = {
            for (final i in highlighted)
              if (i < mushaf.ayat.length) (mushaf.ayat[i].sura, mushaf.ayat[i].no),
          };
          return LayoutBuilder(
            builder: (context, constraints) {
              final scale = (constraints.maxWidth / box.width).clamp(0.0, constraints.maxHeight / box.height);
              final size = box.size * scale;
              return Center(
                child: GestureDetector(
                  onLongPressStart: onAyaLongPress == null
                      ? null
                      : (d) {
                          final p = d.localPosition / scale + box.topLeft;
                          final region = index.hit(page, p);
                          final aya = region == null ? null : mushaf.find(region.sura, region.aya);
                          if (aya != null) onAyaLongPress!(aya);
                        },
                  child: SizedBox.fromSize(
                    size: size,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _Highlight(
                            [
                              for (final a in index.regionsOn(page))
                                if (marked.contains((a.sura, a.aya))) a,
                            ],
                            box,
                            scale,
                            c.mark,
                          ),
                        ),
                        SvgPicture.string(
                          svg,
                          width: size.width,
                          height: size.height,
                          colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Highlight extends CustomPainter {
  _Highlight(this.regions, this.box, this.scale, this.color);

  final List<AyaRegion> regions;
  final Rect box;
  final double scale;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (regions.isEmpty) return;
    canvas.scale(scale);
    canvas.translate(-box.left, -box.top);
    final paint = Paint()..color = color;
    for (final r in regions) {
      for (final ring in r.rings) {
        canvas.drawPath(Path()..addPolygon(ring, true), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_Highlight old) => !listEquals(old.regions, regions) || old.scale != scale || old.color != color;
}
