#ifndef RUNNER_APP_IDENTITY_H_
#define RUNNER_APP_IDENTITY_H_

// Registered window message (see RegisterWindowMessageW) an already-running
// instance is asked to handle by showing/focusing itself. Shared between
// EnsureSingleInstance, which broadcasts it, and Win32Window, which listens
// for it — both resolve the same string to the same message ID at runtime,
// so nothing needs to be passed between the two directly.
extern const wchar_t kShowInstanceMessageName[];

// Claims a named mutex identifying this app. Returns true if this is the
// only running instance, in which case the caller should proceed to create
// its window as normal. Returns false if another instance already holds the
// mutex — this has already broadcast kShowInstanceMessageName to ask it to
// show itself, so the caller should exit immediately without creating one.
bool EnsureSingleInstance();

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
