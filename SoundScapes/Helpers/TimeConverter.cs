using System;

namespace SoundScapes.Helpers
{
    /// <summary>
    /// Helpful class that converts long milliseconds to a nice string as 0:00
    /// </summary>
    public static class TimeConverter
    {
        /// <summary>
        /// Helpful function that converts long milliseconds to a nice string as 0:00
        /// </summary>
        public static string ConvertDurationToString(long durationMs)
        {
            TimeSpan timeSpan = TimeSpan.FromMilliseconds(durationMs);
            if (timeSpan.TotalHours >= 1) return timeSpan.ToString(@"h\:mm\:ss");
            else return timeSpan.ToString(@"m\:ss");
        }
    }
}