import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Applies a downloaded Windows update.
///
/// There's no installer to hand off to — the release asset is a portable
/// zip of the Release build (see .github/workflows/release.yml) — and a
/// running exe can't overwrite its own files. So this extracts the zip,
/// writes a small batch script that waits for this process to exit, copies
/// the new files over the current install directory, and relaunches the
/// app, then exits this process so the script's wait condition is met.
class WindowsUpdateInstaller {
  Future<void> applyUpdate(String zipFilePath) async {
    final installDir = p.dirname(Platform.resolvedExecutable);
    final exeName = p.basename(Platform.resolvedExecutable);

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(p.join(tempDir.path, 'soundscapes_update_extracted'));
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);
    await extractFileToDisk(zipFilePath, extractDir.path);

    final scriptFile = File(p.join(tempDir.path, 'soundscapes_apply_update.bat'));
    await scriptFile.writeAsString(
      '@echo off\r\n'
      'setlocal\r\n'
      ':wait\r\n'
      'tasklist /FI "IMAGENAME eq $exeName" | find /I "$exeName" >nul\r\n'
      'if not errorlevel 1 (\r\n'
      '  timeout /t 1 /nobreak >nul\r\n'
      '  goto wait\r\n'
      ')\r\n'
      'robocopy "${extractDir.path}" "$installDir" /E /IS /IT >nul\r\n'
      'start "" "${p.join(installDir, exeName)}"\r\n'
      '(goto) 2>nul & del "%~f0"\r\n',
    );

    await Process.start(
      'cmd.exe',
      ['/c', scriptFile.path],
      mode: ProcessStartMode.detached,
      workingDirectory: tempDir.path,
    );

    exit(0);
  }
}
