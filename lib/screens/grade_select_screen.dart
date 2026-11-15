import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/hanzi_model.dart';
import '../models/hanzi_course.dart';
import '../services/hanzi_repository.dart';
import '../services/progress_service.dart';
import '../services/storage_service.dart';
import '../widgets/content_frame.dart';
import '../widgets/language_button.dart';
import '../widgets/onboarding_dialog.dart';
import 'course_list_screen.dart';
import 'favorites_screen.dart';
import 'hanzi_grid_screen.dart';
import 'home_screen.dart';

/// 首页（学习入口）：
/// - 按主题：6 个阶段，每阶段 30 课、每课 4 个主题相近的字；
/// - 按部首：按部首集中识字（木 41 字、氵 38 字…）；
/// - 按笔画：由易到难，1~3 画起步。
/// 阶段解锁规则保持原有逻辑：学完上一阶段全部字后解锁下一阶段。
class GradeSelectScreen extends StatefulWidget {
  const GradeSelectScreen({super.key});

  @override
  State<GradeSelectScreen> createState() => _GradeSelectScreenState();
}

enum _BrowseMode { theme, radical, stroke }

class _GradeProgress {
  final GradeInfo info;
  final int total;
  final int learned;
  final int coursesTotal;
  final int coursesDone;
  final bool isUnlocked;

  _GradeProgress({
    required this.info,
    required this.total,
    required this.learned,
    required this.coursesTotal,
    required this.coursesDone,
    required this.isUnlocked,
  });

  bool get isCompleted => total > 0 && learned >= total;
  double get ratio => total == 0 ? 0 : learned / total;
}

