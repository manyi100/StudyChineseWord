import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/hanzi_model.dart';
import '../services/tts_service.dart';

/// 收藏复习页：展示用户标记过星标的字（跨年级共用同一份收藏列表），
/// 每条会显示所属年级，点击可朗读，点击星标可取消收藏。
class FavoritesScreen extends StatefulWidget {
  final List<HanziModel> allHanzi;
  final Set<String> favoriteIds;
  final void Function(String id) onToggleFavorite;

  const FavoritesScreen({
    super.key,
    required this.allHanzi,
    required this.favoriteIds,
    required this.onToggleFavorite,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Set<String> _localFavorites;

  @override
  void initState() {
    super.initState();
    _localFavorites = {...widget.favoriteIds};
  }

  String _gradeNameOf(BuildContext context, HanziModel h) =>
      context.s.stageName(h.gradeId);

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final favoriteList =
        widget.allHanzi.where((h) => _localFavorites.contains(h.id)).toList();

    return Scaffold(
      appBar: AppBar(title: Text(s.favoritesTitle)),
      body: favoriteList.isEmpty
          ? Center(
              child: Text(
                s.favoritesEmpty,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black45, fontSize: 15),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: favoriteList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final h = favoriteList[index];
                final wordsText = h.words.map((w) => w.text).join('  ');
                return Card(
                  elevation: 0,
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Text(h.char, style: const TextStyle(fontSize: 32)),
                    title: Row(
                      children: [
                        Text(h.pinyin),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _gradeNameOf(context, h),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF4CAF50)),
                          ),
                        ),
                      ],
                    ),
                    subtitle: wordsText.isEmpty ? null : Text(wordsText),
                    onTap: () => TtsService.instance.speak(h.char),
                    trailing: IconButton(
                      icon: const Icon(Icons.star_rounded, color: Colors.amber),
                      onPressed: () {
                        setState(() => _localFavorites.remove(h.id));
                        widget.onToggleFavorite(h.id);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
