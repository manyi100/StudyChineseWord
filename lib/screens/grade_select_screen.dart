import 'package:flutter/material.dart';
import '../models/hanzi_model.dart';
import '../services/hanzi_repository.dart';
import '../services/progress_service.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

/// 年级选择页：App的默认首页。6个年级按由简单到复杂排列，
/// 每个年级显示学习进度，且必须学完上一年级（浏览过该年级全部字）
/// 才能解锁下一年级；第一年级始终解锁。
class GradeSelectScreen extends StatefulWidget {
  const GradeSelectScreen({super.key});

  @override
  State<GradeSelectScreen> createState() => _GradeSelectScreenState();
}

class _GradeProgress {
  final GradeInfo info;
  final int total;
  final int learned;
  final bool isUnlocked;

  _GradeProgress({
    required this.info,
    required this.total,
    required this.learned,
    required this.isUnlocked,
  });

  bool get isCompleted => total > 0 && learned >= total;
  double get ratio => total == 0 ? 0 : learned / total;
}

class _GradeSelectScreenState extends State<GradeSelectScreen> {
  bool _isLoading = true;
  List<_GradeProgress> _progressList = [];
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
      final total = chars.length;
      final learned = chars.where((h) => viewedIds.contains(h.id)).length;
      list.add(_GradeProgress(
        info: grade,
        total: total,
        learned: learned,
        isUnlocked: unlockedGradeIds.contains(grade.id),
      ));
    }

    setState(() {
      _progressList = list;
      _totalAll = HanziRepository.instance.all.length;
      _learnedAll = viewedIds.length;
      _unlockedTotal = list
          .where((p) => p.isUnlocked)
          .fold(0, (sum, p) => sum + p.total);
      _isLoading = false;
    });
  }

  void _enterGrade(int gradeId) {
    StorageService.instance.saveLastGradeId(gradeId);
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => HomeScreen(gradeId: gradeId)))
        .then((_) => _load()); // 从学习页返回后刷新进度显示
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('选择学习年级'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '720字按年级由简单到复杂均分为6个年级，共学完$_learnedAll / $_totalAll字',
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ..._progressList.map((p) => _GradeCard(
                progress: p,
                onTap: () =>
                    p.isUnlocked ? _enterGrade(p.info.id) : _onLockedTap(p),
              )),
          const SizedBox(height: 8),
          _AllGradesCard(
            count: _unlockedTotal,
            onTap: () => _enterGrade(0), // 0 代表"已解锁年级连续学"
          ),
        ],
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  final _GradeProgress progress;
  final VoidCallback onTap;

  const _GradeCard({required this.progress, required this.onTap});

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
              border: Border.all(color: Colors.black.withOpacity(0.06)),
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
                          '完成上一年级后解锁',
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
                              '已学 ${progress.learned} / ${progress.total} 字',
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
                      '已解锁年级连续学',
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
