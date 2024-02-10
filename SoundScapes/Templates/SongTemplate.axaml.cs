using Avalonia.Controls;
using Avalonia.Media;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using System;
using System.Diagnostics;
using Avalonia.Media.Imaging;

namespace SoundScapes.Templates;

public partial class SongTemplate : UserControl
{
    /// <summary>
    /// Creates SongTemplate that will later will be represented in renderPanel.
    /// </summary>
    /// <param name="author">Author of the song</param>
    /// <param name="title">Name of the song</param>
    /// <param name="songEnd">In how many minutes song will end?</param>
    /// <param name="linkImage">Link where to load image from</param>
    public SongTemplate(string author, string title, string songEnd, string linkImage)
    {
        InitializeComponent();
        Load(author, title, songEnd, linkImage);
    }

    /// <summary>
    /// Function that loads all of the visuals provided from constructor.
    /// </summary>
    /// <param name="author">Author of the music</param>
    /// <param name="title">Name of the music</param>
    /// <param name="songEnd">In how many minutes song will end?</param>
    /// <param name="linkImage">Link where to load image from</param>
    private async void Load(string author, string title, string songEnd, string linkImage)
    {
        Bitmap? imageBitmap = await LoadImageFromUrlAsync(linkImage);
        ImageBrush backgroundTemplate = new()
        {
            Opacity = 0.2,
            Stretch = Stretch.UniformToFill,
            Source = imageBitmap
        };
        borderTemplate.Background = backgroundTemplate;
        songImage.Source = imageBitmap;
        authorSong.Text = author;
        titleSong.Text = title;
        endTimeOfSong.Text = songEnd;
        RenderOptions.SetBitmapInterpolationMode(songImage, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(borderTemplate, BitmapInterpolationMode.HighQuality);
    }

    /// <summary>
    /// Load bitmap image with provided url
    /// </summary>
    /// <param name="url">your url to image</param>
    /// <returns>Bitmap with loaded image inside.</returns>
    private static async Task<Bitmap?> LoadImageFromUrlAsync(string url)
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