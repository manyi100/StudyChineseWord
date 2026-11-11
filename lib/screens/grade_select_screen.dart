import 'package:flutter/material.dart';
import '../models/hanzi_model.dart';
import '../models/hanzi_course.dart';
import '../services/hanzi_repository.dart';
import '../services/progress_service.dart';
import '../services/storage_service.dart';
import 'course_list_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await HanziRepository.instance.ensureLoaded();
    final viewedIds = await StorageService.instance.getViewedIds();
    final unlockedGradeIds = await ProgressService.getUnlockedGradeIds();

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
      _unlockedTotal = list
          .where((p) => p.isUnlocked)
          .fold(0, (sum, p) => sum + p.total);
      _isLoading = false;
    });
  }

  Future<void> _enterStage(int stageId) async {
    StorageService.instance.saveLastGradeId(stageId);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseListScreen(stageId: stageId)),
    );
    _load();
  }

  void _onLockedTap(_GradeProgress progress) {
    final prevName = gradeInfoList
        .firstWhere((g) => g.id == progress.info.id - 1)
        .name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('请先学完"$prevName"的全部字，才能解锁"${progress.info.name}"哦'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择学习阶段'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            '720 字按由易到难分为 6 个阶段，每阶段 30 课、每课 4 字；'
            '共学完 $_learnedAll / $_totalAll 字',
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SegmentedButton<_BrowseMode>(
            segments: const [
              ButtonSegment(
                value: _BrowseMode.theme,
                label: Text('按主题'),
              ),
              ButtonSegment(
                value: _BrowseMode.radical,
                label: Text('按部首'),
              ),
              ButtonSegment(
                value: _BrowseMode.stroke,
                label: Text('按笔画'),
              ),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
          const SizedBox(height: 16),
          ..._buildContent(),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
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
        ];
      case _BrowseMode.radical:
        return [
          Text(
            '共 ${_radicalGroups.length} 个部首，按字数从多到少排列',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ..._radicalGroups.map((group) => _RadicalRow(
                group: group,
                onTap: () => _openGrid(
                  '部首 · ${group.radical}',
                  'radical_${group.radical}',
                  group.chars,
                ),
              )),
        ];
      case _BrowseMode.stroke:
        return [
          Text(
            '笔画由少到多，适合零基础起步',
            style: const TextStyle(color: Colors.black45, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ..._strokeBands.map((band) => _StrokeBandCard(
                band: band,
                onTap: () => _openGrid(
                  '笔画 · ${band.label}',
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
                          Text(
                            progress.info.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: locked ? Colors.black45 : Colors.black87,
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
                        const Text(
                          '完成上一阶段后解锁',
                          style: TextStyle(fontSize: 12, color: Colors.black38),
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
                              '已学 ${progress.learned} / ${progress.total} 字 · '
                              '完成 ${progress.coursesDone} / ${progress.coursesTotal} 课',
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
                    const Text(
                      '已解锁阶段连续学',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '按顺序学习目前已解锁的$count字',
                      style: const TextStyle(fontSize: 13, color: Colors.white70),
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

class _RadicalRow extends StatelessWidget {
  final RadicalGroup group;
  final VoidCallback onTap;

  const _RadicalRow({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sample = group.chars.take(6).map((e) => e.char).join(' ');
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
                  group.radical,
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
                      '${group.chars.length} 字',
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
                  band.label.replaceAll('画', '\n画'),
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
                      '${band.chars.length} 字',
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