class _GradeSelectScreenState extends State<GradeSelectScreen> {
  bool _isLoading = true;
  _BrowseMode _mode = _BrowseMode.theme;
  List<_GradeProgress> _progressList = [];
  List<RadicalGroup> _radicalGroups = [];
  List<StrokeBand> _strokeBands = [];
  int _totalAll = 0;
  int _learnedAll = 0;
  int _unlockedTotal = 0;
  int _favoriteCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
    // 首次启动自动展示四页使用说明；看过一次后不再打扰，可随时点右上角「?」重看
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingDialog.showIfNeeded(context);
    });
  }

  Future<void> _load() async {
    await HanziRepository.instance.ensureLoaded();
    final viewedIds = await StorageService.instance.getViewedIds();
    final unlockedGradeIds = await ProgressService.getUnlockedGradeIds();
    final favorites = await StorageService.instance.getFavoriteIds();

    final list = <_GradeProgress>[];
    for (final grade in gradeInfoList) {
      final chars = HanziRepository.instance.forGrade(grade.id);
      final courses = HanziRepository.instance.coursesForGrade(grade.id);
      list.add(_GradeProgress(
        info: grade,
        total: chars.length,
        learned: chars.where((h) => viewedIds.contains(h.id)).length,
        coursesTotal: courses.length,
        coursesDone: courses.where((c) => c.isCompleted(viewedIds)).length,
        isUnlocked: unlockedGradeIds.contains(grade.id),
      ));
    }

    if (!mounted) return;
    setState(() {
      _progressList = list;
      _radicalGroups = HanziRepository.instance.radicalGroups;
      _strokeBands = HanziRepository.instance.strokeBands;
      _totalAll = HanziRepository.instance.all.length;
      _learnedAll = viewedIds.length;
      _favoriteCount = favorites.length;
      _unlockedTotal =
          list.where((p) => p.isUnlocked).fold(0, (sum, p) => sum + p.total);
      _isLoading = false;
    });
  }

  Future<void> _openFavorites() async {
    final favorites = await StorageService.instance.getFavoriteIds();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FavoritesScreen(
          allHanzi: HanziRepository.instance.all,
          favoriteIds: favorites,
          onToggleFavorite: (id) async {
            final current = await StorageService.instance.getFavoriteIds();
            if (!current.add(id)) current.remove(id);
            await StorageService.instance.saveFavoriteIds(current);
          },
        ),
      ),
    );
    _load();
  }

  Future<void> _enterStage(int stageId) async {
    StorageService.instance.saveLastGradeId(stageId);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseListScreen(stageId: stageId)),
    );
    _load();
  }

  void _onLockedTap(_GradeProgress progress) {
    final s = context.s;
    final prevName = s.stageName(progress.info.id - 1);
    final currentName = s.stageName(progress.info.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.lockedMessage(prevName, currentName)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openGrid(String title, String progressKey, List<HanziModel> chars) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HanziGridScreen(
          title: title,
          progressKey: progressKey,
          chars: chars,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final s = context.s;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.homeTitle),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            tooltip: s.onboardingBtnHelp,
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => OnboardingDialog.showModal(context),
          ),
          const LanguageButton(),
        ],
      ),
      // 平板 / 横屏时内容居中，避免卡片被拉得过宽
      body: ContentFrame(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Text(
              s.homeIntro(_learnedAll, _totalAll),
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
            const SizedBox(height: 14),
            SegmentedButton<_BrowseMode>(
              segments: [
                ButtonSegment(
                  value: _BrowseMode.theme,
                  label: Text(s.byTheme),
                ),
                ButtonSegment(
                  value: _BrowseMode.radical,
                  label: Text(s.byRadical),
                ),
                ButtonSegment(
                  value: _BrowseMode.stroke,
                  label: Text(s.byStrokes),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
              },
            ),
            const SizedBox(height: 16),
            ..._buildContent(s),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(AppStrings s) {
    switch (_mode) {
      case _BrowseMode.theme:
        return [
          ..._progressList.map((p) => _StageCard(
                progress: p,
                onTap: () =>
                    p.isUnlocked ? _enterStage(p.info.id) : _onLockedTap(p),
              )),
          _AllGradesCard(
            count: _unlockedTotal,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(gradeId: 0),
                ),
              );
              _load();
            },
          ),
          const SizedBox(height: 12),
          _FavoritesCard(count: _favoriteCount, onTap: _openFavorites),
        ];
      case _BrowseMode.radical:
        return [
          Text(
            s.radicalIntro(_radicalGroups.length),
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ..._radicalGroups.map((group) => _RadicalRow(
                group: group,
                onTap: () => _openGrid(
                  s.radicalTitle(group.radical),
                  'radical_${group.radical}',
                  group.chars,
                ),
              )),
        ];
      case _BrowseMode.stroke:
        return [
          Text(
            s.strokeIntro,
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ..._strokeBands.map((band) => _StrokeBandCard(
                band: band,
                onTap: () => _openGrid(
                  s.strokeTitle(s.strokeBandLabel(
                    band.label,
                    band.minStrokes,
                    band.maxStrokes,
                  )),
                  'stroke_${band.minStrokes}',
                  band.chars,
                ),
              )),
        ];
    }
  }
}

class _StageCard extends StatelessWidget {
  final _GradeProgress progress;
  final VoidCallback onTap;

  const _StageCard({required this.progress, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = !progress.isUnlocked;
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: locked ? Colors.grey.shade100 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: locked
                        ? Colors.grey.shade300
                        : (progress.isCompleted
                            ? const Color(0xFFFFF3E0)
                            : const Color(0xFFE8F5E9)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: locked
                      ? const Icon(Icons.lock_rounded,
                          color: Colors.grey, size: 24)
                      : Text(
                          '${progress.info.id}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: progress.isCompleted
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF4CAF50),
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.stageName(progress.info.id),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: locked ? Colors.black45 : Colors.black87,
                              ),
                            ),
                          ),
                          if (progress.isCompleted) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFFFF9800), size: 18),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (locked)
                        Text(
                          s.stageLockedHint,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black38),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.ratio,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                color: progress.isCompleted
                                    ? const Color(0xFFFF9800)
                                    : const Color(0xFF4CAF50),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.stageProgress(
                                progress.learned,
                                progress.total,
                                progress.coursesDone,
                                progress.coursesTotal,
                              ),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : Icons.chevron_right_rounded,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AllGradesCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _AllGradesCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Material(
      color: const Color(0xFF4CAF50),
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.all_inclusive_rounded, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.allStagesTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.allStagesSubtitle(count),
                      style:
                          const TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FavoritesCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star_rounded,
                    color: Color(0xFFFFB300), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.favoritesTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      s.favoritesSubtitle(count),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadicalRow extends StatelessWidget {
  final RadicalGroup group;
  final VoidCallback onTap;

  const _RadicalRow({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sample = group.chars.take(6).map((e) => e.char).join(' ');
    final s = context.s;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.radicalLabel(group.radical),
                  style: const TextStyle(
                    fontFamily: 'KaiTiCustom',
                    fontSize: 22,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.charCount(group.chars.length),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sample,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrokeBandCard extends StatelessWidget {
  final StrokeBand band;
  final VoidCallback onTap;

  const _StrokeBandCard({required this.band, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sample = band.chars.take(10).map((e) => e.char).join(' ');
    final s = context.s;
    final bandLabel = s.strokeBandLabel(
      band.label,
      band.minStrokes,
      band.maxStrokes,
    );
    final labelText = s.strokeBandMultiline(bandLabel);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labelText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1976D2),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.charCount(band.chars.length),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sample,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
