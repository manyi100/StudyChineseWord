import 'dart:async';

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../models/hanzi_model.dart';
import '../services/hanzi_repository.dart';
import '../services/meaning_service.dart';
import '../services/progress_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/audio_feedback.dart';
import '../widgets/character_card.dart';
import '../widgets/content_frame.dart';

class HomeScreen extends StatefulWidget {
  /// gradeId = 0 表示"已解锁阶段连续学"，1~6 表示具体阶段。
  /// 传入 [chars] 时则直接学习给定的字列表（课程/部首/笔画分组共用）。
  final int gradeId;
  final List<HanziModel>? chars;
  final String? title;

  /// 课程学习时传入“本阶段第几课”，标题会随界面语言自动切换。
  final int? lessonNumber;
  final String? progressKey;
  final int? initialIndex;

  /// 本课 4 个字都学完后，继续左滑时触发（用于切到下一课）
  final VoidCallback? onFinished;

  const HomeScreen({
    super.key,
    this.gradeId = 0,
    this.chars,
    this.title,
    this.lessonNumber,
    this.progressKey,
    this.initialIndex,
    this.onFinished,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController? _pageController;
  Set<String> _favoriteIds = {};
  Set<String> _viewedIds = {};
  bool _isLoading = true;
  bool _nextTriggered = false;
  bool _dragStartedAtEnd = false;
  DateTime? _lastFinishHintAt;

  List<HanziModel> _hanziList = [];
  bool _showAudioHint = false;
  Timer? _audioHintTimer;

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  String get _progressKey => widget.progressKey ?? 'grade_${widget.gradeId}';

  Future<void> _restoreState() async {
    // 释义不阻塞首帧：后台加载，加载完成后释义行自己会刷新
    MeaningService.instance.ensureLoaded();
    await HanziRepository.instance.ensureLoaded();

    final explicitChars = widget.chars;
    if (explicitChars != null) {
      _hanziList = explicitChars;
    } else if (widget.gradeId == 0) {
      final unlockedIds = await ProgressService.getUnlockedGradeIds();
      _hanziList = HanziRepository.instance
          .forAllGrades()
          .where((h) => unlockedIds.contains(h.gradeId))
          .toList();
    } else {
      _hanziList = HanziRepository.instance.forGrade(widget.gradeId);
    }

    final lastIndex =
        await StorageService.instance.getLastIndexForKey(_progressKey);
    final favorites = await StorageService.instance.getFavoriteIds();
    final viewedIds = await StorageService.instance.getViewedIds();
    final safeIndex = _hanziList.isEmpty
        ? 0
        : (widget.initialIndex ?? lastIndex).clamp(0, _hanziList.length - 1);

    setState(() {
      _favoriteIds = favorites;
      _viewedIds = viewedIds;
      _pageController = PageController(initialPage: safeIndex);
      _isLoading = false;
    });

    if (_hanziList.isNotEmpty) {
      _markViewedAndSpeak(safeIndex);
    }

    // 第一次进入学习页时，提示“点哪里都能发音”，自动消失
    final hintShown = await StorageService.instance.getAudioHintShown();
    if (!hintShown && mounted) {
      await StorageService.instance.setAudioHintShown();
      if (!mounted) return;
      setState(() => _showAudioHint = true);
      _audioHintTimer = Timer(const Duration(seconds: 9), _dismissAudioHint);
    }
  }

  void _dismissAudioHint() {
    _audioHintTimer?.cancel();
    _audioHintTimer = null;
    if (mounted && _showAudioHint) {
      setState(() => _showAudioHint = false);
    }
  }

  void _markViewedAndSpeak(int index) {
    final hanzi = _hanziList[index];
    _viewedIds.add(hanzi.id);
    StorageService.instance.markViewed(hanzi.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak(hanzi.char, tag: 'char_${hanzi.id}');
    });
  }

  bool get _allViewed =>
      _hanziList.isNotEmpty &&
      _hanziList.every((h) => _viewedIds.contains(h.id));

  /// 在最后一页继续向左滑时：四个字都学完则进入下一课，否则轻提示
  void _handleScrollNotification(ScrollNotification notification) {
    if (widget.onFinished == null || _nextTriggered) return;
    if (notification.depth != 0) return;
    if (notification.metrics.axis != Axis.horizontal) return;

    final metrics = notification.metrics;
    final atEnd = metrics.pixels >= metrics.maxScrollExtent - 1;

    if (notification is ScrollStartNotification) {
      _dragStartedAtEnd = notification.dragDetails != null && atEnd;
    } else if (notification is OverscrollNotification) {
      if (atEnd && notification.overscroll.abs() > 24) {
        _tryFinishCourse();
      }
    } else if (notification is ScrollEndNotification) {
      final startedAtEnd = _dragStartedAtEnd;
      _dragStartedAtEnd = false;
      final velocityX =
          notification.dragDetails?.velocity.pixelsPerSecond.dx ?? 0;
      if (startedAtEnd && atEnd && velocityX < -80) {
        _tryFinishCourse();
      }
    }
  }

  void _tryFinishCourse() {
    if (widget.onFinished == null || _nextTriggered) return;

    final page = _pageController?.page;
    if (page == null || page.round() < _hanziList.length - 1) return;

    if (!_allViewed) {
      final now = DateTime.now();
      final last = _lastFinishHintAt;
      if (last == null || now.difference(last) > const Duration(seconds: 3)) {
        _lastFinishHintAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.s.lessonFinishedHint(_hanziList.length)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    _nextTriggered = true;
    widget.onFinished!();
  }

  void _onPageChanged(int index) {
    StorageService.instance.saveLastIndexForKey(_progressKey, index);
    _markViewedAndSpeak(index);
  }

  void _toggleFavorite(String id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    StorageService.instance.saveFavoriteIds(_favoriteIds);
  }

  void _goToGradeSelect() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _audioHintTimer?.cancel();
    _pageController?.dispose();
    TtsService.instance.stop(notify: false);
    super.dispose();
  }

  String _resolvedTitle(AppStrings s) {
    final lesson = widget.lessonNumber;
    final chars = widget.chars;
    if (lesson != null && chars != null) {
      return s.lessonTitle(lesson, chars.map((e) => e.char).join());
    }
    if (widget.gradeId == 0 && chars == null) {
      return s.allUnlockedTitle;
    }
    if (widget.gradeId > 0 && chars == null) {
      return s.stageName(widget.gradeId);
    }
    return widget.title ?? '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _pageController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final s = context.s;

    if (_hanziList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_resolvedTitle(s))),
        body: Center(child: Text(s.emptyStage)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_resolvedTitle(s)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: s.backToStages,
          onPressed: _goToGradeSelect,
        ),
        actions: [
          // 英文释义开关：中文界面默认关，其它语言界面默认开
          ValueListenableBuilder<bool>(
            valueListenable: MeaningService.instance.visible,
            builder: (context, on, _) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: on ? s.hideMeaning : s.showMeaning,
                child: InkWell(
                  borderRadius: BorderRadius.circular(9),
                  onTap: MeaningService.instance.toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFFE8F5E9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: on ? const Color(0xFF7CB342) : Colors.black26,
                      ),
                    ),
                    child: Text(
                      'EN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: on ? const Color(0xFF33691E) : Colors.black45,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          if (_showAudioHint)
            ContentFrame(child: AudioHintBanner(onClose: _dismissAudioHint)),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                _handleScrollNotification(notification);
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _hanziList.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final hanzi = _hanziList[index];
                  // 平板 / 横屏时卡片居中，翻页手势仍覆盖整屏
                  return ContentFrame(
                    child: CharacterCard(
                      hanzi: hanzi,
                      isFavorite: _favoriteIds.contains(hanzi.id),
                      onToggleFavorite: () => _toggleFavorite(hanzi.id),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
