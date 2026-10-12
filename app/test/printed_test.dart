import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf/data/printed.dart';
import 'package:mushaf/data/quran.dart';

PrintedIndex _index(Riwaya r) => PrintedIndex.parse(File('assets/pages/${r.name}.json').readAsStringSync());

void main() {
  test('every riwaya has 604 indexed pages covering all its ayat', () {
    for (final r in Riwaya.values) {
      final text = Mushaf.parse(r, File('assets/quran/${r.name}.json').readAsStringSync());
      final index = _index(r);
      expect(index.pages.length, 604, reason: r.name);
      final regions = {for (final p in index.pages) for (final a in p) (a.sura, a.aya)};
      final ayat = {for (final a in text.ayat) (a.sura, a.no)};
      // Ad-Duri's artwork counts one aya more than the KFGQPC text data.
      expect(ayat.difference(regions), isEmpty, reason: r.name);
      expect(regions.difference(ayat).length, lessThanOrEqualTo(1), reason: r.name);
    }
  });

  test('a touch on a printed line finds its aya', () {
    final warsh = _index(Riwaya.warsh);
    // Warsh page 50 opens Al Imran; its first aya fills the right of the first line.
    final hit = warsh.hit(50, const Offset(300, 100))!;
    expect((hit.sura, hit.aya), (3, 1));
    // Aya 2 starts at the end of that line and takes the whole next one.
    final next = warsh.hit(50, const Offset(50, 140))!;
    expect((next.sura, next.aya), (3, 2));
    expect(warsh.hit(50, const Offset(-100, -100)), isNull);
  });

  test('the opening pages use point-list regions', () {
    final hafs = _index(Riwaya.hafs);
    expect(hafs.regionsOn(1).first.rings.single.length, 4);
    expect(hafs.regionsOn(1).length, 7);
  });

  test('downloaded pages are read back and decoded', () async {
    final root = await Directory.systemTemp.createTemp('pages');
    addTearDown(() => root.delete(recursive: true));
    final store = PageStore(root: () async => root);
    final dir = Directory('${root.path}/pages/warsh')..createSync(recursive: true);
    for (var p = 1; p <= PageStore.pageCount; p++) {
      File('test/fixtures/page.svg.br').copySync('${dir.path}/${p.toString().padLeft(3, '0')}.svg.br');
    }
    await store.scan();
    expect(store.state(Riwaya.warsh), PackState.ready);
    expect(store.state(Riwaya.hafs), PackState.absent);
    expect(await store.svg(Riwaya.warsh, 50), contains('viewBox="-6 0 345 550"'));
    await store.delete(Riwaya.warsh);
    expect(store.state(Riwaya.warsh), PackState.absent);
    expect(dir.existsSync(), isFalse);
  });
}
