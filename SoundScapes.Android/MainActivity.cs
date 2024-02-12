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

    protected override void OnDestroy()
    {
        base.OnDestroy();
        Intent serviceIntent = new(this, typeof(KeepRunningForever));
        StopService(serviceIntent);
    }

    public override void OnBackPressed()
    {
        // Handle the back button press
        // Close the application gracefully
        AlertDialog.Builder? alertDialogBuilder = new(this);
        alertDialogBuilder.SetMessage("Are you sure you want to quit from SoundScapes?\n\nIt will turn off current music that is playing.");
        alertDialogBuilder.SetCancelable(false);
        alertDialogBuilder.SetPositiveButton("Yes", (senderAlert, args) =>
        {
            FinishAffinity(); // Close all activities of the app
        });
        alertDialogBuilder.SetNegativeButton("No", (senderAlert, args) =>
        {
            // Do nothing, dismiss the dialog
        });
        AlertDialog? alertDialog = alertDialogBuilder.Create();
        alertDialog?.Show();
    }
}