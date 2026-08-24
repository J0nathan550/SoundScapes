#include "app_identity.h"

// Windows header order matters here: windows.h and shobjidl.h must come
// before propkey.h, or MSVC mis-parses its PROPERTYKEY declarations.
#include <windows.h>

#include <shlobj.h>
#include <shobjidl.h>

#include <propkey.h>
#include <propvarutil.h>

#include <string>

const wchar_t kShowInstanceMessageName[] = L"J0nathan550.SoundScapes.ShowInstance";

namespace {

constexpr wchar_t kSingleInstanceMutexName[] =
    L"J0nathan550.SoundScapes.SingleInstance";

std::wstring GetShortcutPath(const wchar_t* app_name) {
  PWSTR programs_path = nullptr;
  if (FAILED(SHGetKnownFolderPath(FOLDERID_Programs, 0, nullptr,
                                   &programs_path))) {
    return L"";
  }
  std::wstring path(programs_path);
  CoTaskMemFree(programs_path);
  path += L"\\";
  path += app_name;
  path += L".lnk";
  return path;
}

bool ShortcutTargetMatches(IShellLinkW* shell_link, const wchar_t* exe_path) {
  wchar_t target[MAX_PATH] = {};
  WIN32_FIND_DATAW find_data = {};
  if (FAILED(
          shell_link->GetPath(target, MAX_PATH, &find_data, SLGP_RAWPATH))) {
    return false;
  }
  return _wcsicmp(target, exe_path) == 0;
}

}  // namespace

bool EnsureSingleInstance() {
  HANDLE mutex = ::CreateMutexW(nullptr, FALSE, kSingleInstanceMutexName);
  bool already_running = mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS;
  if (!already_running) {
    // Deliberately not closed/released: this handle needs to keep holding
    // the mutex for the app's whole lifetime, and the OS reclaims it when
    // the process exits regardless.
    return true;
  }

  UINT show_message = ::RegisterWindowMessageW(kShowInstanceMessageName);
  ::PostMessage(HWND_BROADCAST, show_message, 0, 0);
  ::CloseHandle(mutex);
  return false;
}

void EnsureStartMenuShortcut(const wchar_t* app_name, const wchar_t* aumid) {
  wchar_t exe_path[MAX_PATH] = {};
  if (GetModuleFileNameW(nullptr, exe_path, MAX_PATH) == 0) return;

  std::wstring shortcut_path = GetShortcutPath(app_name);
  if (shortcut_path.empty()) return;

  IShellLinkW* shell_link = nullptr;
  if (FAILED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER,
                               IID_IShellLinkW,
                               reinterpret_cast<void**>(&shell_link)))) {
    return;
  }

  IPersistFile* persist_file = nullptr;
  shell_link->QueryInterface(IID_IPersistFile,
                              reinterpret_cast<void**>(&persist_file));

  // If a shortcut already exists and points at this exact exe, leave it be.
  if (persist_file &&
      SUCCEEDED(persist_file->Load(shortcut_path.c_str(), STGM_READ)) &&
      ShortcutTargetMatches(shell_link, exe_path)) {
    persist_file->Release();
    shell_link->Release();
    return;
  }

  shell_link->SetPath(exe_path);
  shell_link->SetIconLocation(exe_path, 0);

  IPropertyStore* property_store = nullptr;
  if (SUCCEEDED(shell_link->QueryInterface(
          IID_IPropertyStore, reinterpret_cast<void**>(&property_store)))) {
    PROPVARIANT prop_variant;
    if (SUCCEEDED(InitPropVariantFromString(aumid, &prop_variant))) {
      property_store->SetValue(PKEY_AppUserModel_ID, prop_variant);
      property_store->Commit();
      PropVariantClear(&prop_variant);
    }
    property_store->Release();
  }

  if (persist_file) {
    persist_file->Save(shortcut_path.c_str(), TRUE);
    persist_file->Release();
  }

  shell_link->Release();
}
