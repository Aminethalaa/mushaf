import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/quran.dart';

/// A saved place in the Mushaf. Stored by sura and aya so it survives a
/// change of riwaya.
class Bookmark {
  const Bookmark(this.riwaya, this.sura, this.aya);

  final Riwaya riwaya;
  final int sura;
  final int aya;

  String encode() => '${riwaya.name}:$sura:$aya';

  static Bookmark? decode(String s) {
    final p = s.split(':');
    if (p.length != 3) return null;
    final r = Riwaya.values.where((r) => r.name == p[0]);
    final sura = int.tryParse(p[1]);
    final aya = int.tryParse(p[2]);
    if (r.isEmpty || sura == null || aya == null) return null;
    return Bookmark(r.first, sura, aya);
  }

  @override
  bool operator ==(Object other) =>
      other is Bookmark && other.riwaya == riwaya && other.sura == sura && other.aya == aya;

  @override
  int get hashCode => Object.hash(riwaya, sura, aya);
}

/// Everything in phase 1 is stored on the device only. Free reading never
/// leaves the device, by design; the wird and sync arrive in later phases.
class Settings extends ChangeNotifier {
  Settings(this._prefs);

  final SharedPreferences _prefs;

  static Future<Settings> load() async => Settings(await SharedPreferences.getInstance());

  bool get onboarded => _prefs.getBool('onboarded') ?? false;

  Riwaya get riwaya =>
      Riwaya.values.firstWhere((r) => r.name == _prefs.getString('riwaya'), orElse: () => Riwaya.warsh);

  String get language => _prefs.getString('language') ?? 'ar';

  bool get night => _prefs.getBool('night') ?? false;

  /// Show the printed Madinah pages instead of text pages, for each riwaya
  /// whose pages are on the device.
  bool get printed => _prefs.getBool('printed') ?? false;

  Future<void> setPrinted(bool value) async {
    await _prefs.setBool('printed', value);
    notifyListeners();
  }

  /// Tajweed colours, for the riwayat that have them (Hafs for now).
  bool get tajweed => _prefs.getBool('tajweed') ?? true;

  int lastPage(Riwaya r) => _prefs.getInt('lastPage.${r.name}') ?? 1;

  List<Bookmark> get bookmarks =>
      (_prefs.getStringList('bookmarks') ?? const []).map(Bookmark.decode).whereType<Bookmark>().toList();

  Future<void> completeOnboarding({required Riwaya riwaya, required String language}) async {
    await _prefs.setString('riwaya', riwaya.name);
    await _prefs.setString('language', language);
    await _prefs.setBool('onboarded', true);
    notifyListeners();
  }

  Future<void> setRiwaya(Riwaya r) async {
    await _prefs.setString('riwaya', r.name);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    await _prefs.setString('language', code);
    notifyListeners();
  }

  Future<void> setNight(bool value) async {
    await _prefs.setBool('night', value);
    notifyListeners();
  }

  Future<void> setTajweed(bool value) async {
    await _prefs.setBool('tajweed', value);
    notifyListeners();
  }

  Future<void> setLastPage(Riwaya r, int page) => _prefs.setInt('lastPage.${r.name}', page);

  bool isBookmarked(Bookmark b) => bookmarks.contains(b);

  Future<void> toggleBookmark(Bookmark b) async {
    final list = bookmarks;
    list.contains(b) ? list.remove(b) : list.insert(0, b);
    await _prefs.setStringList('bookmarks', list.map((e) => e.encode()).toList());
    notifyListeners();
  }
}
