import 'dart:convert';
import 'dart:ui' show Brightness, Color;

import 'package:flutter/services.dart' show rootBundle;

/// The rules coloured on the page, grouped the way printed tajweed Mushafs
/// colour them: shades of red for madd, green for ghunnah, blue for qalqalah,
/// grey for letters that are written but not pronounced.
enum TajweedColor {
  silent(Color(0xFF9A9A9A), Color(0xFF8A8F94)),
  madd2(Color(0xFFC09A2A), Color(0xFFD8B54A)),
  madd246(Color(0xFFE5791C), Color(0xFFF39A4A)),
  maddWajib(Color(0xFFD7262C), Color(0xFFF0585D)),
  madd6(Color(0xFF8E0F14), Color(0xFFD9403F)),
  ghunnah(Color(0xFF16924A), Color(0xFF4CC27A)),
  qalqalah(Color(0xFF1E6FD0), Color(0xFF5AA5F0));

  const TajweedColor(this.day, this.night);

  final Color day;
  final Color night;

  Color of(Brightness b) => b == Brightness.dark ? night : day;
}

/// Rule names as written by tools/build_tajweed.py, in its order.
const _ruleColors = {
  'hamzat_wasl': TajweedColor.silent,
  'silent': TajweedColor.silent,
  'lam_shamsiyyah': TajweedColor.silent,
  'madd_2': TajweedColor.madd2,
  'madd_246': TajweedColor.madd246,
  'madd_muttasil': TajweedColor.maddWajib,
  'madd_munfasil': TajweedColor.maddWajib,
  'madd_6': TajweedColor.madd6,
  'qalqalah': TajweedColor.qalqalah,
  'ghunnah': TajweedColor.ghunnah,
  'ikhfa': TajweedColor.ghunnah,
  'ikhfa_shafawi': TajweedColor.ghunnah,
  'iqlab': TajweedColor.ghunnah,
  'idghaam_ghunnah': TajweedColor.ghunnah,
  'idghaam_no_ghunnah': TajweedColor.silent,
  'idghaam_shafawi': TajweedColor.ghunnah,
  'idghaam_mutajanisayn': TajweedColor.silent,
  'idghaam_mutaqaribayn': TajweedColor.silent,
};

/// A coloured stretch of an aya's text, as UTF-16 offsets into [Aya.text].
class TajweedSpan {
  const TajweedSpan(this.color, this.start, this.end);

  final TajweedColor color;
  final int start;
  final int end;
}

/// Tajweed colouring for every aya of one riwaya, in the riwaya's own order.
class Tajweed {
  Tajweed._(this.ayat);

  final List<List<TajweedSpan>> ayat;

  static Future<Tajweed> load(String asset) async => parse(await rootBundle.loadString(asset));

  static Tajweed parse(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final rules = [for (final r in json['rules'] as List) _ruleColors[r]!];
    return Tajweed._([
      for (final aya in json['ayat'] as List)
        [
          for (final s in aya as List) TajweedSpan(rules[s[0] as int], s[1] as int, s[2] as int),
        ],
    ]);
  }

  /// Splits [text] into runs of one colour each (null where uncoloured).
  /// Where two rules overlap, the later one in the data wins.
  static List<(String, TajweedColor?)> runs(String text, List<TajweedSpan> spans) {
    final colors = List<TajweedColor?>.filled(text.length, null);
    for (final s in spans) {
      for (var i = s.start; i < s.end && i < text.length; i++) {
        colors[i] = s.color;
      }
    }
    final out = <(String, TajweedColor?)>[];
    var start = 0;
    for (var i = 1; i <= text.length; i++) {
      if (i == text.length || colors[i] != colors[start]) {
        out.add((text.substring(start, i), colors[start]));
        start = i;
      }
    }
    return out;
  }
}
