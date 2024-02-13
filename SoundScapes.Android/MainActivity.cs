using Android.App;
using Android.Content;
using Android.Content.PM;
using Android.OS;
using Avalonia;
using Avalonia.Android;
using Avalonia.ReactiveUI;
using SoundScapes.Views;

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
        alertDialogBuilder.SetPositiveButton("No", (senderAlert, args) =>{/*do nothing*/});
        alertDialogBuilder.SetNegativeButton("Yes", (senderAlert, args) =>
        {
            PlayerMediaSound.PlayerMediaSoundInstance?.cancelSong?.Cancel();
            PlayerMediaSound.PlayerMediaSoundInstance?.mediaPlayer?.Stop();
            FinishAffinity(); // Close all activities of the app
            base.OnBackPressed();
            Process.KillProcess(Process.MyPid());
        });
        AlertDialog? alertDialog = alertDialogBuilder.Create();
        alertDialog?.Show();
    }
}