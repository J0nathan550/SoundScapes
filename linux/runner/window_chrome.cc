#include "window_chrome.h"

#include <gio/gio.h>
#include <libayatana-appindicator/app-indicator.h>
#include <limits.h>
#include <unistd.h>

#include <cstdio>

gchar* window_chrome_get_executable_dir() {
  gchar exe_path[PATH_MAX];
  ssize_t len = readlink("/proc/self/exe", exe_path, sizeof(exe_path) - 1);
  if (len == -1) return nullptr;
  exe_path[len] = '\0';
  return g_path_get_dirname(exe_path);
}

namespace {

// The freedesktop "desktop file ID" this app is identified by — see
// linux/com.j0nathan550.soundscapes.desktop, whose filename (not any field
// inside it) is what docks/shells match against. Built from the same
// APPLICATION_ID CMake feeds every translation unit (see
// linux/runner/CMakeLists.txt and my_application.cc) so the two can't drift
// apart.
constexpr char kAppUri[] = "application://" APPLICATION_ID ".desktop";

// Object path com.canonical.Unity.LauncherEntry's Update signal is emitted
// from. The spec leaves this application-determined — listeners match on
// the app_uri argument, not this path — so any stable value works; this
// follows the same "/com/canonical/unity/launcherentry/<n>" shape used by
// other implementations of the protocol.
constexpr char kLauncherEntryPath[] = "/com/canonical/unity/launcherentry/1";
constexpr char kLauncherEntryInterface[] = "com.canonical.Unity.LauncherEntry";

// Lazily connected, then reused for the process's lifetime.
GDBusConnection* GetSessionBusConnection() {
  static GDBusConnection* connection = nullptr;
  if (connection == nullptr) {
    g_autoptr(GError) error = nullptr;
    connection = g_bus_get_sync(G_BUS_TYPE_SESSION, nullptr, &error);
    if (connection == nullptr) {
      g_warning("Failed to connect to session bus for taskbar progress: %s",
                error ? error->message : "unknown error");
    }
  }
  return connection;
}

// Emits the Update signal with whatever properties |builder| holds. Takes
// ownership of |builder| the way g_variant_new's "a{sv}" varargs slot does.
void EmitLauncherEntryUpdate(GVariantBuilder* builder) {
  GDBusConnection* connection = GetSessionBusConnection();
  if (connection == nullptr) return;

  g_autoptr(GError) error = nullptr;
  g_dbus_connection_emit_signal(
      connection, nullptr /* broadcast, no specific destination */,
      kLauncherEntryPath, kLauncherEntryInterface, "Update",
      g_variant_new("(sa{sv})", kAppUri, builder), &error);
  if (error != nullptr) {
    g_warning("Failed to emit LauncherEntry Update signal: %s",
              error->message);
  }
}

// Lazily created the first time a real GtkHeaderBar is available, then
// reused for the rest of the process's life: re-adding a provider on every
// call would stack an ever-growing pile of providers on the same style
// context instead of just updating the colors it applies.
GtkCssProvider* g_title_bar_css_provider = nullptr;

// 0xAARRGGBB -> "rgba(r, g, b, a)", the format GTK's CSS parser accepts.
void FormatArgbAsCssRgba(guint32 argb, char* out, size_t out_size) {
  guint8 a = (argb >> 24) & 0xFF;
  guint8 r = (argb >> 16) & 0xFF;
  guint8 g = (argb >> 8) & 0xFF;
  guint8 b = argb & 0xFF;
  snprintf(out, out_size, "rgba(%u, %u, %u, %.3f)", r, g, b, a / 255.0);
}

void OnShowMenuItemActivate(GtkMenuItem* item, gpointer user_data) {
  gtk_window_present(GTK_WINDOW(user_data));
}

void OnQuitMenuItemActivate(GtkMenuItem* item, gpointer user_data) {
  g_application_quit(G_APPLICATION(user_data));
}

// "delete-event" handler: hides instead of destroying, so closing the
// window behaves like Windows' close-to-tray rather than quitting the app.
// Actually quitting only happens via the tray menu's "Close app completely".
gboolean OnWindowDeleteEvent(GtkWidget* widget, GdkEvent* event,
                             gpointer user_data) {
  gtk_widget_hide(widget);
  return TRUE;
}

}  // namespace

