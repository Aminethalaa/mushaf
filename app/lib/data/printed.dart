import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Offset;

import 'package:brotli/brotli.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'quran.dart';

/// Where one aya sits on a printed page, in the page's SVG coordinates:
/// one ring per printed line it occupies.
class AyaRegion {
  const AyaRegion(this.sura, this.aya, this.rings);

  final int sura;
  final int aya;
  final List<List<Offset>> rings;

  bool contains(Offset p) => rings.any((r) => _inside(r, p));

  static bool _inside(List<Offset> ring, Offset p) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final a = ring[i], b = ring[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) && p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
    return inside;
  }
}

/// The aya regions of every printed page of one riwaya, bundled with the app.
class PrintedIndex {
  PrintedIndex._(this.commit, this.artworkPath, this.pages);

  /// The quran-svg commit the regions and the artwork are pinned to.
  final String commit;

  /// Path of a page's artwork in that repository, with `{page}` to fill in.
  final String artworkPath;
  final List<List<AyaRegion>> pages;

  static Future<PrintedIndex> load(Riwaya r) async => parse(await rootBundle.loadString('assets/pages/${r.name}.json'));

  static PrintedIndex parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return PrintedIndex._(json['commit'] as String, json['artwork'] as String, [
      for (final page in json['pages'] as List)
        [
          for (final a in page as List)
            AyaRegion(a[0] as int, a[1] as int, [
              for (final ring in a[2] as List)
                [
                  for (var i = 0; i + 1 < (ring as List).length; i += 2)
                    Offset((ring[i] as num).toDouble(), (ring[i + 1] as num).toDouble()),
                ],
            ]),
        ],
    ]);
  }

  List<AyaRegion> regionsOn(int page) => pages[page - 1];

  AyaRegion? hit(int page, Offset p) {
    for (final r in regionsOn(page)) {
      if (r.contains(p)) return r;
    }
    return null;
  }
}

enum PackState { absent, downloading, ready }

/// The printed page artwork, downloaded per riwaya when the reader asks for
/// it (about 75–90 MB each, Brotli-compressed SVG) and kept on the device.
class PageStore extends ChangeNotifier {
  PageStore({Future<Directory> Function()? root}) : _root = root ?? getApplicationSupportDirectory;

  static const pageCount = 604;

  /// Approximate download size of each riwaya's pages, in MB.
  static const sizeMb = {Riwaya.hafs: 73, Riwaya.warsh: 84, Riwaya.qalon: 90, Riwaya.douri: 78, Riwaya.shubah: 80};

  /// Downloading needs a file system; the web build keeps to text pages.
  static bool get supported => !kIsWeb;

  final Future<Directory> Function() _root;
  final Map<Riwaya, PackState> _state = {};
  final Map<Riwaya, int> _done = {};
  final Map<Riwaya, Future<PrintedIndex>> _indexes = {};
  final Set<Riwaya> _cancelled = {};
  final Map<String, Future<String>> _svgCache = {};

  Future<PrintedIndex> index(Riwaya r) => _indexes.putIfAbsent(r, () => PrintedIndex.load(r));

  PackState state(Riwaya r) => _state[r] ?? PackState.absent;

  /// Pages on the device so far, out of [pageCount].
  int done(Riwaya r) => _done[r] ?? 0;

  Future<Directory> _dir(Riwaya r) async => Directory('${(await _root()).path}/pages/${r.name}');

  File _file(Directory dir, int page) => File('${dir.path}/${page.toString().padLeft(3, '0')}.svg.br');

  /// Reads what is already on the device, once at start-up.
  Future<void> scan() async {
    if (!supported) return;
    for (final r in Riwaya.values) {
      final dir = await _dir(r);
      final n = dir.existsSync() ? dir.listSync().where((f) => f.path.endsWith('.svg.br')).length : 0;
      _done[r] = n;
      _state[r] = n >= pageCount ? PackState.ready : PackState.absent;
    }
    notifyListeners();
  }

  /// Downloads every page not yet on the device. Safe to call again after a
  /// failure or a cancel: finished pages are kept.
  Future<void> download(Riwaya r) async {
    if (state(r) != PackState.absent) return;
    _cancelled.remove(r);
    _state[r] = PackState.downloading;
    notifyListeners();
    final idx = await index(r);
    final dir = await _dir(r);
    await dir.create(recursive: true);
    final client = HttpClient();
    final pending = [
      for (var p = 1; p <= pageCount; p++)
        if (!_file(dir, p).existsSync()) p,
    ];
    _done[r] = pageCount - pending.length;
    try {
      // A few pages at a time keeps a phone connection busy without flooding it.
      final workers = [
        for (var w = 0; w < 6; w++)
          () async {
            while (pending.isNotEmpty && !_cancelled.contains(r)) {
              final page = pending.removeAt(0);
              await _fetch(client, idx, page, _file(dir, page));
              _done[r] = done(r) + 1;
              notifyListeners();
            }
          }(),
      ];
      await Future.wait(workers);
    } finally {
      client.close(force: true);
      _state[r] = done(r) >= pageCount ? PackState.ready : PackState.absent;
      notifyListeners();
    }
  }

  Future<void> _fetch(HttpClient client, PrintedIndex idx, int page, File to) async {
    final path = idx.artworkPath.replaceAll('{page}', page.toString().padLeft(3, '0'));
    final uri = Uri.parse('https://raw.githubusercontent.com/quran-ws/quran-svg/${idx.commit}/$path');
    final req = await client.getUrl(uri);
    final res = await req.close();
    if (res.statusCode != 200) {
      await res.drain<void>();
      throw HttpException('HTTP ${res.statusCode}', uri: uri);
    }
    final part = File('${to.path}.part');
    await res.pipe(part.openWrite());
    await part.rename(to.path);
  }

  void cancel(Riwaya r) => _cancelled.add(r);

  Future<void> delete(Riwaya r) async {
    cancel(r);
    final dir = await _dir(r);
    if (dir.existsSync()) await dir.delete(recursive: true);
    _svgCache.removeWhere((k, _) => k.startsWith('${r.name}/'));
    _state[r] = PackState.absent;
    _done[r] = 0;
    notifyListeners();
  }

  /// The SVG source of one printed page. Decoding runs off the UI thread and
  /// the last few pages stay in memory for page turns back and forth.
  Future<String> svg(Riwaya r, int page) {
    final key = '${r.name}/$page';
    final hit = _svgCache.remove(key);
    if (hit != null) return _svgCache[key] = hit;
    while (_svgCache.length >= 8) {
      _svgCache.remove(_svgCache.keys.first);
    }
    return _svgCache[key] = () async {
      final bytes = await _file(await _dir(r), page).readAsBytes();
      return compute(_decode, bytes);
    }();
  }
}

String _decode(List<int> bytes) => brotli.decodeToString(bytes);
