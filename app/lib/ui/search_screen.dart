import 'package:flutter/material.dart';

import '../data/quran.dart';
import '../l10n.dart';
import 'home_screen.dart';

/// Searches the bundled text with no network: diacritics and letter forms are
/// ignored, so «الرحمن» finds «ٱلرَّحۡمَٰنِ».
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.mushaf});

  final Mushaf mushaf;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Aya> _results = const [];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final m = widget.mushaf;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const ValueKey('search-field'),
          autofocus: true,
          textDirection: TextDirection.rtl,
          decoration: InputDecoration(hintText: s.searchHint, border: InputBorder.none),
          onChanged: (q) => setState(() {
            _query = q;
            _results = m.search(q);
          }),
        ),
      ),
      body: _query.trim().length < 2
          ? const SizedBox.shrink()
          : _results.isEmpty
          ? Center(child: Text(s.noResults))
          : ListView.separated(
              itemCount: _results.length + 1,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(padding: const EdgeInsets.all(12), child: Text(s.resultsCount(_results.length)));
                }
                final a = _results[i - 1];
                return ListTile(
                  title: Text(
                    a.text,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: m.riwaya.fontFamily, fontSize: 20, height: 1.9),
                  ),
                  subtitle: Text('${s.ayaRef(m.sura(a.sura).nameAr, a.no)} · ${s.page(a.page)}'),
                  onTap: () => HomeScreen.open(context, m, a.page, focus: a),
                );
              },
            ),
    );
  }
}
