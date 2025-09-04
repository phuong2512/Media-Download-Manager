import 'package:flutter/material.dart';
import 'dart:io';
import 'package:media_download_manager/models/media.dart';
import 'package:media_download_manager/services/media_scanner.dart';

class MediaController extends ChangeNotifier {
  MediaController() {
    _libraryMediaList = [];
    _homeMediaList = [];
  }

  late List<Media> _libraryMediaList;
  late List<Media> _homeMediaList;
  bool _isSortNewestFirst = true;
  final MediaScannerService _scanner = MediaScannerService();

  List<Media> get libraryMediaList => _libraryMediaList;

  List<Media> get homeMediaList => _homeMediaList;

  bool get isSortNewestFirst => _isSortNewestFirst;

  List<Media> get audioList =>
      _homeMediaList.where((media) => media.type == "Audio").toList();

  List<Media> get videoList =>
      _homeMediaList.where((media) => media.type == "Video").toList();

  List<Media> filteredLibrary({required String type, required String query}) {
    final lowered = query.toLowerCase();
    return _libraryMediaList.where((media) {
      final isType = media.type == type;
      final name = media.path.split('/').last.split('.').first.toLowerCase();
      return isType && name.contains(lowered);
    }).toList();
  }

  void addToHome(Media media) {
    final isExists = _homeMediaList.any((m) => m.path == media.path);
    if (!isExists) {
      _homeMediaList.add(media);
      notifyListeners();
    }
  }

  Future<bool> deleteByPath(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _libraryMediaList.removeWhere((m) => m.path == path);
      _homeMediaList.removeWhere((m) => m.path == path);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rename(Media target, String newName) async {
    final index = _libraryMediaList.indexWhere((m) => m.path == target.path);
    if (index == -1) return false;
    final oldMedia = _libraryMediaList[index];
    try {
      final oldFile = File(oldMedia.path);
      final directoryPath = oldFile.parent.path;
      final extension = oldMedia.path.split('.').last;
      final newPath = '$directoryPath/$newName.$extension';

      if (await oldFile.exists()) {
        await oldFile.rename(newPath);
      }

      final updatedStat = await File(newPath).stat();

      final updated = Media(
        path: newPath,
        duration: oldMedia.duration,
        size: updatedStat.size,
        lastModified: updatedStat.modified,
        type: oldMedia.type,
      );

      _libraryMediaList[index] = updated;
      final homeIndex = _homeMediaList.indexWhere((m) => m.path == target.path);
      if (homeIndex != -1) {
        _homeMediaList[homeIndex] = updated;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void sortToggleByLastModified() {
    _libraryMediaList.sort(
      (a, b) => _isSortNewestFirst
          ? a.lastModified.compareTo(b.lastModified)
          : b.lastModified.compareTo(a.lastModified),
    );
    _isSortNewestFirst = !_isSortNewestFirst;
    notifyListeners();
  }

  Future<void> scanLibrary() async {
    final scanned = await _scanner.scanAll();
    _libraryMediaList = scanned;
    notifyListeners();
  }
}
