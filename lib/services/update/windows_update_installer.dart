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

    final waitFile = p.join(tempDir.path, 'soundscapes_update_wait.tmp');
    final scriptFile = File(p.join(tempDir.path, 'soundscapes_apply_update.bat'));
    await scriptFile.writeAsString(
      '@echo off\r\n'
      'setlocal\r\n'
      'set count=0\r\n'
      ':wait\r\n'
      // Redirect tasklist to a file and scan that file with findstr instead
      // of the more obvious "tasklist | find": this script runs from a
      // console-less detached process, and piping between two console
      // subsystem executables in that situation can leave find/findstr
      // hung forever reading a pipe that never delivers input — which
      // silently strands the user with the app already closed and nothing
      // to relaunch it. File redirection sidesteps consoles entirely.
      'tasklist /FI "IMAGENAME eq $exeName" > "$waitFile" 2>nul\r\n'
      'findstr /I "$exeName" "$waitFile" >nul\r\n'
      'if errorlevel 1 goto copy\r\n'
      'set /a count+=1\r\n'
      // Give up waiting after 30s and copy anyway rather than risk hanging
      // forever — with the app already closed, that would strand the user
      // with no window and no way to tell an update is still in progress.
      'if %count% geq 30 goto copy\r\n'
      'timeout /t 1 /nobreak >nul\r\n'
      'goto wait\r\n'
      ':copy\r\n'
      'del "$waitFile" 2>nul\r\n'
      // /R:5 /W:1 caps robocopy's retries — its defaults (1 million retries,
      // 30s apart) mean a single transiently-locked file (e.g. still being
      // scanned by antivirus right after extraction) would otherwise hang
      // this script, and the app it's supposed to relaunch, for days.
      'robocopy "${extractDir.path}" "$installDir" /E /IS /IT /R:5 /W:1 >nul\r\n'
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
