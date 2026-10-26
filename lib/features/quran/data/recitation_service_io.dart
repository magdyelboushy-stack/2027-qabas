import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/download_manager.dart';
import 'models/recitation.dart';
import '../../../config/api_endpoints.dart';

class RecitationService {
  static Future<File> _getLocalFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/cache';
    if (!await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    return File('$path/$filename');
  }

  static Future<List<Recitation>> getRecitationsForShaykh(
    String shaykhId, {
    String? mushafId,
  }) async {
    final String fileName =
        'recitations_shaykh_${shaykhId}_${mushafId ?? 'all'}_v4.json';
    final file = await _getLocalFile(fileName);

    List<Recitation> allRecitations = [];
    bool networkSuccess = false;

    try {
      // Build URL using ApiEndpoints
      final String url = ApiEndpoints.buildUrl(
        ApiEndpoints.recitationsRead,
        {
          'reciter_id': shaykhId,
          if (mushafId != null) 'mushaf_id': mushafId,
        },
      );

      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> jsonList = data['data'];
          allRecitations =
              jsonList.map((jsonItem) => Recitation.fromJson(jsonItem)).toList();
          await file.writeAsString(json.encode(jsonList));
          networkSuccess = true;
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (_) {
      // Offline or network failed: Fallback to cache
    }

    if (!networkSuccess) {
      // 1. Check exact file
      if (await file.exists()) {
        try {
          final contents = await file.readAsString();
          final List<dynamic> jsonList = json.decode(contents);
          allRecitations =
              jsonList.map((jsonItem) => Recitation.fromJson(jsonItem)).toList();
        } catch (_) {}
      }

      // 2. If empty, check 'all' cache file
      if (allRecitations.isEmpty) {
        try {
          final allFile =
              await _getLocalFile('recitations_shaykh_${shaykhId}_all_v4.json');
          if (await allFile.exists()) {
            final contents = await allFile.readAsString();
            final List<dynamic> jsonList = json.decode(contents);
            allRecitations =
                jsonList.map((jsonItem) => Recitation.fromJson(jsonItem)).toList();
          }
        } catch (_) {}
      }

      // 3. If still empty, scan cache folder for any cached recitations for this shaykh
      if (allRecitations.isEmpty) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final cacheDir = Directory('${directory.path}/cache');
          if (await cacheDir.exists()) {
            final files = cacheDir.listSync().whereType<File>();
            for (final f in files) {
              final bName = f.path.split(Platform.pathSeparator).last;
              if (bName.startsWith('recitations_shaykh_${shaykhId}_') &&
                  bName.endsWith('.json')) {
                final contents = await f.readAsString();
                final List<dynamic> jsonList = json.decode(contents);
                final list =
                    jsonList.map((jsonItem) => Recitation.fromJson(jsonItem)).toList();
                if (list.isNotEmpty) {
                  for (final item in list) {
                    if (!allRecitations.any((r) => r.id == item.id)) {
                      allRecitations.add(item);
                    }
                  }
                }
              }
            }
          }
        } catch (_) {}
      }
    }

    // Filter by mushafId if specified and there are matching elements
    if (mushafId != null && allRecitations.any((r) => r.mushafId == mushafId)) {
      allRecitations =
          allRecitations.where((r) => r.mushafId == mushafId).toList();
    }

    // 4. Always ensure downloaded recitations for this shaykh are included when offline!
    try {
      final downloadedList = await DownloadManager.getAllDownloads();
      final downloadedForShaykh = downloadedList.where((d) {
        final dShaykhId = d['shaykhId']?.toString();
        return dShaykhId == shaykhId;
      }).toList();

      for (final dl in downloadedForShaykh) {
        final dlId = dl['id']?.toString() ?? '';
        final exists = allRecitations.any((r) => r.id == dlId);
        if (!exists && dlId.isNotEmpty) {
          allRecitations.add(Recitation(
            id: dlId,
            title: dl['title'] ?? 'تلاوة',
            audioUrl: dl['filePath'] ?? '',
            reciterName: dl['reciterName'] ?? '',
            mushafId: mushafId,
          ));
        }
      }
    } catch (_) {}

    return allRecitations;
  }
}
