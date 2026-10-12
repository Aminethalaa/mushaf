# المصحف · Mushaf

تطبيق مصحف للهاتف والتابلت بروايتي ورش عن نافع وحفص عن عاصم، مع واجهة واب ومزامنة للورد اليومي في مراحل لاحقة.

المواصفات الكاملة: [مواصفات تطبيق المصحف](https://claude.ai/code/artifact/0afd7dc8-66dc-4f5e-b255-d5e631456c70)

## المرحلة الأولى: القارئ (هذا المستودع الآن)

- المصحف كاملاً بالروايتين، 604 صفحة لكل رواية، يعمل دون اتصال.
- الصفحة مرسومة من النص بخط مجمع الملك فهد، وحجم الخط يُختار تلقائياً لتملأ الصفحة.
- صفحتان متقابلتان على التابلت في الوضع الأفقي.
- فهرس السور والأجزاء، بحث يتجاهل التشكيل، مفضلة بالضغط المطوّل على الآية، نسخ الآية.
- شاشة ترحيب تسأل عن الرواية واللغة (العربية أو الفرنسية)، ووضع ليلي.
- القراءة الحرة تُحفظ على الجهاز فقط. الورد والحسابات والمزامنة في المراحل 2 و3.

## Structure

| Path | What |
| --- | --- |
| `app/` | Flutter app (Android, iOS, web) |
| `app/assets/quran/{hafs,warsh}.json` | Text generated from the KFGQPC data, never edited by hand |
| `app/assets/fonts/` | KFGQPC Uthmanic fonts for each riwaya |
| `tools/build_quran_data.py` | Regenerates the assets from a checkout of the KFGQPC data |

## Text source

The text and fonts come from the King Fahd Glorious Quran Printing Complex
([developer page](https://qurancomplex.gov.sa/techquran/dev/)), via
[thetruetruth/quran-data-kfgqpc](https://github.com/thetruetruth/quran-data-kfgqpc):
Hafs data v18, Warsh data v10. The SHA-1 of each source file is stored in the asset.
The Complex states no licence on that page, so written permission is needed before a store release.

To regenerate:

```sh
git clone --depth 1 https://github.com/thetruetruth/quran-data-kfgqpc /tmp/kfgqpc
python3 tools/build_quran_data.py /tmp/kfgqpc
```

## Develop

```sh
cd app
flutter pub get
flutter test      # checks aya counts (6236 / 6214), the 604 pages, search, riwaya switching
flutter run
```
