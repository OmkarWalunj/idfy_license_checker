import 'dart:convert';
import 'package:http/http.dart' as http;

/// A class for handling DL verification using IDfy.
class DLVerificationManager {
  final String apiKey;
  final String accountId;

  DLVerificationManager({
    required this.apiKey,
    required this.accountId,
  });

  /// Validates the image URL format.
  bool validateImageUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  /// Extracts DL data from an image using IDfy.
  Future<Map<String, dynamic>> extractDLData(String imageUrl) async {
    if (!validateImageUrl(imageUrl)) {
      throw Exception('Invalid image URL.');
    }

    final String taskId = 'task-${DateTime.now().millisecondsSinceEpoch}';
    final String groupId = 'group-${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse(
          'https://eve.idfy.com/v3/tasks/async/extract/ind_driving_license'),
      headers: {
        'Content-Type': 'application/json',
        'api-key': apiKey,
        'account-id': accountId,
      },
      body: jsonEncode({
        'task_id': taskId,
        'group_id': groupId,
        'data': {'document1': imageUrl},
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to extract DL data: ${response.body}');
    }

    final responseBody = jsonDecode(response.body);
    final requestId = responseBody['request_id'];
    return _fetchData(requestId);
  }

  /// Fetches data for an extraction request.
  Future<Map<String, dynamic>> _fetchData(String requestId) async {
    final url =
        Uri.parse('https://eve.idfy.com/v3/tasks?request_id=$requestId');

    while (true) {
      final response = await http.get(
        url,
        headers: {
          'api-key': apiKey,
          'account-id': accountId,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List tasksList = jsonDecode(response.body);
        if (tasksList.isNotEmpty) {
          final task = tasksList.first;

          if (task['status'] == 'completed') {
            return task['result'] ?? {};
          } else if (task['status'] == 'failed') {
            throw Exception('DL data extraction failed: ${task['error']}');
          }
        }
      }

      await Future.delayed(Duration(seconds: 3));
    }
  }

  /// Verifies DL data with government sources.
  Future<Map<String, dynamic>> verifyDL({
    required String idNumber,
    required String dob,
  }) async {
    final String taskId = 'task-${DateTime.now().millisecondsSinceEpoch}';
    final String groupId = 'group-${DateTime.now().millisecondsSinceEpoch}';

    final response = await http.post(
      Uri.parse(
          'https://eve.idfy.com/v3/tasks/async/verify_with_source/ind_driving_license'),
      headers: {
        'Content-Type': 'application/json',
        'api-key': apiKey,
        'account-id': accountId,
      },
      body: jsonEncode({
        'task_id': taskId,
        'group_id': groupId,
        'data': {
          'id_number': idNumber,
          'date_of_birth': dob,
          'advanced_details': {'state_info': true, 'age_info': true},
        },
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 202) {
      throw Exception('Failed to verify DL: ${response.body}');
    }

    final responseBody = jsonDecode(response.body);
    final requestId = responseBody['request_id'];
    return _fetchDLVerificationData(requestId);
  }

  /// Fetches data for a verification request.
  Future<Map<String, dynamic>> _fetchDLVerificationData(
      String requestId) async {
    final url =
        Uri.parse('https://eve.idfy.com/v3/tasks?request_id=$requestId');

    while (true) {
      final response = await http.get(
        url,
        headers: {
          'api-key': apiKey,
          'account-id': accountId,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List tasksList = jsonDecode(response.body);
        if (tasksList.isNotEmpty) {
          final task = tasksList.first;

          if (task['status'] == 'completed') {
            return _parseVerificationDetails(task['result'] ?? {});
          } else if (task['status'] == 'failed') {
            throw Exception('DL verification failed.');
          }
        }
      }

      await Future.delayed(Duration(seconds: 3));
    }
  }

  /// Parses detailed verification results.
  Map<String, dynamic> _parseVerificationDetails(Map<String, dynamic>? result) {
    String? holderName;
    String? dlNumber;
    String? issueDate;
    String? expiryDate;
    bool isValid = false;
    String? statusMessage;

    if (result != null) {
      // Use 'source_output' from package response
      final sourceOutput = result['source_output'];
      if (sourceOutput != null && sourceOutput is Map) {
        final dlStatus = sourceOutput['dl_status'];
        final status = sourceOutput['status'];
        holderName = sourceOutput['name'] ?? '';
        dlNumber = sourceOutput['id_number'] ?? '';
        issueDate = sourceOutput['date_of_issue'] ?? '';
        expiryDate = sourceOutput['nt_validity_to'] ??
            sourceOutput['t_validity_to'] ??
            '';

        if (dlStatus != null) {
          isValid = dlStatus.toString().toLowerCase() == 'active' ||
              dlStatus.toString().toLowerCase() == 'valid';
          statusMessage = 'DL Status: $dlStatus';
        } else if (status != null) {
          isValid = status.toString().toLowerCase() == 'id_found' ||
              status.toString().toLowerCase() == 'valid';
          statusMessage = 'Status: $status';
        }
      } else {
        // Fallback to top-level keys if 'source_output' doesn't exist
        final dlStatus = result['dl_status'];
        final dlFound = result['dl_found'];
        final status = result['status'];

        if (dlStatus != null) {
          isValid = dlStatus.toString().toLowerCase() == 'valid' ||
              dlStatus.toString().toLowerCase() == 'active';
          statusMessage = 'DL Status: $dlStatus';
        } else if (dlFound != null) {
          isValid =
              dlFound == true || dlFound.toString().toLowerCase() == 'true';
          statusMessage = isValid ? 'DL Found in Records' : 'DL Not Found';
        } else if (status != null) {
          isValid = status.toString().toLowerCase() == 'valid' ||
              status.toString().toLowerCase() == 'id_found';
          statusMessage = 'Status: $status';
        }
      }
    }

    return {
      'isValid': isValid,
      'holderName': holderName ?? '',
      'dlNumber': dlNumber ?? '',
      'issueDate': issueDate ?? '',
      'expiryDate': expiryDate ?? '',
      'statusMessage': statusMessage ?? '',
    };
  }
}
