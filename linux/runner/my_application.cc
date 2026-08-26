#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "window_chrome.h"

namespace {

// Same channel name/contract as Windows' "soundscapes/window" — see
// windows/runner/flutter_window.cpp and
// lib/services/window/{window_theme_service,taskbar_progress_service}.dart.
constexpr char kWindowChannelName[] = "soundscapes/window";

FlValue* LookupOrNull(FlValue* map, const char* key) {
  if (map == nullptr || fl_value_get_type(map) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }
  return fl_value_lookup_string(map, key);
}

void WindowChannelMethodCallCb(FlMethodChannel* channel,
                                FlMethodCall* method_call,
                                gpointer user_data) {
  GtkApplication* app = GTK_APPLICATION(user_data);
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "setTitleBarColors") == 0) {
    FlValue* caption = LookupOrNull(args, "caption");
    FlValue* text = LookupOrNull(args, "text");
    FlValue* dark_mode = LookupOrNull(args, "darkMode");
    GtkWindow* window = gtk_application_get_active_window(app);
    if (caption == nullptr || text == nullptr || dark_mode == nullptr ||
        window == nullptr) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "bad_args",
          "Expected caption, text (ARGB ints) and darkMode (bool)", nullptr));
    } else {
      window_chrome_apply_title_bar_theme(
          window, fl_value_get_bool(dark_mode),
          static_cast<guint32>(fl_value_get_int(caption)),
          static_cast<guint32>(fl_value_get_int(text)));
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (g_strcmp0(method, "setTaskbarProgress") == 0) {
    FlValue* progress = LookupOrNull(args, "progress");
    if (progress == nullptr) {
      response = FL_METHOD_RESPONSE(fl_method_error_response_new(
          "bad_args", "Expected a progress double", nullptr));
    } else {
      window_chrome_set_taskbar_progress(fl_value_get_float(progress));
      response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
    }
  } else if (g_strcmp0(method, "clearTaskbarProgress") == 0) {
    window_chrome_clear_taskbar_progress();
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to respond to soundscapes/window call: %s",
              error->message);
  }
}

}  // namespace

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  gtk_widget_show(gtk_widget_get_toplevel(GTK_WIDGET(view)));
}

// Sets the window icon from the PNG installed alongside the bundle's data
// directory (see the install() rule for it in linux/CMakeLists.txt). A
// missing/unreadable icon is a cosmetic issue, not fatal — logged and
// otherwise ignored, same spirit as the Windows title-bar theming's
// best-effort error handling.
static void apply_window_icon(GtkWindow* window) {
  g_autofree gchar* exe_dir = window_chrome_get_executable_dir();
  if (!exe_dir) return;
  g_autofree gchar* icon_path =
      g_build_filename(exe_dir, "data", "icons", "app_icon.png", nullptr);
  g_autoptr(GError) error = nullptr;
  if (!gtk_window_set_icon_from_file(window, icon_path, &error)) {
    g_warning("Failed to load window icon from %s: %s", icon_path,
              error ? error->message : "unknown error");
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  // With G_APPLICATION_NON_UNIQUE no longer set (see my_application_new),
  // GIO enforces single-instance for us via the session D-Bus: a second
  // launch registers against the same well-known name, GIO redirects it into
  // this process, and activate() runs again here instead of a second
  // process/window being created. GtkApplication already tracks its own
  // window, so a non-null existing one just needs presenting/focusing —
  // mirrors ShowFromTray()'s SW_RESTORE + SetForegroundWindow on Windows.
  GtkWindow* existing_window =
      gtk_application_get_active_window(GTK_APPLICATION(application));
  if (existing_window != nullptr) {
    gtk_window_present(existing_window);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "SoundScapes");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "SoundScapes");
  }

  apply_window_icon(window);
  window_chrome_enable_tray_icon(GTK_APPLICATION(application), window);

  gtk_window_set_default_size(window, 1280, 720);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* window_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      kWindowChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      window_channel, WindowChannelMethodCallCb, application, nullptr);

  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  // No explicit "flags" (defaults to G_APPLICATION_FLAGS_NONE): this is what
  // makes GIO enforce single-instance via the session D-Bus — see
  // my_application_activate's existing_window check above.
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     nullptr));
}
