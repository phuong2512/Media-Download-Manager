String formatBytes(int bytes) {
  const int k = 1024;
  if (bytes < k) return '$bytes B';
  final double kb = bytes / k;
  if (kb < k) return '${kb.toStringAsFixed(1)} KB';
  final double mb = kb / k;
  if (mb < k) return '${mb.toStringAsFixed(1)} MB';
  final double gb = mb / k;
  return '${gb.toStringAsFixed(1)} GB';
}


