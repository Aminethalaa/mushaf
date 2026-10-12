import 'package:flutter/widgets.dart';

import 'data/quran.dart';
import 'data/tajweed.dart';

/// Interface strings in Arabic and French. The Quran text itself is never translated.
class S {
  const S(this.code);

  final String code;

  static S of(BuildContext context) => S(Localizations.localeOf(context).languageCode);

  bool get ar => code == 'ar';

  String _t(String ar, String fr) => this.ar ? ar : fr;

  String get appName => _t('المصحف', 'Mushaf');
  String get welcome => _t('أهلاً بك', 'Bienvenue');
  String get chooseRiwaya => _t('بأي رواية تقرأ؟', 'Quelle riwaya lisez-vous ?');
  String get chooseLanguage => _t('لغة الواجهة', "Langue de l'interface");
  String get changeLater => _t('يمكنك تغيير ذلك لاحقاً من الإعدادات.', 'Vous pourrez le changer plus tard dans les réglages.');
  String get start => _t('ابدأ', 'Commencer');
  String get continueReading => _t('تابع القراءة', 'Reprendre la lecture');
  String get suras => _t('السور', 'Sourates');
  String get ajza => _t('الأجزاء', 'Juz');
  String get bookmarks => _t('المفضلة', 'Favoris');
  String get noBookmarks => _t('لا توجد مفضلة بعد. اضغط مطولاً على آية لإضافتها.', "Aucun favori. Appuyez longuement sur un verset pour l'ajouter.");
  String get search => _t('بحث', 'Recherche');
  String get searchHint => _t('ابحث في نص المصحف', 'Rechercher dans le texte');
  String get noResults => _t('لا نتائج', 'Aucun résultat');
  String get settings => _t('الإعدادات', 'Réglages');
  String get nightMode => _t('الوضع الليلي', 'Mode nuit');
  String get language => _t('اللغة', 'Langue');
  String get riwayaLabel => _t('الرواية', 'Riwaya');
  String get copy => _t('نسخ الآية', 'Copier le verset');
  String get copied => _t('نُسخت الآية', 'Verset copié');
  String get addBookmark => _t('أضف إلى المفضلة', 'Ajouter aux favoris');
  String get removeBookmark => _t('احذف من المفضلة', 'Retirer des favoris');
  String get switchRiwaya => _t('بدّل الرواية', 'Changer de riwaya');
  String get localOnly => _t('القراءة الحرة تُحفظ على هذا الجهاز فقط.', 'La lecture libre reste sur cet appareil.');
  String get tajweed => _t('ألوان التجويد', 'Couleurs du tajwid');
  String get tajweedHint => _t('متاحة لرواية حفص. ألوان ورش تنتظر مصدراً مرخّصاً.',
      'Disponibles pour Ḥafṣ. Celles de Warsh attendent une source sous licence.');
  String get tajweedSource => _t(
      'أحكام التجويد مستخرجة آلياً بقواعد مشروع quran-tajweed (رخصة CC BY 4.0).',
      'Règles de tajwid calculées avec les arbres du projet quran-tajweed (licence CC BY 4.0).');
  String tajweedColor(TajweedColor c) => switch (c) {
        TajweedColor.silent => _t('لا يُلفظ: همزة الوصل، اللام الشمسية، الإدغام بلا غنة', 'Non prononcé : hamzat al-waṣl, lām shamsiyya, idghām sans ghunna'),
        TajweedColor.madd2 => _t('مدّ حركتين', 'Madd de 2 temps'),
        TajweedColor.madd246 => _t('مدّ جائز ٢ أو ٤ أو ٦', 'Madd permis : 2, 4 ou 6 temps'),
        TajweedColor.maddWajib => _t('مدّ واجب أو منفصل ٤ أو ٥', 'Madd obligatoire ou séparé : 4 ou 5 temps'),
        TajweedColor.madd6 => _t('مدّ لازم ٦ حركات', 'Madd nécessaire : 6 temps'),
        TajweedColor.ghunnah => _t('غنّة، إخفاء، إقلاب، إدغام بغنّة', 'Ghunna, ikhfāʾ, iqlāb, idghām avec ghunna'),
        TajweedColor.qalqalah => _t('قلقلة', 'Qalqala'),
      };
  String get sourceNote => _t('النص من مجمع الملك فهد لطباعة المصحف الشريف.', "Texte du Complexe du Roi Fahd pour l'impression du Coran.");

  String riwaya(Riwaya r) => switch (r) {
        Riwaya.warsh => _t('ورش عن نافع', 'Warsh ʿan Nāfiʿ'),
        Riwaya.hafs => _t('حفص عن عاصم', 'Ḥafṣ ʿan ʿĀṣim'),
        Riwaya.qalon => _t('قالون عن نافع', 'Qālūn ʿan Nāfiʿ'),
        Riwaya.douri => _t('الدوري عن أبي عمرو', 'Ad-Dūrī ʿan Abī ʿAmr'),
        Riwaya.shubah => _t('شعبة عن عاصم', 'Shuʿba ʿan ʿĀṣim'),
      };

  String page(int n) => _t('صفحة ${arNum(n)}', 'Page $n');
  String juz(int n) => _t('الجزء ${arNum(n)}', 'Juz $n');
  String ayatCount(int n) => _t('${arNum(n)} آية', '$n versets');
  String ayaRef(String sura, int aya) => _t('$sura، الآية ${arNum(aya)}', '$sura, verset $aya');
  String num(int n) => ar ? arNum(n) : '$n';
  String resultsCount(int n) => _t('${arNum(n)} نتيجة', '$n résultats');
}

String arNum(int n) =>
    n.toString().split('').map((d) => String.fromCharCode(0x0660 + int.parse(d))).join();
