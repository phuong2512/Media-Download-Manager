import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:media_download_manager/models/media.dart';

class MediaScannerService {
  static const _audioExts = ['.mp3', '.m4a', '.wav', '.aac', '.flac', '.ogg'];
  static const _videoExts = ['.mp4', '.mkv', '.mov', '.avi', '.webm', '.3gp'];

  Future<List<Media>> scanAll() async {
    final roots = await _getCandidateRoots();
    final files = <File>[];
    for (final dir in roots) {
      if (await dir.exists()) {
        files.addAll(_listMediaFilesRecursive(dir));
      }
    }

    final items = <Media>[];
    for (final f in files) {
      final stat = await f.stat();
      final ext = p.extension(f.path).toLowerCase();
      final isAudio = _audioExts.contains(ext);
      final isVideo = _videoExts.contains(ext);
      if (!isAudio && !isVideo) continue;
      items.add(
        Media(
          path: f.path,
          duration: '00:00',
          size: stat.size,
          lastModified: stat.modified,
          type: isAudio ? 'Audio' : 'Video',
        ),
      );
    }
    return items;
  }

  Future<List<Directory>> _getCandidateRoots() async {
    final result = <Directory>[];
    try {
      if (Platform.isAndroid) {
        final downloads = Directory('/storage/emulated/0/Download');
        final music = Directory('/storage/emulated/0/Music');
        final movies = Directory('/storage/emulated/0/Movies');
        final dcim = Directory('/storage/emulated/0/DCIM');
        final pictures = Directory('/storage/emulated/0/Pictures');
        result.addAll([downloads, music, movies, dcim, pictures]);
        final extDirs = await getExternalStorageDirectories();
        if (extDirs != null) {
          result.addAll(extDirs);
        }
      } else if (Platform.isIOS) {
        final docs = await getApplicationDocumentsDirectory();
        result.add(docs);
      } else {
        final docs = await getDownloadsDirectory();
        if (docs != null) result.add(docs);
      }
    } catch (_) {}
    return result;
  }

  List<File> _listMediaFilesRecursive(Directory dir) {
    final collected = <File>[];
    try {
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (_audioExts.contains(ext) || _videoExts.contains(ext)) {
            collected.add(entity);
          }
        }
      }
    } catch (_) {}
    return collected;
  }
}