void window_chrome_apply_title_bar_theme(GtkWindow* window,
                                          gboolean dark_mode,
                                          guint32 caption_argb,
                                          guint32 text_argb) {
  GtkSettings* settings = gtk_settings_get_default();
  if (settings != nullptr) {
    g_object_set(settings, "gtk-application-prefer-dark-theme", dark_mode,
                 nullptr);
  }

  GtkWidget* titlebar = gtk_window_get_titlebar(window);
  if (titlebar == nullptr || !GTK_IS_HEADER_BAR(titlebar)) {
    // Plain WM-drawn title bar (non-GNOME X11 window manager, per
    // my_application.cc's use_header_bar check) — nothing app code can
    // recolor here, same "gracefully degrades" spirit as pre-22H2 Windows.
    return;
  }

  GtkStyleContext* style_context = gtk_widget_get_style_context(titlebar);
  if (g_title_bar_css_provider == nullptr) {
    g_title_bar_css_provider = gtk_css_provider_new();
    gtk_style_context_add_provider(style_context,
                                    GTK_STYLE_PROVIDER(g_title_bar_css_provider),
                                    GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
    gtk_style_context_add_class(style_context, "soundscapes-titlebar");
  }

  char caption_css[32];
  char text_css[32];
  FormatArgbAsCssRgba(caption_argb, caption_css, sizeof(caption_css));
  FormatArgbAsCssRgba(text_argb, text_css, sizeof(text_css));

  char css[512];
  snprintf(css, sizeof(css),
           "headerbar.soundscapes-titlebar {"
           "  background-color: %s;"
           "  background-image: none;"
           "  color: %s;"
           "}"
           "headerbar.soundscapes-titlebar .title {"
           "  color: %s;"
           "}",
           caption_css, text_css, text_css);

  g_autoptr(GError) error = nullptr;
  if (!gtk_css_provider_load_from_data(g_title_bar_css_provider, css, -1,
                                        &error)) {
    g_warning("Failed to apply title bar theme CSS: %s",
              error ? error->message : "unknown error");
  }
}

void window_chrome_set_taskbar_progress(double fraction) {
  double clamped = fraction < 0.0 ? 0.0 : (fraction > 1.0 ? 1.0 : fraction);

  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&builder, "{sv}", "progress-visible",
                         g_variant_new_boolean(TRUE));
  g_variant_builder_add(&builder, "{sv}", "progress",
                         g_variant_new_double(clamped));

  EmitLauncherEntryUpdate(&builder);
}

void window_chrome_clear_taskbar_progress() {
  GVariantBuilder builder;
  g_variant_builder_init(&builder, G_VARIANT_TYPE("a{sv}"));
  g_variant_builder_add(&builder, "{sv}", "progress-visible",
                         g_variant_new_boolean(FALSE));

  EmitLauncherEntryUpdate(&builder);
}

void window_chrome_enable_tray_icon(GtkApplication* app, GtkWindow* window) {
  g_signal_connect(window, "delete-event", G_CALLBACK(OnWindowDeleteEvent),
                    nullptr);

  g_autofree gchar* exe_dir = window_chrome_get_executable_dir();
  if (exe_dir == nullptr) {
    g_warning("Failed to resolve executable directory; tray icon disabled");
    return;
  }
  g_autofree gchar* icon_dir =
      g_build_filename(exe_dir, "data", "icons", nullptr);

  // Deliberately never unreffed: the indicator needs to stay alive and
  // registered on the bus for the whole process's life, same as the title
  // bar CSS provider above.
  //
  // app_indicator_new_with_path is marked deprecated by the library with no
  // G_GNUC_DEPRECATED_FOR replacement named — it's still the documented,
  // fully-functional constructor (the property-based alternative's exact
  // GObject property names aren't part of the public header), so silence
  // just this warning rather than reverse-engineer an undocumented
  // construction path.
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
  AppIndicator* indicator = app_indicator_new_with_path(
      APPLICATION_ID, "app_icon", APP_INDICATOR_CATEGORY_APPLICATION_STATUS,
      icon_dir);
#pragma GCC diagnostic pop
  app_indicator_set_status(indicator, APP_INDICATOR_STATUS_ACTIVE);

  GtkWidget* menu = gtk_menu_new();
  // A standalone GtkMenu has no screen of its own until something assigns
  // one — showing it before that (below) hits GTK internals that assume a
  // screen is already set (e.g. querying scale factor), logging spurious
  // Gtk-CRITICAL warnings. Borrow the real window's screen, which is
  // already realized at this point.
  gtk_menu_set_screen(GTK_MENU(menu), gtk_widget_get_screen(GTK_WIDGET(window)));

  GtkWidget* show_item = gtk_menu_item_new_with_label("Show SoundScapes");
  g_signal_connect(show_item, "activate", G_CALLBACK(OnShowMenuItemActivate),
                    window);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), show_item);

  GtkWidget* quit_item = gtk_menu_item_new_with_label("Close app completely");
  g_signal_connect(quit_item, "activate", G_CALLBACK(OnQuitMenuItemActivate),
                    app);
  gtk_menu_shell_append(GTK_MENU_SHELL(menu), quit_item);

  gtk_widget_show_all(menu);
  app_indicator_set_menu(indicator, GTK_MENU(menu));
  app_indicator_set_secondary_activate_target(indicator, show_item);
}
