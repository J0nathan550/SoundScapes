using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;
using Avalonia.Media.Imaging;
using Avalonia.Threading;
using SoundScapes.Helpers;
using SoundScapes.Models;
using SpotifyExplode;
using SpotifyExplode.Search;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Threading.Tasks;
using System.Timers;

namespace SoundScapes.Views;

/// <summary>
/// This page, or view in this case. Allows user to search for the song in the internet.
/// </summary>
public partial class SearchView : UserControl
{
    private static SearchView? searchViewInstance;
    /// <summary>
    /// Timer that will execute search event when user will stop typing something.
    /// </summary>
    private readonly Timer searchTimer = new() { Interval = 1000 };
    /// <summary>
    /// SpotifyClient is an high level API class that provides ability to search in the Spotify API to retrive songs. 
    /// </summary>
    private readonly SpotifyClient spotifyClient = new();
    /// <summary>
    /// songList is a list that you get from searching songs, used to show items in <see cref="resultsPanel"/>
    /// </summary>
    public readonly ObservableCollection<SongInfo> songList = [];
    /// <summary>
    /// Singleton of this Page or User Control if you will. Used to check the values in <see cref="resultsPanel"/>. in <see cref="PlayerMediaSound"/>
    /// </summary>
    public static SearchView? SearchViewInstance { get => searchViewInstance; set => searchViewInstance = value; }

    /// <summary>
    /// Main constructor of SearchView.
    /// </summary>
    public SearchView()
    {
        InitializeComponent();
        resultsPanel.ItemsSource = songList;
        searchTimer.Elapsed += SearchTimer_ElapsedAsync;
        SearchViewInstance = this;  
    }

    /// <summary>
    /// Event that when you are typing any symbol or else restarts the timer to not execute <see cref="SearchTimer_ElapsedAsync(object?, ElapsedEventArgs)"/>
    /// </summary>
    private void SearchTextBox_TextChanged(object? sender, TextChangedEventArgs e) => RestartTimer();
   
    /// <summary>
    /// Restarts the Search Timer.
    /// </summary>
    private void RestartTimer()
    {
        searchTimer.Stop();
        searchTimer.Start();
    }

    /// <summary>
    /// Timer function that when specified amount of seconds will pass, will execute search command in the API.
    /// </summary>
    private async void SearchTimer_ElapsedAsync(object? sender, ElapsedEventArgs e)
    {
        string? query = string.Empty;
        Dispatcher.UIThread.Invoke(() =>
        {
            query = searchTextBox.Text;
        });
        await SearchSongs(query);
    }

    /// <summary>
    /// Function that with specified query paramater will return in <see cref="resultsPanel"/> all founded metadata songs.
    /// </summary>
    /// <param name="query">Whatever you are looking for.</param>
    /// <returns>Songs metadata in <see cref="resultsPanel"/></returns>
    private async Task SearchSongs(string? query)
    {
        songList.Clear();
        searchTimer.Stop();
        if (string.IsNullOrEmpty(query)) return;
        List<TrackSearchResult> results = [];
        try
        {
            results = spotifyClient.Search.GetTracksAsync(query).Result;
        }
        catch // if there is any internet issues we tell about it. 
        {
            songList.Clear();
            NoContentFound(query);
            return;
        }
        if (results.Count > 0)
        {
            foreach (var result in results)
            {
                if (songList.Count > 50)
                {
                    songList.Clear();
                    return;
                }
                await Task.Run(async () =>
                {
                    try
                    {
                        var image = await BitmapImageLoader.LoadImageFromUrlAsync(result.Album.Images[1].Url);
                        string artists = string.Empty;
                        foreach (var artist in result.Artists)
                        {
                            artists += $"{artist.Name}, ";
                        }
                        artists = artists[..^2];
                        songList.Add(new SongInfo()
                        {
                            SongImage = image,
                            SongTitle = result.Title,
                            SongEnd = TimeConverter.ConvertDurationToString(result.DurationMs),
                            SongAuthor = artists,
                            SongUrl = result
                        });
                    }
                    catch { }
                });
            }
            return;
        }
        songList.Clear();
        NoContentFound(query);
    }

    /// <summary>
    /// When item was clicked in <see cref="resultsPanel"/> it checks the item index that was clicked, and based on it changes certain visuals.
    /// And plays specific song. 
    /// </summary>
    private void SearchResult_SelectionChanged(object? sender, SelectionChangedEventArgs e)
    {
        if (PlayerViewCompact.PlayerViewCompactInstance != null && PlayerMediaSound.PlayerMediaSoundInstance != null)
        {
            PlayerMediaSound.PlayerMediaSoundInstance.cancelSong.Cancel();
            Bitmap? icon = songList[resultsPanel.SelectedIndex].SongImage;
            if (icon != null)
            {
                PlayerViewCompact.PlayerViewCompactInstance.LoadContentToPlayerViewCompact(icon, songList[resultsPanel.SelectedIndex].SongTitle, songList[resultsPanel.SelectedIndex].SongAuthor, songList[resultsPanel.SelectedIndex].SongEnd);
                PlayerMediaSound.PlayerMediaSoundInstance.PlayMusic(songList[resultsPanel.SelectedIndex].SongUrl);
            }
        }
    }

    /// <summary>
    /// Helpful function that shows something was not found as the visual in the window.
    /// </summary>
    /// <param name="query">Query, or text of what was not found</param>
    private static void NoContentFound(string query)
    {
        Dispatcher.UIThread.Invoke(() =>
        {
            TextBlock notFound = new()
            {
                Margin = new Thickness(25),
                Foreground = new SolidColorBrush(Colors.White),
                Text = $"There was no music found labeled: '{query}'!",
                TextTrimming = TextTrimming.CharacterEllipsis,
                HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Center,
                VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center
            };
            Grid.SetRow(notFound, 1);
        });
    }
}