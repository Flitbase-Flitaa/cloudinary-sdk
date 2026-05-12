import 'package:dio/dio.dart';

import 'logger.dart';

class CloudinaryDioInterceptor extends Interceptor {
  static CloudinaryLogger get _log => CloudinaryLogger.instance;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.info(
      'REQUEST [${options.method}] → ${options.uri}\n'
      '  headers : ${options.headers}\n'
      '  data    : ${_summariseData(options.data)}',
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(response, ResponseInterceptorHandler handler) {
    _log.success(
      'RESPONSE [${response.statusCode}] ← ${response.requestOptions.uri}\n'
      '  data: ${_summariseData(response.data)}',
    );
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.error(
      'ERROR [${err.response?.statusCode}] ← ${err.requestOptions.uri}\n'
      '  type   : ${err.type}\n'
      '  message: ${err.message}',
      error: err,
      stackTrace: err.stackTrace,
    );
    super.onError(err, handler);
  }

  /// Keeps log lines short for multipart/binary payloads.
  String _summariseData(dynamic data) {
    if (data is FormData) {
      final fields = data.fields.map((e) => '${e.key}: ${e.value}');
      final files = data.files.map(
        (e) => '${e.key}: <file: ${e.value.filename}>',
      );
      return '{${[...fields, ...files].join(', ')}}';
    }
    return '$data';
  }
}
