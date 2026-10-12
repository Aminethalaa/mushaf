# المصحف · Mushaf

تطبيق مصحف للهاتف والتابلت بروايات ورش وقالون عن نافع، وحفص وشعبة عن عاصم، والدوري عن أبي عمرو، مع واجهة واب ومزامنة للورد اليومي في مراحل لاحقة.

المواصفات الكاملة: [مواصفات تطبيق المصحف](https://claude.ai/code/artifact/0afd7dc8-66dc-4f5e-b255-d5e631456c70)

## المرحلة الأولى: القارئ (هذا المستودع الآن)

- المصحف كاملاً بالروايات الخمس، 604 صفحة لكل رواية، يعمل دون اتصال.
- صفحات مصحف المدينة المطبوع كما هي (سطراً بسطر)، تُحمَّل لكل رواية عند الطلب (75 إلى 90 م.ب) ثم تعمل دون اتصال.
- الصفحة مرسومة من النص بخط مجمع الملك فهد، وحجم الخط يُختار تلقائياً لتملأ الصفحة.
- صفحتان متقابلتان على التابلت في الوضع الأفقي.
- فهرس السور والأجزاء، بحث يتجاهل التشكيل، مفضلة بالضغط المطوّل على الآية، نسخ الآية.
- ألوان التجويد لرواية حفص (تُطفأ من الإعدادات)، مع دليل الألوان. ورش بلا ألوان حتى يتوفر مصدر مرخّص.
- شاشة ترحيب تسأل عن الرواية واللغة (العربية أو الفرنسية)، ووضع ليلي.
- القراءة الحرة تُحفظ على الجهاز فقط. الورد والحسابات والمزامنة في المراحل 2 و3.

## Structure

| Path | What |
| --- | --- |
| `app/` | Flutter app (Android, iOS, web) |
| `app/assets/quran/<riwaya>.json` | Text generated from the KFGQPC data, never edited by hand |
| `app/assets/pages/<riwaya>.json` | Where each aya sits on the printed pages, generated |
| `app/assets/fonts/` | KFGQPC Uthmanic fonts for each riwaya |
| `app/assets/quran/hafs_tajweed.json` | Tajweed colouring of the Hafs text, generated |
| `tools/build_quran_data.py` | Regenerates the assets from a checkout of the KFGQPC data |
| `tools/build_tajweed.py` | Regenerates the Hafs tajweed colouring |
| `tools/build_page_index.py` | Regenerates the printed-page aya index |

## Text source

The text and fonts come from the King Fahd Glorious Quran Printing Complex
([developer page](https://qurancomplex.gov.sa/techquran/dev/)), via
[thetruetruth/quran-data-kfgqpc](https://github.com/thetruetruth/quran-data-kfgqpc):
Hafs v18, Warsh v10, Qalun v10, Ad-Duri v09, Shu'bah v08. The SHA-1 of each source file is stored in the asset.
The Complex states no licence on that page, so written permission is needed before a store release.

To regenerate:

```sh
git clone --depth 1 https://github.com/thetruetruth/quran-data-kfgqpc /tmp/kfgqpc
python3 tools/build_quran_data.py /tmp/kfgqpc
```

## Printed pages

The Madinah Mushaf pages of the five riwayat are the KFGQPC artwork as published in SVG by
[quran-ws/quran-svg](https://github.com/quran-ws/quran-svg). The Complex allows their free use in
software ([its terms](https://github.com/quran-ws/quran-svg/blob/main/LICENSE)); the aya regions
are CC BY 4.0. The app bundles only the aya regions and downloads each riwaya's Brotli-compressed
pages from that repository, pinned to one commit, when the reader asks for them.

```sh
git clone --depth 1 --filter=blob:none --sparse https://github.com/quran-ws/quran-svg /tmp/quran-svg
git -C /tmp/quran-svg sparse-checkout set $(for r in hafs warsh qalon douri shubah; do echo mushafs/$r/kfqc/json; done)
python3 tools/build_page_index.py /tmp/quran-svg
```

The Ad-Duri artwork counts 6218 ayat where the KFGQPC text data has 6217.

## Tajweed colours (Hafs)

The rules are the decision trees of [cpfair/quran-tajweed](https://github.com/cpfair/quran-tajweed)
(data under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), credited in the app's settings),
run on the KFGQPC Hafs text after rewriting its marks into the Tanzil conventions the trees
were trained on. The rule counts match that project's published data on 6222 of 6236 ayat.

```sh
git clone --depth 1 https://github.com/cpfair/quran-tajweed /tmp/quran-tajweed
python3 tools/build_tajweed.py /tmp/quran-tajweed
```

No open, licensed tajweed data exists for Warsh yet.

## Develop

```sh
cd app
flutter pub get
flutter test      # checks aya counts (6236 / 6214), the 604 pages, search, riwaya switching
flutter run
```
