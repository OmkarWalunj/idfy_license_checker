import 'package:idfy_license_checker/idfy_license_checker.dart';

void main() async {
  final dlManager = DLVerificationManager(
    apiKey: 'your-idfy-api-key',
    accountId: 'your-idfy-account-id',
  );

  final extractResult =
      await dlManager.extractDLData('https://example.com/license.jpg');
  print('Extracted Data: $extractResult');

  final verifyResult = await dlManager.verifyDL(
    idNumber: 'DL-XXXXXXXXXXXX',
    dob: 'YYYY-MM-DD',
  );
  print('Verification Result: $verifyResult');
}
