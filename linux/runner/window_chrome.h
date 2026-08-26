#ifndef RUNNER_WINDOW_CHROME_H_
#define RUNNER_WINDOW_CHROME_H_

#include <gtk/gtk.h>

// Directory the running executable lives in, so bundled resources (icons)
// can be found by a path relative to it — the bundle is meant to be
// relocatable, so a build-time absolute path won't do. Returns nullptr if
// the exe's own path couldn't be resolved. Caller owns the result (free with
// g_free, or hold it in a g_autofree gchar*).
gchar* window_chrome_get_executable_dir();

// Applies the app's current theme colors to the title bar: a flat tint on
// the GtkHeaderBar (when the window has one — see my_application.cc's
// GNOME/Wayland-vs-other-WM detection) plus GTK's global dark/light
// preference. |caption_argb| and |text_argb| are 0xAARRGGBB, matching what
// Dart's Color.toARGB32() produces (see WindowThemeService). No-ops if the
// window's titlebar isn't a real GtkHeaderBar — a plain WM-drawn title bar
// can't be recolored from app code, mirroring how the Windows side quietly
// no-ops the caption color on pre-22H2 Windows. Mirrors
// Win32Window::SetTitleBarTheme.
void window_chrome_apply_title_bar_theme(GtkWindow* window,
                                          gboolean dark_mode,
                                          guint32 caption_argb,
                                          guint32 text_argb);

// Shows determinate progress on the taskbar/dock icon by emitting the
// com.canonical.Unity.LauncherEntry "Update" signal on the session bus —
// honored by Ubuntu Dock / Dash to Dock (GNOME Shell extensions) and KDE
// Plasma's task manager. |fraction| is clamped to [0.0, 1.0]. Plain GNOME
// Shell (no dock extension) and most tiling window managers have no
// equivalent at all — a real, undoggable platform gap, not a bug. Mirrors
// Win32Window::SetTaskbarProgress.
void window_chrome_set_taskbar_progress(double fraction);

// Clears the taskbar/dock progress indicator. Mirrors
// Win32Window::ClearTaskbarProgress.
void window_chrome_clear_taskbar_progress();

// Creates a tray/dock indicator for |window| (via libayatana-appindicator3,
// the StatusNotifierItem/D-Bus standard KDE/XFCE/Cinnamon speak natively —
// vanilla GNOME Shell needs the "AppIndicator and KStatusNotifierItem
// Support" extension, not installed by default; a real, undoggable gap, not
// a bug) and makes |window|'s close button hide instead of quit. Mirrors
// Win32Window::EnableTrayIcon + its WM_CLOSE handling.
//
// Unlike Windows, AppIndicator has no distinct single-click-to-restore
// gesture — StatusNotifierItem is menu-first by design. "Show SoundScapes"
// in the menu is the reliable way to restore the window; it's also wired as
// the indicator's secondary-activate target, which docks that support it
// trigger on a middle-click.
void window_chrome_enable_tray_icon(GtkApplication* app, GtkWindow* window);

#endif  // RUNNER_WINDOW_CHROME_H_
