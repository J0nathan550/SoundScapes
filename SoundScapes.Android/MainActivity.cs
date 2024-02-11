using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.Media;
using Android.OS;
using Avalonia;
using Avalonia.Android;
using Avalonia.ReactiveUI;

namespace SoundScapes.Android;

[Activity(
    Label = "SoundScapes",
    Theme = "@style/MyTheme.NoActionBar",
    Icon = "@drawable/icon",
    MainLauncher = true,
    ConfigurationChanges = ConfigChanges.Orientation | ConfigChanges.ScreenSize | ConfigChanges.UiMode)]
public class MainActivity : AvaloniaMainActivity<App>
{
    protected override AppBuilder CustomizeAppBuilder(AppBuilder builder)
    {
        return base.CustomizeAppBuilder(builder)
            .WithInterFont()
            .UseReactiveUI();
    }
    protected override void OnCreate(Bundle savedInstanceState)
    {
        base.OnCreate(savedInstanceState);
        Intent? serviceIntent = new(this, typeof(KeepRunningForever));
        if (serviceIntent != null)
        {
#pragma warning disable CA1416 // Validate platform compatibility
            StartForegroundService(serviceIntent);
#pragma warning restore CA1416 // Validate platform compatibility
        }
    }
}