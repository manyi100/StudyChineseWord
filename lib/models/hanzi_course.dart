import 'hanzi_model.dart';

/// 一课 = 原书同一行的 4 个主题相近的汉字。
/// 720 字共 180 课，每阶段（原年级）30 课。
class HanziCourse {
  /// 课程 ID，直接复用数据里的 groupId（如 g1_line1）
  final String groupId;

  /// 所属阶段（1~6，对应原 gradeId）
  final int stageId;

  /// 全部课程中的序号（1 开始）
  final int index;

  /// 本阶段内的课序号（1 开始）
  final int indexInStage;

  final List<HanziModel> chars;

  const HanziCourse({
    required this.groupId,
    required this.stageId,
    required this.index,
    required this.indexInStage,
    required this.chars,
  });

  /// 课程标题就用 4 个汉字本身，例如 "上下左右"
  String get title => chars.map((e) => e.char).join();

  String get label => '第 $indexInStage 课';

  /// 该课是否已学完（4 个字都浏览/描红过）
  bool isCompleted(Set<String> viewedIds) =>
      chars.isNotEmpty && chars.every((h) => viewedIds.contains(h.id));

  int learnedCount(Set<String> viewedIds) =>
      chars.where((h) => viewedIds.contains(h.id)).length;
}

/// 按部首归类的一组汉字
class RadicalGroup {
  final String radical;
  final List<HanziModel> chars;

  const RadicalGroup({required this.radical, required this.chars});
}

/// 按笔画数分段的一组汉字
class StrokeBand {
  final String label;
  final int minStrokes;
  final int maxStrokes;
  final List<HanziModel> chars;

  const StrokeBand({
    required this.label,
    required this.minStrokes,
    required this.maxStrokes,
    required this.chars,
  });
}
