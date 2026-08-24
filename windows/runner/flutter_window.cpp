#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

namespace {

// Windows COLORREF is 0x00BBGGRR; Flutter's Color.toARGB32() is 0xAARRGGBB.
COLORREF ArgbToColorRef(int64_t argb) {
  auto r = static_cast<BYTE>((argb >> 16) & 0xFF);
  auto g = static_cast<BYTE>((argb >> 8) & 0xFF);
  auto b = static_cast<BYTE>(argb & 0xFF);
  return RGB(r, g, b);
}

std::optional<int64_t> GetInt(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(std::string(key)));
  if (it == map.end()) return std::nullopt;
  if (auto v = std::get_if<int32_t>(&it->second)) return *v;
  if (auto v = std::get_if<int64_t>(&it->second)) return *v;
  return std::nullopt;
}

std::optional<bool> GetBool(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(std::string(key)));
  if (it == map.end()) return std::nullopt;
  if (auto v = std::get_if<bool>(&it->second)) return *v;
  return std::nullopt;
}

std::optional<double> GetDouble(const flutter::EncodableMap& map, const char* key) {
  auto it = map.find(flutter::EncodableValue(std::string(key)));
  if (it == map.end()) return std::nullopt;
  if (auto v = std::get_if<double>(&it->second)) return *v;
  return std::nullopt;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  window_channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      flutter_controller_->engine()->messenger(), "soundscapes/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        const auto& method = call.method_name();
        const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

        if (method == "setTitleBarColors") {
          auto caption = args ? GetInt(*args, "caption") : std::nullopt;
          auto text = args ? GetInt(*args, "text") : std::nullopt;
          auto dark_mode = args ? GetBool(*args, "darkMode") : std::nullopt;
          if (!caption || !text || !dark_mode) {
            result->Error("bad_args", "Expected caption, text (ARGB ints) and darkMode (bool)");
            return;
          }
          SetTitleBarTheme(*dark_mode, ArgbToColorRef(*caption), ArgbToColorRef(*text));
          result->Success();
        } else if (method == "setTaskbarProgress") {
          auto progress = args ? GetDouble(*args, "progress") : std::nullopt;
          if (!progress) {
            result->Error("bad_args", "Expected a progress double");
            return;
          }
          SetTaskbarProgress(*progress);
          result->Success();
        } else if (method == "clearTaskbarProgress") {
          ClearTaskbarProgress();
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
