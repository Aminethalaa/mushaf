import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

enum Riwaya {
  warsh('Warsh'),
  hafs('Hafs');

  const Riwaya(this.fontFamily);

  final String fontFamily;

  Riwaya get other => this == warsh ? hafs : warsh;
}

class Sura {
  const Sura({
    required this.no,
    required this.nameAr,
    required this.nameEn,
    required this.page,
    required this.ayatCount,
  });

  final int no;
  final String nameAr;
  final String nameEn;
  final int page;
  final int ayatCount;
}

class Aya {
  const Aya({
    required this.index,
    required this.sura,
    required this.no,
    required this.page,
    required this.pageEnd,
    required this.juz,
    required this.text,
    required this.searchText,
    required this.searchTextAlef,
  });

  /// Position in the riwaya's own count, from 0.
  final int index;
  final int sura;
  final int no;
  final int page;

  /// Differs from [page] only for the few Warsh ayat that run onto the next page.
  final int pageEnd;
  final int juz;

  /// The KFGQPC text exactly as published, ending with the aya number.
  final String text;

  /// Normalised text without diacritics, used for search.
  final String searchText;

  /// The same with the small (dagger) alef written as a full alef, so that
  /// «العالمين» matches «ٱلۡعَٰلَمِينَ» while «ذلك» still matches «ذَٰلِكَ».
  final String searchTextAlef;

  /// The text without the trailing aya number, for copying.
  String get bareText => text.replaceAll(RegExp(r'[ \s]*[٠-٩]+\s*$'), '').trim();
}

/// One riwaya's full text, loaded from the bundled assets.
class Mushaf {
  Mushaf._(this.riwaya, this.pageCount, this.suras, this.ayat, this.sourceSha1)
      : _pageStarts = _indexPages(ayat, pageCount);

  final Riwaya riwaya;
  final int pageCount;
  final List<Sura> suras;
  final List<Aya> ayat;
  final String sourceSha1;
  final List<int> _pageStarts;

  static List<int> _indexPages(List<Aya> ayat, int pageCount) {
    final starts = List<int>.filled(pageCount + 2, ayat.length);
    for (var i = ayat.length - 1; i >= 0; i--) {
      starts[ayat[i].page] = i;
    }
    starts[pageCount + 1] = ayat.length;
    return starts;
  }

  static Future<Mushaf> load(Riwaya riwaya) async {
    final raw = await rootBundle.loadString('assets/quran/${riwaya.name}.json');
    return parse(riwaya, raw);
  }

  static Mushaf parse(Riwaya riwaya, String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final suras = [
      for (final s in json['suras'] as List)
        Sura(
          no: s['no'] as int,
          nameAr: s['nameAr'] as String,
          nameEn: s['nameEn'] as String,
          page: s['page'] as int,
          ayatCount: s['ayat'] as int,
        ),
    ];
    final rows = json['ayat'] as List;
    final ayat = <Aya>[
      for (var i = 0; i < rows.length; i++)
        Aya(
          index: i,
          sura: rows[i][0] as int,
          no: rows[i][1] as int,
          page: rows[i][2] as int,
          pageEnd: rows[i][3] as int,
          juz: rows[i][4] as int,
          text: rows[i][7] as String,
          searchText: normalizeArabic(
              (rows[i][8] as String).isNotEmpty ? rows[i][8] as String : rows[i][7] as String),
          searchTextAlef: normalizeArabic((rows[i][7] as String).replaceAll('\u0670', '\u0627')),
        ),
    ];
    return Mushaf._(riwaya, json['pages'] as int, suras, ayat, json['sourceSha1'] as String);
  }

  /// Ayat that start on [page], in order.
  List<Aya> ayatOnPage(int page) => ayat.sublist(_pageStarts[page], _pageStarts[page + 1]);

  Sura sura(int no) => suras[no - 1];

  /// The basmala printed above each sura, in this riwaya's own orthography.
  /// Taken from An-Naml 27:30, so it is never typed by hand.
  late final String basmala = () {
    final t = find(27, 30)!.bareText;
    return t.substring(t.indexOf('\u0628\u0650\u0633'));
  }();

  /// Al-Fatiha's first aya in Hafs is the basmala itself; in Warsh it is not counted.
  bool printsBasmala(int sura) => sura != 9 && !(sura == 1 && riwaya == Riwaya.hafs);

  int juzOfPage(int page) => ayatOnPage(page).first.juz;

  int firstPageOfJuz(int juz) => ayat.firstWhere((a) => a.juz == juz).page;

  Aya? find(int sura, int no) {
    if (sura < 1 || sura > suras.length || no < 1 || no > suras[sura - 1].ayatCount) return null;
    var start = 0;
    for (var s = 1; s < sura; s++) {
      start += suras[s - 1].ayatCount;
    }
    return ayat[start + no - 1];
  }

  /// The closest aya to ([sura], [no]) in this riwaya. The two counts differ,
  /// so an aya number from the other riwaya is clamped to this sura's length.
  Aya nearest(int sura, int no) {
    final s = this.sura(sura);
    return find(sura, no.clamp(1, s.ayatCount))!;
  }

  List<Aya> search(String query, {int limit = 200}) {
    final q = normalizeArabic(query);
    if (q.length < 2) return const [];
    final out = <Aya>[];
    for (final a in ayat) {
      if (a.searchText.contains(q) || a.searchTextAlef.contains(q)) {
        out.add(a);
        if (out.length >= limit) break;
      }
    }
    return out;
  }
}

final _marks = RegExp(
    '[ؐ-ًؚ-ٰٟۖ-ۭ࣓-ࣿـ ‏۞۩٠-٩]');

/// Strips diacritics and Quranic marks and unifies letter forms so that a
/// query typed on a normal keyboard matches the Uthmani text.
String normalizeArabic(String input) {
  var s = input.replaceAll(_marks, '');
  s = s
      .replaceAll(RegExp('[آأإٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ے', 'ي')
      .replaceAll('ئ', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ة', 'ه');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
