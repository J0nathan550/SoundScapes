using Avalonia.Media.Imaging;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System;

namespace SoundScapes.Helpers
{
    public static class BitmapImageLoader
    {
        /// <summary>
        /// Load bitmap image with provided url
        /// </summary>
        /// <param name="url">your url to image</param>
        /// <returns>Bitmap with loaded image inside.</returns>
        public static async Task<Bitmap?> LoadImageFromUrlAsync(string url)
        {
            try
            {
                using HttpClient client = new();
                var streamBytes = await client.GetByteArrayAsync(url);
                using MemoryStream memoryStream = new(streamBytes);
                Bitmap bitmap = new(memoryStream);
                return bitmap;
            }
            catch (Exception ex)
            {
                Trace.WriteLine($"Error loading image: {ex.Message}");
                return null;
            }
        }
    }
}