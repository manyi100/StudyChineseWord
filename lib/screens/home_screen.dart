import 'dart:async';

import 'package:flutter/material.dart';
import '../models/hanzi_model.dart';
import '../services/hanzi_repository.dart';
import '../services/progress_service.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/audio_feedback.dart';
import '../widgets/character_card.dart';
import 'grade_select_screen.dart';

class HomeScreen extends StatefulWidget {
  /// gradeId = 0 表示"已解锁阶段连续学"，1~6 表示具体阶段。
  /// 传入 [chars] 时则直接学习给定的字列表（课程/部首/笔画分组共用）。
  final int gradeId;
  final List<HanziModel>? chars;
  final String? title;
  final String? progressKey;
  final int? initialIndex;

  const HomeScreen({
    super.key,
    this.gradeId = 0,
    this.chars,
    this.title,
    this.progressKey,
    this.initialIndex,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController? _pageController;
  int _currentIndex = 0;
  Set<String> _favoriteIds = {};
  bool _isLoading = true;

  List<HanziModel> _hanziList = [];
  String _titleText = '';
  bool _showAudioHint = false;
  Timer? _audioHintTimer;

  @override
  void initState() {
    super.initState();
    _restoreState();
  }

  String get _progressKey => widget.progressKey ?? 'grade_${widget.gradeId}';

  Future<void> _restoreState() async {
    await HanziRepository.instance.ensureLoaded();

    final explicitChars = widget.chars;
    if (explicitChars != null) {
      _hanziList = explicitChars;
      _titleText = widget.title ?? '';
    } else if (widget.gradeId == 0) {
      final unlockedIds = await ProgressService.getUnlockedGradeIds();
      _hanziList = HanziRepository.instance
          .forAllGrades()
          .where((h) => unlockedIds.contains(h.gradeId))
          .toList();
      _titleText = '入学必备720字 · 已解锁';
    } else {
      _hanziList = HanziRepository.instance.forGrade(widget.gradeId);
      final grade = gradeInfoList.firstWhere((g) => g.id == widget.gradeId);
      _titleText = grade.name;
    }

    final lastIndex =
        await StorageService.instance.getLastIndexForKey(_progressKey);
    final favorites = await StorageService.instance.getFavoriteIds();
    final safeIndex = _hanziList.isEmpty
        ? 0
        : (widget.initialIndex ?? lastIndex)
            .clamp(0, _hanziList.length - 1);

    setState(() {
      _currentIndex = safeIndex;
      _favoriteIds = favorites;
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
    StorageService.instance.markViewed(hanzi.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.instance.speak(hanzi.char);
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
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
    TtsService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _pageController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_hanziList.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_titleText)),
        body: const Center(child: Text('该阶段暂无数据')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: '返回阶段选择',
          onPressed: _goToGradeSelect,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${_currentIndex + 1} / ${_hanziList.length}',
              style: const TextStyle(color: Colors.black45, fontSize: 13),
            ),
          ),
          if (_showAudioHint) AudioHintBanner(onClose: _dismissAudioHint),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _hanziList.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final hanzi = _hanziList[index];
                return CharacterCard(
                  hanzi: hanzi,
                  isFavorite: _favoriteIds.contains(hanzi.id),
                  onToggleFavorite: () => _toggleFavorite(hanzi.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
