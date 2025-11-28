import '../models/calc_models.dart';
import '../packages/network/api_client.dart';

class ProfitLossApiService {
  ProfitLossApiService({
    required String baseUrl,
    ApiClient? client,
  }) : _client = client ??
            ApiClient(
              baseUrl: baseUrl,
              successKey: 'success',
              successValue: true,
              messageKey: 'message',
              dataKey: 'data',
            );

  final ApiClient _client;

  Future<CalcResult> calculate(CalcRequest request) async {
    final response = await _client.post<CalcResult>(
      '/api/calc',
      body: request.toJson(),
      parser: (json) => CalcResult.fromJson(json as Map<String, dynamic>),
    );
    return response.requireData();
  }

  Future<List<CalcRule>> fetchRules() async {
    final response = await _client.get<List<CalcRule>>(
      '/api/rules',
      parser: (json) {
        if (json is List) {
          return json
              .whereType<Map<String, dynamic>>()
              .map(CalcRule.fromJson)
              .toList();
        }
        return const <CalcRule>[];
      },
    );
    return response.data ?? const [];
  }

  Future<CalcRule> saveRule(CalcRequest request) async {
    final response = await _client.post<CalcRule>(
      '/api/rules',
      body: request.toJson(),
      parser: (json) => CalcRule.fromJson(json as Map<String, dynamic>),
    );
    return response.requireData();
  }

  Future<void> deleteRule(String id) async {
    await _client.delete<void>(
      '/api/rules/$id',
      parser: (_) => null,
    );
  }

  void dispose() {
    _client.dispose();
  }
}
