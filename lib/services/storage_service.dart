import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 本地存储服务：
/// - 记住用户上次选择的年级（重新打开App直接回到该年级）
/// - 分年级记住学习进度（每个年级单独记一个"上次学到第几个字"）
/// - 保存收藏的字ID集合（收藏复习功能，跨年级共用同一份收藏列表）
///
/// MVP阶段使用 shared_preferences 做轻量存储即可验证功能；
/// 后续整合完整720字数据 + 复习算法时，建议升级为 sqflite 数据库。
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  static const _kLastGradeKey = 'last_grade_id';
  static const _kLastIndexPrefix = 'last_index_grade_';
  static const _kFavoritesKey = 'favorite_ids';
  static const _kViewedIdsKey = 'viewed_char_ids';

  /// 已经"学习过"(浏览到过)的字ID集合，用于计算年级学习进度和解锁状态。
  /// 不区分年级——每个字的id本身就是全局唯一的，按所属年级筛选即可。
  Future<Set<String>> getViewedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kViewedIdsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => e.toString()).toSet();
  }

  Future<void> markViewed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getViewedIds();
    if (current.contains(id)) return; // 已经记录过，不用重复写
    current.add(id);
    await prefs.setString(_kViewedIdsKey, jsonEncode(current.toList()));
  }

  /// 上次选择的年级ID，没有记录时返回 null（代表需要展示年级选择页）
  Future<int?> getLastGradeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLastGradeKey);
  }

  Future<void> saveLastGradeId(int gradeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastGradeKey, gradeId);
  }

  /// 某个年级（或"全部"，约定用 gradeId = 0 表示全部）上次学习到的下标
  Future<int> getLastIndexForGrade(int gradeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_kLastIndexPrefix$gradeId') ?? 0;
  }

  Future<void> saveLastIndexForGrade(int gradeId, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kLastIndexPrefix$gradeId', index);
  }

  Future<Set<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kFavoritesKey);
    if (raw == null || raw.isEmpty) return <String>{};
    final List<dynamic> list = jsonDecode(raw);
    return list.map((e) => e.toString()).toSet();
  }

  Future<void> saveFavoriteIds(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFavoritesKey, jsonEncode(ids.toList()));
  }
}
