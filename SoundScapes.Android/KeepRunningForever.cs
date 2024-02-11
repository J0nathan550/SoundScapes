using Android.App;
using Android.Content;
using Android.OS;

namespace SoundScapes.Android
{
    [Service]
    public class KeepRunningForever : Service
    {
        private const int SERVICE_NOTIFICATION_ID = 1001; // Unique notification ID for the service

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
            // Create a notification channel
#pragma warning disable CA1416 // Validate platform compatibility
            NotificationChannel channel = new("1", "SoundScapes", NotificationImportance.Max);
            NotificationManager? notificationManager = (NotificationManager?)GetSystemService(NotificationService);
            notificationManager?.CreateNotificationChannel(channel);

            // Create a notification for the foreground service
            Notification.Builder builder = new Notification.Builder(this, "1")
                .SetContentTitle("SoundScapes is running!")
                .SetSmallIcon(Resource.Drawable.Icon);
#pragma warning restore CA1416 // Validate platform compatibility
            return builder.Build();
        }
    }
}