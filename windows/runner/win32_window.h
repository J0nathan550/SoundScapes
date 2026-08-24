#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

// windows.h must precede shellapi.h/shobjidl.h — both rely on macros and
// types (EXTERN_C, HDROP, etc.) that only windows.h defines.
#include <windows.h>

#include <shellapi.h>
#include <shobjidl.h>

#include <functional>
#include <memory>
#include <string>

// A class abstraction for a high DPI-aware Win32 Window. Intended to be
// inherited from by classes that wish to specialize with custom
// rendering and input handling
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // Creates a win32 window with |title| that is positioned and sized using
  // |origin| and |size|. New windows are created on the default monitor. Window
  // sizes are specified to the OS in physical pixels, hence to ensure a
  // consistent size this function will scale the inputted width and height as
  // as appropriate for the default monitor. The window is invisible until
  // |Show| is called. Returns true if the window was created successfully.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // Show the current window. Returns true if the window was successfully shown.
  bool Show();

  // Release OS resources associated with window.
  void Destroy();

  // Inserts |content| into the window tree.
  void SetChildContent(HWND content);

  // Returns the backing Window handle to enable clients to set icon and other
  // window properties. Returns nullptr if the window has been destroyed.
  HWND GetHandle();

  // If true, closing this window will quit the application.
  void SetQuitOnClose(bool quit_on_close);

  // Return a RECT representing the bounds of the current client area.
  RECT GetClientArea();

  // Applies immersive dark mode and, on Windows 11 22H2+, an accent title
  // bar color to match the app's theme. On older Windows, the DWM caption/
  // text color attributes are simply ignored by the OS and only the dark/
  // light mode takes effect.
  void SetTitleBarTheme(bool dark_mode, COLORREF caption_color, COLORREF text_color);

  // Shows a determinate progress overlay on the taskbar icon. |fraction| is
  // clamped to [0.0, 1.0]. Lazily creates the ITaskbarList3 COM object on
  // first use.
  void SetTaskbarProgress(double fraction);

  // Clears the taskbar icon's progress overlay.
  void ClearTaskbarProgress();

  // Adds this window to the notification area (tray) using the app icon,
  // with |tooltip| as its hover text. Once enabled, the window's close
  // button hides the window instead of quitting the app — left-clicking (or
  // double-clicking) the tray icon shows it again, and right-clicking opens
  // a menu with "Show SoundScapes" / "Close app completely", the latter
  // being the only way to actually exit once this is on.
  void EnableTrayIcon(const std::wstring& tooltip);

  // Removes the tray icon, if present. Also called from Destroy, so the
  // icon never lingers after the window is gone.
  void DisableTrayIcon();

 protected:
  // Processes and route salient window messages for mouse handling,
  // size change and DPI. Delegates handling of these to member overloads that
  // inheriting classes can handle.
  virtual LRESULT MessageHandler(HWND window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // Called when CreateAndShow is called, allowing subclass window-related
  // setup. Subclasses should return false if setup fails.
  virtual bool OnCreate();

  // Called when Destroy is called.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // OS callback called by message pump. Handles the WM_NCCREATE message which
  // is passed when the non-client area is being created and enables automatic
  // non-client DPI scaling so that the non-client area automatically
  // responds to changes in DPI. All other messages are handled by
  // MessageHandler.
  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // Retrieves a class instance pointer for |window|
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // Update the window frame's theme to match the system theme.
  static void UpdateTheme(HWND const window);

  // Re-applies the last theme set via SetTitleBarTheme (if any) after a
  // system colorization change, instead of letting UpdateTheme overwrite it
  // with the system default.
  void ApplyStoredTitleBarTheme();

  // Returns the lazily-created ITaskbarList3 instance, or nullptr if it
  // couldn't be created (e.g. COM not initialized).
  ITaskbarList3* GetTaskbarList();

  // Un-hides and focuses the window; used by both the tray icon's own click
  // and its menu's "Show SoundScapes" item.
  void ShowFromTray();

  // Opens the tray icon's right-click menu at the current cursor position.
  void ShowTrayContextMenu();

  // Actually exits the app via the tray menu's "Close app completely",
  // bypassing the close-to-tray behavior WM_CLOSE otherwise applies.
  void QuitFromTray();

  bool quit_on_close_ = false;

  // Set once SetTitleBarTheme has been called; see ApplyStoredTitleBarTheme.
  bool has_custom_title_bar_theme_ = false;
  bool title_bar_dark_mode_ = false;
  COLORREF title_bar_caption_color_ = 0;
  COLORREF title_bar_text_color_ = 0;

  // Lazily created by GetTaskbarList; released in Destroy.
  ITaskbarList3* taskbar_list_ = nullptr;

  // Set by EnableTrayIcon; cleared (and the icon removed) by DisableTrayIcon.
  bool tray_icon_enabled_ = false;
  NOTIFYICONDATAW tray_icon_data_ = {};

  // window handle for top level window.
  HWND window_handle_ = nullptr;

  // window handle for hosted content.
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
