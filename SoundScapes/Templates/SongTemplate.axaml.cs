using Avalonia.Controls;
using Avalonia.Media;
using Avalonia.Media.Imaging;
using LibVLCSharp.Shared;
using SoundScapes.Helpers;
using SpotifyExplode;
using SpotifyExplode.Tracks;
using System;
using System.Diagnostics;
using System.IO;
using System.Net.Http;
using System.Threading.Tasks;
using YoutubeReExplode;
using YoutubeReExplode.Videos.Streams;

namespace SoundScapes.Templates;

public partial class SongTemplate : UserControl
{
    /// <summary>
    /// In order to play full songs we use YouTube Client because there is no API to get stream from Spotify.
    /// </summary>
    private Track spotifyTrack = new();
    /// <summary>
    /// Creates SongTemplate that will later will be represented in renderPanel.
    /// </summary>
    /// <param name="spotifyTrack">Entire spotify track</param>
    public SongTemplate(Track spotifyTrack)
    {
        InitializeComponent();
        Load(spotifyTrack);
    }

    /// <summary>
    /// Will do nothing, this was added in order to prevent any errors in IDE of Avalonia.
    /// </summary>
    public SongTemplate(){}

    /// <summary>
    /// Function that loads all of the visuals provided from constructor.
    /// </summary>
    /// <param name="spotifyTrack">Entire spotify track</param>
    private async void Load(Track spotifyTrack)
    {
        this.spotifyTrack = spotifyTrack;
        Bitmap? imageBitmap = await LoadImageFromUrlAsync(spotifyTrack.Album.Images[1].Url);
        ImageBrush backgroundTemplate = new()
        {
            Opacity = 0.3,
            Stretch = Stretch.UniformToFill,
            Source = imageBitmap
        };
        borderTemplate.Background = backgroundTemplate;
        songImage.Source = imageBitmap;
        string authors = string.Empty;
        foreach (var author in spotifyTrack.Artists)
        {
            authors += $"{author.Name}, ";
        }
        authors = authors[..^2];
        authorSong.Text = authors;
        titleSong.Text = spotifyTrack.Title;
        endTimeOfSong.Text = TimeConverter.ConvertDurationToString(spotifyTrack.DurationMs);
        RenderOptions.SetBitmapInterpolationMode(songImage, BitmapInterpolationMode.HighQuality);
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

    private async void Song_Tapped(object? sender, Avalonia.Input.TappedEventArgs e)
    {
        try
        {
            await Task.Run(async () =>
            {
                Helper.player?.Stop();
                var youTubeID = await Helper.spotifyClient.Tracks.GetYoutubeIdAsync(spotifyTrack.Id);
                var streamManifest = await Helper.youtubeClient.Videos.Streams.GetManifestAsync("https://youtube.com/watch?v=" + youTubeID, default);
                var streamInfo = streamManifest.GetAudioOnlyStreams().GetWithHighestBitrate();
                var media = new Media(Helper.libVLC, streamInfo.Url, FromType.FromLocation);
                if (Helper.player == null)
                {
                    Helper.player = new(media)
                    {
                        Volume = 30
                    };
                    Helper.player.Play();
                }
                else
                {
                    Helper.player.Media = media;
                    Helper.player.Play();
                }
            });
        }
        catch (Exception ex)
        {
            Trace.WriteLine(ex.Message);
        }
    }
}