/// 前端表单收集的计算请求
class CalcRequest {
  const CalcRequest({
    required this.name,
    required this.code,
    required this.buyPrice,
    required this.stopLoss,
    required this.maxLoss,
    required this.riskReward,
  });

  final String name;
  final String code;
  final double buyPrice;
  final double stopLoss;
  final double maxLoss;
  final double riskReward;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'buyPrice': buyPrice,
        'stopLoss': stopLoss,
        'maxLoss': maxLoss,
        'riskReward': riskReward,
      };

  factory CalcRequest.fromJson(Map<String, dynamic> json) {
    return CalcRequest(
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      buyPrice: (json['buyPrice'] as num?)?.toDouble() ?? 0,
      stopLoss: (json['stopLoss'] as num?)?.toDouble() ?? 0,
      maxLoss: (json['maxLoss'] as num?)?.toDouble() ?? 0,
      riskReward: (json['riskReward'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// 根据输入推导出的结果
class CalcResult {
  const CalcResult({
    required this.unitRisk,
    required this.quantity,
    required this.requiredCapital,
    required this.maxProfit,
    required this.takeProfit,
  });

  final double unitRisk;
  final double quantity;
  final double requiredCapital;
  final double maxProfit;
  final double takeProfit;

  factory CalcResult.fromJson(Map<String, dynamic> json) {
    return CalcResult(
      unitRisk: (json['unitRisk'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      requiredCapital: (json['requiredCapital'] as num?)?.toDouble() ?? 0,
      maxProfit: (json['maxProfit'] as num?)?.toDouble() ?? 0,
      takeProfit: (json['takeProfit'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'unitRisk': unitRisk,
        'quantity': quantity,
        'requiredCapital': requiredCapital,
        'maxProfit': maxProfit,
        'takeProfit': takeProfit,
      };
}

/// 封装一次保存的规则及其结果
class CalcRule {
  const CalcRule({
    required this.id,
    required this.request,
    required this.result,
    this.createdAt,
  });

  final String id;
  final CalcRequest request;
  final CalcResult result;
  final DateTime? createdAt;

  factory CalcRule.fromJson(Map<String, dynamic> json) {
    return CalcRule(
      id: json['id']?.toString() ?? '',
      request:
          json['request'] is Map<String, dynamic> // nested or flat payloads
              ? CalcRequest.fromJson(json['request'] as Map<String, dynamic>)
              : CalcRequest.fromJson(json),
      result: json['result'] is Map<String, dynamic>
          ? CalcResult.fromJson(json['result'] as Map<String, dynamic>)
          : CalcResult.fromJson(json),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'result': result.toJson(),
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };
}
