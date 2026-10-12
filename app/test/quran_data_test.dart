import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/data/quran.dart';

Mushaf _load(Riwaya r) => Mushaf.parse(r, File('assets/quran/${r.name}.json').readAsStringSync());

void main() {
  final hafs = _load(Riwaya.hafs);
  final warsh = _load(Riwaya.warsh);

  test('aya counts match each riwaya', () {
    expect(hafs.ayat.length, 6236);
    expect(warsh.ayat.length, 6214);
  });

  test('both have 114 suras whose aya counts add up', () {
    for (final m in [hafs, warsh]) {
      expect(m.suras.length, 114);
      expect(m.suras.fold<int>(0, (n, s) => n + s.ayatCount), m.ayat.length);
      expect(m.sura(2).ayatCount, m.riwaya == Riwaya.hafs ? 286 : 285);
    }
  });

  test('every one of the 604 pages has ayat, in order', () {
    for (final m in [hafs, warsh]) {
      expect(m.pageCount, 604);
      var previous = -1;
      for (var p = 1; p <= 604; p++) {
        final ayat = m.ayatOnPage(p);
        expect(ayat, isNotEmpty, reason: '${m.riwaya.name} page $p');
        expect(ayat.first.index, greaterThan(previous));
        previous = ayat.last.index;
      }
      expect(previous, m.ayat.length - 1);
    }
  });

  test('30 juz, each starting on a later page', () {
    for (final m in [hafs, warsh]) {
      var page = 0;
      for (var j = 1; j <= 30; j++) {
        expect(m.firstPageOfJuz(j), greaterThan(page));
        page = m.firstPageOfJuz(j);
      }
    }
  });

  test('basmala comes from the text of each riwaya', () {
    expect(hafs.basmala, startsWith('بِسۡمِ'));
    expect(warsh.basmala, startsWith('بِسْمِ'));
    expect(hafs.printsBasmala(1), isFalse);
    expect(warsh.printsBasmala(1), isTrue);
    expect(warsh.printsBasmala(9), isFalse);
  });

  test('search ignores diacritics and letter forms', () {
    expect(hafs.search('الرحمن الرحيم').first.sura, 1);
    expect(warsh.search('الحمد لله رب العالمين').first.sura, 1);
    expect(hafs.search('ا'), isEmpty);
    expect(warsh.search('قل هو الله احد').first.sura, 112);
  });

  test('switching riwaya keeps the place', () {
    final a = hafs.find(2, 286)!;
    expect(warsh.nearest(a.sura, a.no).no, 285);
    expect(warsh.nearest(18, 1).page, warsh.sura(18).page);
  });

  test('copied text drops the aya number', () {
    expect(hafs.find(112, 1)!.bareText.contains('١'), isFalse);
  });
}
