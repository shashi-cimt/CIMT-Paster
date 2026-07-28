import 'package:canimage/utils/uid_file_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UidFileHelper', () {
    test('parses Android ID from ANDROID_ID line', () {
      const content = 'ANDROID_ID=abc123-device-id';

      expect(UidFileHelper.parseUid(content), 'abc123-device-id');
    });

    test('accepts bare Android ID values', () {
      const content = 'abc123-device-id';

      expect(UidFileHelper.parseUid(content), 'abc123-device-id');
    });
  });
}
