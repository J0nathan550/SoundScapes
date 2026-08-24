#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <flutter_windows.h>
#include <shobjidl.h>
#include <windows.h>

#include <algorithm>

#include "app_identity.h"
#include "flutter_window.h"
#include "utils.h"

namespace {

// Returns the top-left origin, in the same logical-pixel space
// Win32Window::Create expects, that centers a window of |size| on the
// primary monitor's work area.
Win32Window::Point GetCenteredOrigin(const Win32Window::Size& size) {
  POINT origin_point = {0, 0};
  HMONITOR monitor = MonitorFromPoint(origin_point, MONITOR_DEFAULTTOPRIMARY);
  UINT dpi = FlutterDesktopGetDpiForMonitor(monitor);
  double scale_factor = dpi / 96.0;

  MONITORINFO monitor_info = {};
  monitor_info.cbSize = sizeof(monitor_info);
  GetMonitorInfo(monitor, &monitor_info);

  int monitor_width = monitor_info.rcWork.right - monitor_info.rcWork.left;
  int monitor_height = monitor_info.rcWork.bottom - monitor_info.rcWork.top;
  int scaled_width = static_cast<int>(size.width * scale_factor);
  int scaled_height = static_cast<int>(size.height * scale_factor);

  int physical_x = monitor_info.rcWork.left + (monitor_width - scaled_width) / 2;
  int physical_y = monitor_info.rcWork.top + (monitor_height - scaled_height) / 2;

  return Win32Window::Point(
      static_cast<unsigned int>(std::max(0, physical_x) / scale_factor),
      static_cast<unsigned int>(std::max(0, physical_y) / scale_factor));
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Only one instance should ever be running: if SoundScapes is already
  // open (including hidden in the tray), this asks it to show itself
  // instead of launching a second, independent instance.
  if (!EnsureSingleInstance()) {
    return EXIT_SUCCESS;
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Give this unpackaged app an explicit identity so Windows shell surfaces
  // (taskbar grouping, and the System Media Transport Controls "Now
  // Playing" flyout) show "SoundScapes" instead of "Unknown app". The AUMID
  // alone isn't enough for Explorer to resolve a name/icon for an
  // unpackaged exe — it also needs a Start Menu shortcut carrying the same
  // AUMID, which we create/repair here.
  constexpr wchar_t kAppUserModelId[] = L"J0nathan550.SoundScapes";
  ::SetCurrentProcessExplicitAppUserModelID(kAppUserModelId);
  EnsureStartMenuShortcut(L"SoundScapes", kAppUserModelId);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Size size(1280, 720);
  Win32Window::Point origin = GetCenteredOrigin(size);
  if (!window.Create(L"SoundScapes", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  window.EnableTrayIcon(L"SoundScapes");

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
