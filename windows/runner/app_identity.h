#ifndef RUNNER_APP_IDENTITY_H_
#define RUNNER_APP_IDENTITY_H_

// Ensures a Start Menu shortcut exists for the current executable with
// |aumid| set as its System.AppUserModel.ID, creating or repairing it if
// missing or stale (e.g. the portable exe was moved).
//
// Without a shortcut carrying a matching AUMID, Windows shell surfaces —
// notably the System Media Transport Controls "Now Playing" flyout — can't
// resolve this unpackaged app's name/icon and show "Unknown app" instead,
// regardless of SetCurrentProcessExplicitAppUserModelID.
void EnsureStartMenuShortcut(const wchar_t* app_name, const wchar_t* aumid);

#endif  // RUNNER_APP_IDENTITY_H_
