using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;
using Microsoft.Maui.LifecycleEvents;
using Microsoft.Maui.Platform;

namespace SoundScapes
{
    public static class MauiProgram
    {
        public static MauiApp CreateMauiApp()
        {
            var builder = MauiApp.CreateBuilder();
            builder
                .UseMauiApp<App>()
                .UseMauiCommunityToolkit()
                .UseMauiCommunityToolkitMediaElement()
                .ConfigureLifecycleEvents(events =>
                {
#if WINDOWS
                    events.AddWindows(windowsLifecycleBuilder =>
                    {
                        windowsLifecycleBuilder.OnWindowCreated(window =>
                        {
                            var handle = WinRT.Interop.WindowNative.GetWindowHandle(window);
                            var id = Microsoft.UI.Win32Interop.GetWindowIdFromWindow(handle);
                            var appWindow = Microsoft.UI.Windowing.AppWindow.GetFromWindowId(id);
                            var titleBar = appWindow.TitleBar;
                            var favoriteColor = new Windows.UI.Color()
                            {
                                R = 0x1C,
                                G = 0x1C,
                                B = 0x1C,
                            };
                            titleBar.BackgroundColor = favoriteColor;
                            titleBar.ButtonBackgroundColor = favoriteColor;
                            titleBar.ButtonForegroundColor = Colors.White.ToWindowsColor();
                            titleBar.InactiveBackgroundColor = favoriteColor;
                            titleBar.InactiveForegroundColor = Colors.White.ToWindowsColor();
                            titleBar.ButtonInactiveBackgroundColor = favoriteColor;
                            titleBar.ButtonInactiveForegroundColor = Colors.White.ToWindowsColor();
                            titleBar.ButtonForegroundColor = Colors.White.ToWindowsColor();
                            titleBar.ButtonPressedBackgroundColor = Colors.DarkGray.ToWindowsColor();
                            titleBar.ButtonHoverBackgroundColor = Colors.DarkGray.ToWindowsColor();    
                        });
                    });
#endif
                })
                .ConfigureFonts(fonts =>
                {
                    fonts.AddFont("OpenSans-Regular.ttf", "OpenSansRegular");
                    fonts.AddFont("OpenSans-Semibold.ttf", "OpenSansSemibold");
                    fonts.AddFont("Gotham-Black.ttf", "GothamBlack");
                    fonts.AddFont("Gotham-Bold.ttf", "GothamBold");
                    fonts.AddFont("GothamBook.ttf", "GothamBook");
                    fonts.AddFont("GothamMedium.ttf", "GothamMedium");
                });
#if DEBUG
            builder.Logging.AddDebug();
#endif

            return builder.Build();
        }
    }
}