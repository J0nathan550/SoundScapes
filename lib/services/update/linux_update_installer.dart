import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Applies a downloaded Linux update.
///
/// Mirrors [WindowsUpdateInstaller]'s shape and reasoning — the release
/// asset is a portable tar.gz of the Release bundle (see
/// .github/workflows/release.yml), and a running executable can't overwrite
/// its own files — but the POSIX side is simpler: there's no
/// console-subsystem pipe-hang problem to route around (see the Windows
/// version's tasklist/findstr file-redirection comment), so process
/// liveness is just a plain `kill -0` poll.
class LinuxUpdateInstaller {
  Future<void> applyUpdate(String tarGzFilePath) async {
    final installDir = p.dirname(Platform.resolvedExecutable);
    final exeName = p.basename(Platform.resolvedExecutable);
    final currentPid = pid;

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempDir.path, 'soundscapes_update_extracted'));
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);
    // Auto-detects .tar.gz by extension and (on POSIX) restores each
    // entry's Unix permission bits, including the executable bit — no
    // separate chmod step needed after extraction, unlike the yt-dlp
    // binary download in ytdlp_service.dart.
    await extractFileToDisk(tarGzFilePath, extractDir.path);

    final scriptFile = File(p.join(tempDir.path, 'soundscapes_apply_update.sh'));
    await scriptFile.writeAsString(
      '#!/bin/sh\n'
      'count=0\n'
      'while kill -0 $currentPid 2>/dev/null; do\n'
      '  count=\$((count + 1))\n'
      // Give up waiting after 30s and copy anyway rather than risk hanging
      // forever — with the app already closed, that would strand the user
      // with no window and no way to tell an update is still in progress.
      '  if [ "\$count" -ge 30 ]; then break; fi\n'
      '  sleep 1\n'
      'done\n'
      'cp -a "${extractDir.path}/." "$installDir/"\n'
      '"${p.join(installDir, exeName)}" &\n'
      'rm -- "\$0"\n',
    );
    await Process.run('chmod', ['+x', scriptFile.path]);

    await Process.start(
      '/bin/sh',
      [scriptFile.path],
      mode: ProcessStartMode.detached,
      workingDirectory: tempDir.path,
    );

    exit(0);
  }
}
