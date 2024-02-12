using Android.App;
using Android.Content;
using Android.OS;
using AndroidX.Core.App;

namespace SoundScapes.Android
{
    [Service]
    public class KeepRunningForever : Service
    {
        private const int SERVICE_NOTIFICATION_ID = 1001; // Unique notification ID for the service
        private const string CHANNEL_ID = "soundscapes_channel";

        public override IBinder? OnBind(Intent? intent)
        {
            return null;
        }

        public override StartCommandResult OnStartCommand(Intent? intent, StartCommandFlags flags, int startId)
        {
            // Perform any necessary initialization here

            // Start the service in the foreground
            StartForeground(SERVICE_NOTIFICATION_ID, CreateNotification());

            // Return StartCommandResult.Sticky to keep the service running indefinitely.
            return StartCommandResult.Sticky;
        }

        public override void OnDestroy()
        {
            base.OnDestroy();
        }

        private Notification CreateNotification()
        {
            // Create an explicit intent for an activity in your app
            Intent intent = new(this, typeof(MainActivity));
            intent.SetFlags(ActivityFlags.SingleTop);
            PendingIntent? pendingIntent = PendingIntent.GetActivity(this, 0, intent, PendingIntentFlags.UpdateCurrent);

            // Create the notification
            NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .SetContentTitle("SoundScapes is running!")
                .SetContentText("Click to open the app...")
                .SetSmallIcon(Resource.Drawable.Icon)
                .SetContentIntent(pendingIntent)
                .SetOngoing(true); // Notification cannot be swiped away by the user

            // Create the notification channel (for Android 8.0 and higher)
            if (Build.VERSION.SdkInt >= BuildVersionCodes.O)
            {
#pragma warning disable CA1416 // Validate platform compatibility
                NotificationChannel channel = new(CHANNEL_ID, "SoundScapes", NotificationImportance.Default);
                NotificationManager? notificationManager = GetSystemService(NotificationService) as NotificationManager;
                notificationManager?.CreateNotificationChannel(channel);
#pragma warning restore CA1416 // Validate platform compatibility
            }

            return builder.Build();
        }
    }
}