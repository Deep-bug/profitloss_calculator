class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.raw,
    this.statusCode,
  });

  final bool success;
  final String? message;
  final T? data;
  final dynamic raw;
  final int? statusCode;

  T requireData() {
    if (data == null) {
      throw StateError('响应数据为空');
    }
    return data as T;
  }
}
