import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../globals.dart';
import '../generated/l10n.dart';

class HelpArticlesPage extends StatefulWidget {
  const HelpArticlesPage({super.key});

  @override
  State<HelpArticlesPage> createState() => _HelpArticlesPageState();
}

class _HelpArticlesPageState extends State<HelpArticlesPage> {
  List<Map<String, dynamic>> crops = [];
  String searchQuery = '';
  bool isLoading = false;
  String? errorMsg;
  String? selectedCropId;
  String? selectedCropTitle;
  String article = '';

  @override
  void initState() {
    super.initState();
    loadManifest();
  }

  Future<void> loadManifest() async {
    final manifestStr = await rootBundle.loadString('assets/articles_manifest.json');
    final manifest = json.decode(manifestStr) as List;
    setState(() {
      crops = manifest.cast<Map<String, dynamic>>();
    });
  }

  Future<void> loadArticle(String cropId, String cropTitle, String lang) async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      selectedCropId = cropId;
      selectedCropTitle = cropTitle;
      article = '';
    });
    try {
      final data = await rootBundle.loadString('assets/articles/${cropId}_$lang.md');
      setState(() {
        article = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        article = '';
        errorMsg = S.of(context)!.articleMissing(cropTitle);
        isLoading = false;
      });
    }
  }

  void clearSelection() {
    setState(() {
      selectedCropId = null;
      selectedCropTitle = null;
      article = '';
      errorMsg = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
        final filteredCrops = crops.where((c) =>
          c['title'].toLowerCase().contains(searchQuery.toLowerCase())
        ).toList();

        if (selectedCropId != null) {
          return Scaffold(
            appBar: AppBar(
              title: Text(selectedCropTitle ?? ''),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: clearSelection,
              ),
            ),
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMsg != null
                    ? Center(child: Text(errorMsg!))
                    : article.isEmpty
                        ? Center(child: Text(S.of(context)!.noContent))
                        : Markdown(
                            data: article,
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                              p: const TextStyle(fontFamily: 'Segoe UI Variable Display'),
                            ),
                          ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context)!.cropGuides),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: S.of(context)!.searchHint,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (val) => setState(() => searchQuery = val),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filteredCrops.isEmpty
                    ? Center(child: Text(S.of(context)!.noCropsFound))
                    : ListView.builder(
                        itemCount: filteredCrops.length,
                        itemBuilder: (context, idx) {
                          final crop = filteredCrops[idx];
                          return ListTile(
                            leading: const Icon(Icons.grass),
                            title: Text(crop['title']),
                            onTap: () => loadArticle(crop['id'], crop['title'], lang),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
