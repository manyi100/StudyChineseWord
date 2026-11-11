import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/hanzi_model.dart';
import '../models/hanzi_course.dart';
import 'stroke_repository.dart';

/// 汉字数据仓库：720字数据量较大，不再硬编码在Dart源码里，
/// 改为打包成 assets/data/hanzi_data.json，启动时读取一次并缓存在内存中。
class HanziRepository {
  HanziRepository._internal();
  static final HanziRepository instance = HanziRepository._internal();

  List<HanziModel> _all = [];
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/data/hanzi_data.json');
    final List<dynamic> raw = jsonDecode(jsonStr);
    _all =
        raw.map((e) => HanziModel.fromJson(e as Map<String, dynamic>)).toList();
    await StrokeRepository.instance.ensureLoaded();
    _loaded = true;
  }

  List<HanziModel> get all => _all;

  /// 某个年级的字，按原书排版顺序排列（已经把相近字相邻排好）
  List<HanziModel> forGrade(int gradeId) {
    final list = _all.where((h) => h.gradeId == gradeId).toList();
    list.sort((a, b) => a.orderInGrade.compareTo(b.orderInGrade));
    return list;
  }

  /// "全部年级连续学"：按年级顺序依次排列
  List<HanziModel> forAllGrades() {
    final list = [..._all];
    list.sort((a, b) {
      final g = a.gradeId.compareTo(b.gradeId);
      if (g != 0) return g;
      return a.orderInGrade.compareTo(b.orderInGrade);
    });
    return list;
  }

  int countForGrade(int gradeId) => _all.where((h) => h.gradeId == gradeId).length;

  List<HanziCourse>? _courses;

  /// 全部 180 课（每课 = 原书同一行的 4 个字），按阶段/原书顺序排列
  List<HanziCourse> get courses {
    final cached = _courses;
    if (cached != null) return cached;

    final grouped = <String, List<HanziModel>>{};
    for (final h in _all) {
      grouped.putIfAbsent(h.groupId, () => []).add(h);
    }

    final ordered = grouped.entries.toList()
      ..sort((a, b) {
        final ga = a.value.first.gradeId.compareTo(b.value.first.gradeId);
        if (ga != 0) return ga;
        final minA = a.value
            .map((e) => e.orderInGrade)
            .reduce((x, y) => x < y ? x : y);
        final minB = b.value
            .map((e) => e.orderInGrade)
            .reduce((x, y) => x < y ? x : y);
        return minA.compareTo(minB);
      });

    final stageCounters = <int, int>{};
    var index = 0;
    final list = <HanziCourse>[];
    for (final entry in ordered) {
      final chars = [...entry.value]
        ..sort((a, b) => a.groupOrder.compareTo(b.groupOrder));
      final stage = chars.first.gradeId;
      final inStage = (stageCounters[stage] ?? 0) + 1;
      stageCounters[stage] = inStage;
      index++;
      list.add(HanziCourse(
        groupId: entry.key,
        stageId: stage,
        index: index,
        indexInStage: inStage,
        chars: chars,
      ));
    }
    _courses = list;
    return list;
  }

  List<HanziCourse> coursesForGrade(int gradeId) =>
      courses.where((c) => c.stageId == gradeId).toList();

  /// 按部首归类，按字数从多到少排序，组内按笔画数排序
  List<RadicalGroup> get radicalGroups {
    final grouped = <String, List<HanziModel>>{};
    for (final h in _all) {
      final radical = (h.radical == null || h.radical!.isEmpty) ? '其他' : h.radical!;
      grouped.putIfAbsent(radical, () => []).add(h);
    }
    final list = grouped.entries.map((e) {
      final chars = [...e.value]
        ..sort((a, b) {
          final sa = a.strokeCount ?? 99;
          final sb = b.strokeCount ?? 99;
          if (sa != sb) return sa.compareTo(sb);
          return a.id.compareTo(b.id);
        });
      return RadicalGroup(radical: e.key, chars: chars);
    }).toList()
      ..sort((a, b) {
        final c = b.chars.length.compareTo(a.chars.length);
        if (c != 0) return c;
        return a.radical.compareTo(b.radical);
      });
    return list;
  }

  /// 按笔画数分段（1~3、4~5、6~7、8~9、10~12、13+）
  List<StrokeBand> get strokeBands {
    const ranges = [
      (1, 3, '1~3画'),
      (4, 5, '4~5画'),
      (6, 7, '6~7画'),
      (8, 9, '8~9画'),
      (10, 12, '10~12画'),
      (13, 99, '13画以上'),
    ];
    return ranges.map((r) {
      final chars = _all
          .where((h) {
            final s = h.strokeCount;
            return s != null && s >= r.$1 && s <= r.$2;
          })
          .toList()
        ..sort((a, b) {
          final sa = a.strokeCount ?? 99;
          final sb = b.strokeCount ?? 99;
          if (sa != sb) return sa.compareTo(sb);
          return a.id.compareTo(b.id);
        });
      return StrokeBand(
        label: r.$3,
        minStrokes: r.$1,
        maxStrokes: r.$2,
        chars: chars,
      );
    }).toList();
  }
}
