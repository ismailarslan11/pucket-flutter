import 'package:flutter_test/flutter_test.dart';
import 'package:pucket_flutter/services/api_config.dart';

void main() {
  test('API base URL resolves from WS URL', () {
    expect(httpBaseFromWs('ws://localhost:8080'), 'http://localhost:8080');
  });
}
