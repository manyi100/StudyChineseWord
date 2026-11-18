import 'package:flutter/material.dart';
import '../app_route_observer.dart';
import '../l10n/app_strings.dart';
import '../models/hanzi_course.dart';
import '../services/hanzi_repository.dart';
import '../services/storage_service.dart';
import '../widgets/content_frame.dart';
import 'home_screen.dart';

/// 阶段课程列表：每个阶段 30 课，每课 4 个主题相近的汉字。
/// 课程卡片显示 4 个字和完成进度，点击进入该课的左右翻页学习。
class CourseListScreen extends StatefulWidget {
  final int stageId;

  const CourseListScreen({super.key, required this.stageId});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> with RouteAware {
  bool _isLoading = true;
  List<HanziCourse> _courses = [];
  Set<String> _viewedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) appRouteObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  /// 从学习页回到列表时刷新进度。
  ///
  /// 只靠 `_openCourseAt` 里 `await push` 之后的 `_load()` 不够：学完一课继续
  /// 左滑进下一课用的是 `pushReplacement`，会让那个 await 提前完成；之后按
  /// 返回时列表不会再刷新，刚学的那一课仍显示「0 / 4 字」，要再进一次才更新。
  @override
  void didPopNext() {
    _load();
  }

  Future<void> _load() async {
    await HanziRepository.instance.ensureLoaded();
    final viewed = await StorageService.instance.getViewedIds();
    if (!mounted) return;
    setState(() {
      _courses = HanziRepository.instance.coursesForGrade(widget.stageId);
      _viewedIds = viewed;
      _isLoading = false;
    });
  }

  Widget _courseStudy(
    int index, {
    bool startAtLast = false,
    bool startAtFirst = false,
  }) {
    final course = _courses[index];
    return HomeScreen(
      chars: course.chars,
      lessonNumber: course.indexInStage,
      progressKey: 'course_${course.groupId}',
      // 跨课滑动要落在边界字上：
      // 左滑进下一课 → 它的第一个字（不沿用该课上次停下的位置，
      // 否则常停在最后一个字，再划一下又会直接跳到下一课）；
      // 右滑回上一课 → 它的最后一个字，和「左滑进下一课」对称。
      initialIndex:
          startAtLast ? course.chars.length - 1 : (startAtFirst ? 0 : null),
      // 一课学完后继续左滑，直接替换为下一课
      onFinished: index + 1 < _courses.length
          ? () => _replaceWithCourse(index + 1, startAtFirst: true)
          : null,
      // 在本课第一页继续右滑，回到上一课的最后一个字
      onRewind: index > 0
          ? () => _replaceWithCourse(index - 1, startAtLast: true)
          : null,
    );
  }

  Future<void> _openCourseAt(int index) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _courseStudy(index)),
    );
    _load();
  }

  void _replaceWithCourse(
    int index, {
    bool startAtLast = false,
    bool startAtFirst = false,
  }) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => _courseStudy(
          index,
          startAtLast: startAtLast,
          startAtFirst: startAtFirst,
        ),
      ),
    );
  }

  Future<void> _openContinuous() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeScreen(gradeId: widget.stageId),
      ),
    );
    _load();
  }

  int get _learnedTotal =>
      _courses.fold(0, (sum, c) => sum + c.learnedCount(_viewedIds));

  int get _totalChars => _courses.fold(0, (sum, c) => sum + c.chars.length);

  int get _completedCourses =>
      _courses.where((c) => c.isCompleted(_viewedIds)).length;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final s = context.s;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.courseListTitle(widget.stageId)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: ContentFrame(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: _courses.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) return _buildHeader();
            if (index == _courses.length + 1) return _buildContinuousCard();
            final course = _courses[index - 1];
            return _CourseCard(
              course: course,
              viewedIds: _viewedIds,
              onTap: () => _openCourseAt(index - 1),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.courseListIntro(
              _learnedTotal,
              _totalChars,
              _courses.length,
              _completedCourses,
            ),
            style: const TextStyle(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _totalChars == 0 ? 0 : _learnedTotal / _totalChars,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinuousCard() {
    final s = context.s;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _openContinuous,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.all_inclusive_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    s.continuousStage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final HanziCourse course;
  final Set<String> viewedIds;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.viewedIds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final completed = course.isCompleted(viewedIds);
    final learned = course.learnedCount(viewedIds);
    final s = context.s;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: completed ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: completed
                        ? const Color(0xFFFFE0B2)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: completed
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFFFF9800))
                      : Text(
                          '${course.indexInStage}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.courseLabel(course.indexInStage),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              completed
                                  ? s.courseDone
                                  : s.courseProgress(
                                      learned, course.chars.length),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: completed
                                    ? const Color(0xFFFF9800)
                                    : Colors.black38,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: course.chars
                            .map((h) => Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: Text(
                                    h.char,
                                    style: const TextStyle(
                                      fontFamily: 'KaiTiCustom',
                                      fontSize: 26,
                                      height: 1.0,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
