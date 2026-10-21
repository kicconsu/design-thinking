import 'package:flutter_test/flutter_test.dart';
import 'package:imker/core/utils/log_config.dart';
import 'package:loggy/loggy.dart';

void main() {
  test('en release no pasan los mensajes debug, info ni warning', () {
    final options = logOptionsFor(release: true);

    expect(options.logLevel, LogLevel.error);
    expect(LogLevel.debug.priority >= options.logLevel.priority, isFalse);
    expect(LogLevel.warning.priority >= options.logLevel.priority, isFalse);
    expect(LogLevel.error.priority >= options.logLevel.priority, isTrue);
  });

  test('en debug se registra todo', () {
    expect(logOptionsFor(release: false).logLevel, LogLevel.all);
  });
}
