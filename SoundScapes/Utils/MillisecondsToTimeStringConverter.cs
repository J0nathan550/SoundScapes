using System.Globalization;

namespace SoundScapes.Utils
{
    public class MillisecondsToTimeStringConverter : IValueConverter
    {
        public object Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            if (value is long milliseconds)
            {
                TimeSpan timeSpan = TimeSpan.FromMilliseconds(milliseconds);

                if (timeSpan.TotalHours >= 1)
                {
                    return $"{(int)timeSpan.TotalHours}:{timeSpan.Minutes:D2}:{timeSpan.Seconds:D2}";
                }
                else
                {
                    return $"{timeSpan.Minutes}:{timeSpan.Seconds:D2}";
                }
            }

            return string.Empty;
        }

        public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
        {
            return value?.ToString();
        }
    }
}