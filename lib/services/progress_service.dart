import '../models/hanzi_model.dart';
import 'hanzi_repository.dart';
import 'storage_service.dart';

/// 年级解锁/进度判断逻辑统一放在这里，年级选择页和学习页("全部"模式)
/// 都依赖同一份逻辑，避免出现两处实现不一致的情况。
class ProgressService {
  /// 返回当前已解锁的年级ID列表，按顺序排列（第1年级必定在内）。
  /// 规则：从第1年级开始，只要前一个年级"学完"（该年级里的字全部浏览过），
  /// 就解锁下一个年级；一旦遇到未学完的年级，后面的年级全部保持锁定。
  static Future<List<int>> getUnlockedGradeIds() async {
    final viewed = await StorageService.instance.getViewedIds();
    final unlocked = <int>[];
    bool previousCompleted = true; // 第1年级前面没有"上一年级"要求，视为满足

    for (final grade in gradeInfoList) {
      if (!previousCompleted) break;
      unlocked.add(grade.id);

      final chars = HanziRepository.instance.forGrade(grade.id);
      final learnedCount = chars.where((h) => viewed.contains(h.id)).length;
      previousCompleted = chars.isNotEmpty && learnedCount >= chars.length;
    }
    return unlocked;
  }

  static Future<bool> isGradeUnlocked(int gradeId) async {
    final unlocked = await getUnlockedGradeIds();
    return unlocked.contains(gradeId);
  }
}
