using CommunityToolkit.Maui;
using Microsoft.Extensions.Logging;

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