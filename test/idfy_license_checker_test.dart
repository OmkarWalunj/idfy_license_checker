import 'package:test/test.dart';
import 'package:idfy_license_checker/idfy_license_checker.dart';

void main() {
  test('Image URL validation', () {
    final manager = DLVerificationManager(apiKey: 'dummy', accountId: 'dummy');
    expect(manager.validateImageUrl('https://example.com/image.jpg'), isTrue);
    expect(manager.validateImageUrl('ftp://example.com/image.jpg'), isFalse);
  });
}
