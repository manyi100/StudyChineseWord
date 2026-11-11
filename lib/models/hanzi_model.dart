/// 组词条目：词语本身 + 对应拼音
class WordEntry {
  final String text;
  final String pinyin;

  const WordEntry({required this.text, required this.pinyin});

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        text: json['text'] as String,
        pinyin: json['pinyin'] as String,
      );
}

/// 例句条目：句子本身 + 对应拼音
class SentenceEntry {
  final String text;
  final String pinyin;

  const SentenceEntry({required this.text, required this.pinyin});

  factory SentenceEntry.fromJson(Map<String, dynamic> json) => SentenceEntry(
        text: json['text'] as String,
        pinyin: json['pinyin'] as String,
      );
}

/// 单个汉字的完整数据结构
///
/// 数据来源说明：
/// - pinyin / strokeCount / strokeOrderNames / radical / structure
///   均来自 cnchar(MIT协议)库的真实词典数据，不是手写猜测，可信度高
/// - gradeId / orderInGrade / groupId / groupOrder 来自原始720字文件的
///   行序号，按"每30行=一个年级"自动均分为6个年级，同一行的4个字
///   视为一组"相近字"，组内顺序保留原书排版顺序
/// - words / sentence 暂未填充（需要单独的内容整理阶段）
/// - needsReview = true 表示该字在原始数据文件中存在已知问题
///   （例如来源行重复、或为非简体/无法识别的字），需要人工核对原书
class HanziModel {
  final String id;
  final String char;
  final String pinyin;
  final int gradeId;
  final int orderInGrade;
  final String groupId;
  final int groupOrder;
  final int? strokeCount;
  final List<String> strokeOrderNames; // 例如 ["撇","横","竖","竖","横折","横"]
  final String? radical;
  final String? structure;
  final List<WordEntry> words;
  final SentenceEntry? sentence;
  final String? imageAsset;
  final bool needsReview;

  const HanziModel({
    required this.id,
    required this.char,
    required this.pinyin,
    required this.gradeId,
    required this.orderInGrade,
    required this.groupId,
    required this.groupOrder,
    this.strokeCount,
    this.strokeOrderNames = const [],
    this.radical,
    this.structure,
    this.words = const [],
    this.sentence,
    this.imageAsset,
    this.needsReview = false,
  });

  /// 把笔顺名称数组拼接成可读字符串（中文数据原样拼接；
  /// 界面展示请使用 AppStrings.strokeOrder，以跟随界面语言）。
  String get strokeOrderDisplay =>
      strokeOrderNames.isEmpty ? '暂无笔顺数据' : strokeOrderNames.join(' → ');

  factory HanziModel.fromJson(Map<String, dynamic> json) {
    return HanziModel(
      id: json['id'] as String,
      char: json['char'] as String,
      pinyin: (json['pinyin'] as String?) ?? '',
      gradeId: json['gradeId'] as int,
      orderInGrade: json['orderInGrade'] as int,
      groupId: json['groupId'] as String,
      groupOrder: json['groupOrder'] as int,
      strokeCount: json['strokeCount'] as int?,
      strokeOrderNames: (json['strokeOrderNames'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      radical: json['radical'] as String?,
      structure: json['structure'] as String?,
      words: (json['words'] as List<dynamic>?)
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sentence: json['sentence'] != null
          ? SentenceEntry.fromJson(json['sentence'] as Map<String, dynamic>)
          : null,
      imageAsset: json['imageAsset'] as String?,
      needsReview: (json['needsReview'] as bool?) ?? false,
    );
  }
}

/// 年级元信息：用于年级选择页展示
class GradeInfo {
  final int id;
  final String name;
  const GradeInfo({required this.id, required this.name});
}

const List<GradeInfo> gradeInfoList = [
  GradeInfo(id: 1, name: '第 1 阶段'),
  GradeInfo(id: 2, name: '第 2 阶段'),
  GradeInfo(id: 3, name: '第 3 阶段'),
  GradeInfo(id: 4, name: '第 4 阶段'),
  GradeInfo(id: 5, name: '第 5 阶段'),
  GradeInfo(id: 6, name: '第 6 阶段'),
];
