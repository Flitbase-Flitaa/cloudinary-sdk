import 'dart:developer' as developer;

class CloudinaryLogger {
  CloudinaryLogger._();
  static final CloudinaryLogger _instance = CloudinaryLogger._();
  static CloudinaryLogger get instance => _instance;

  /// Defaults to debug mode (asserts enabled = dart --enable-asserts).
  /// Override with [true] to force-enable or [false] to force-disable.
  bool? enabled;

  bool get _shouldLog => enabled ?? _isDebugMode;

  static final bool _isDebugMode = () {
    var debug = false;
    assert(() {
      debug = true;
      return true;
    }());
    return debug;
  }();

  void info(String message) {
    if (_shouldLog) developer.log(message, name: 'Cloudinary SDK', level: 500);
  }

  void success(String message) {
    if (_shouldLog) developer.log(message, name: 'Cloudinary SDK', level: 800);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (_shouldLog) {
      developer.log(
        message,
        name: 'Cloudinary SDK',
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
