import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// First-run onboarding flag, stored as a tiny marker file in the app
/// documents directory. No extra dependency needed.
class OnboardingService {
  Future<File> _markerFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/.onboarding_done');
  }

  Future<bool> get isOnboardingDone async {
    try {
      return await (await _markerFile()).exists();
    } on Exception {
      return false;
    }
  }

  Future<void> markDone() async {
    final file = await _markerFile();
    await file.writeAsString(DateTime.now().toIso8601String());
  }
}
