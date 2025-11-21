import 'package:flutter/material.dart';

import 'models/calc_models.dart';
import 'services/api_service.dart';

const String apiBaseUrl = 'http://localhost:8080';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '盈亏比组合工具',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const ProfitLossCalculatorPage(),
    );
  }
}

class ProfitLossCalculatorPage extends StatefulWidget {
  const ProfitLossCalculatorPage({super.key});

  @override
  State<ProfitLossCalculatorPage> createState() =>
      _ProfitLossCalculatorPageState();
}

class _ProfitLossCalculatorPageState extends State<ProfitLossCalculatorPage> {
  final _forms = <_RuleFormData>[];
  final _api = ProfitLossApiService(baseUrl: apiBaseUrl);

  List<CalcRule> _savedRules = [];
  bool _loadingRules = true;
  String? _globalError;
  String? _deletingRuleId;

  @override
  void initState() {
    super.initState();
    _addFormRow();
    _loadSavedRules();
  }

  @override
  void dispose() {
    for (final form in _forms) {
      form.dispose();
    }
    _api.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRules() async {
    setState(() {
      _loadingRules = true;
      _globalError = null;
    });
    try {
      final rules = await _api.fetchRules();
      if (!mounted) return;
      setState(() {
        _savedRules = rules;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _globalError = '规则加载失败：${_readableError(e)}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingRules = false;
      });
    }
  }

  void _addFormRow() {
    setState(() {
      _forms.add(_RuleFormData());
    });
  }

  void _removeFormRow(_RuleFormData row) {
    if (_forms.length == 1) return;
    setState(() {
      _forms.remove(row);
    });
    row.dispose();
  }

  CalcRequest? _buildRequestFromRow(_RuleFormData row) {
    final name = row.nameController.text.trim();
    final code = row.codeController.text.trim();
    final buyPrice = double.tryParse(row.buyPriceController.text.trim());
    final stopLoss = double.tryParse(row.stopLossController.text.trim());
    final maxLoss = double.tryParse(row.maxLossController.text.trim());
    final ratio = double.tryParse(row.ratioController.text.trim());

    String? error;
    if (name.isEmpty || code.isEmpty) {
      error = '请输入个股名称和代码。';
    } else if ([buyPrice, stopLoss, maxLoss, ratio].contains(null)) {
      error = '价格、亏损与盈亏比必须为数字。';
    } else if (buyPrice! <= 0 ||
        stopLoss! <= 0 ||
        maxLoss! <= 0 ||
        ratio! <= 0) {
      error = '所有输入值必须大于 0。';
    } else if (stopLoss >= buyPrice) {
      error = '止损点必须低于买入点。';
    }

    if (error != null) {
      setState(() => row.error = error);
      return null;
    }

    return CalcRequest(
      name: name,
      code: code,
      buyPrice: buyPrice!,
      stopLoss: stopLoss!,
      maxLoss: maxLoss!,
      riskReward: ratio!,
    );
  }

  Future<void> _calculateRow(_RuleFormData row) async {
    final request = _buildRequestFromRow(row);
    if (request == null) return;

    setState(() {
      row
        ..error = null
        ..isCalculating = true
        ..result = null;
    });

    try {
      final result = await _api.calculate(request);
      if (!mounted) return;
      setState(() {
        row.result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        row.error = '计算失败：${_readableError(e)}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        row.isCalculating = false;
      });
    }
  }

  Future<void> _saveRow(_RuleFormData row) async {
    final request = _buildRequestFromRow(row);
    if (request == null) return;

    setState(() {
      row
        ..error = null
        ..isSaving = true;
    });

    try {
      final savedRule = await _api.saveRule(request);
      if (!mounted) return;
      setState(() {
        row.result = savedRule.result;
        _savedRules = [savedRule, ..._savedRules];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存 ${request.name}(${request.code})')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        row.error = '保存失败：${_readableError(e)}';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        row.isSaving = false;
      });
    }
  }

  Future<void> _deleteRule(String id) async {
    setState(() {
      _deletingRuleId = id;
    });
    try {
      await _api.deleteRule(id);
      if (!mounted) return;
      setState(() {
        _savedRules.removeWhere((rule) => rule.id == id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败：${_readableError(e)}')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _deletingRuleId = null;
      });
    }
  }

  String _readableError(Object error) {
    if (error is ApiException) return error.message;
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('盈亏比组合工具'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedRules,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const Text(
              '批量管理个股仓位：为每个标的设置买入、止损和最大亏损，'
              '通过接口计算所需仓位，保存后可在下方列表中统一查看与删除。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ..._forms
                .asMap()
                .entries
                .map((entry) => _buildRuleFormCard(entry.key, entry.value))
                .toList(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _addFormRow,
              icon: const Icon(Icons.add),
              label: const Text('新增个股'),
            ),
            const SizedBox(height: 32),
            _buildSavedRulesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleFormCard(int index, _RuleFormData row) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '个股 ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_forms.length > 1)
                  IconButton(
                    tooltip: '移除此行',
                    onPressed: () => _removeFormRow(row),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: row.nameController,
                    label: '股票名称',
                    hintText: '如：贵州茅台',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: row.codeController,
                    label: '股票代码',
                    hintText: '如：600519',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: row.buyPriceController,
                    label: '买入点（元）',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: row.stopLossController,
                    label: '止损点（元）',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: row.maxLossController,
                    label: '最大可亏金额（元）',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: row.ratioController,
                    label: '盈亏比（如 3 表示 3:1）',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      row.isCalculating ? null : () => _calculateRow(row),
                  icon: row.isCalculating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate),
                  label: const Text('计算'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: row.isSaving ? null : () => _saveRow(row),
                  icon: row.isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('保存规则'),
                ),
              ],
            ),
            if (row.error != null) ...[
              const SizedBox(height: 12),
              Text(
                row.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (row.result != null) ...[
              const SizedBox(height: 16),
              _ResultChips(result: row.result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hintText),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _buildSavedRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '已保存的交易规则',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              tooltip: '刷新',
              onPressed: _loadingRules ? null : _loadSavedRules,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        if (_globalError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              _globalError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (_loadingRules)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_savedRules.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('暂无保存记录，先在上方添加并保存一条规则吧。'),
          )
        else
          ..._savedRules.map(
            (rule) => Card(
              child: ListTile(
                title: Text('${rule.request.name} (${rule.request.code})'),
                subtitle: Text(
                  '买入 ${_format(rule.request.buyPrice)} / '
                  '止损 ${_format(rule.request.stopLoss)} / '
                  '盈亏比 ${_format(rule.request.riskReward)} / '
                  '所需本金 ${_format(rule.result.requiredCapital)}',
                ),
                trailing: IconButton(
                  tooltip: '删除',
                  onPressed: _deletingRuleId == rule.id
                      ? null
                      : () => _deleteRule(rule.id),
                  icon: _deletingRuleId == rule.id
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _format(double value) {
    return value.toStringAsFixed(value.abs() >= 100 ? 0 : 2);
  }
}

class _ResultChips extends StatelessWidget {
  const _ResultChips({required this.result});

  final CalcResult result;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('单位风险', result.unitRisk),
      ('可买入数量', result.quantity),
      ('所需本金', result.requiredCapital),
      ('最大收益', result.maxProfit),
      ('止盈价', result.takeProfit),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => Chip(
              label: Text(
                '${item.$1}: ${item.$2.toStringAsFixed(item.$2.abs() >= 100 ? 0 : 2)}',
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RuleFormData {
  _RuleFormData()
      : nameController = TextEditingController(),
        codeController = TextEditingController(),
        buyPriceController = TextEditingController(),
        stopLossController = TextEditingController(),
        maxLossController = TextEditingController(),
        ratioController = TextEditingController(text: '3');

  final TextEditingController nameController;
  final TextEditingController codeController;
  final TextEditingController buyPriceController;
  final TextEditingController stopLossController;
  final TextEditingController maxLossController;
  final TextEditingController ratioController;

  CalcResult? result;
  String? error;
  bool isCalculating = false;
  bool isSaving = false;

  void dispose() {
    nameController.dispose();
    codeController.dispose();
    buyPriceController.dispose();
    stopLossController.dispose();
    maxLossController.dispose();
    ratioController.dispose();
  }
}
