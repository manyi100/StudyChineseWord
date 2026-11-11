import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/hanzi_model.dart';
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
}
