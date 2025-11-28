import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/calc_models.dart';

/// 使用 SharedPreferences 做简单的规则持久化
class LocalRuleStore {
  static const _rulesKey = 'saved_calc_rules';

  /// 读取本地缓存的全部规则
  Future<List<CalcRule>> loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_rulesKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map(CalcRule.fromJson)
            .toList();
      }
    } catch (_) {
      // ignore malformed cache
    }
    return [];
  }

  /// 覆盖式写入最新规则列表
  Future<void> saveRules(List<CalcRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(rules.map((rule) => rule.toJson()).toList());
    await prefs.setString(_rulesKey, payload);
  }
}

