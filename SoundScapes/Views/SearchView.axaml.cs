using Avalonia;
using Avalonia.Controls;
using Avalonia.Media;
using Avalonia.Threading;
using SoundScapes.Helpers;
using SoundScapes.Templates;
using SpotifyExplode;
using SpotifyExplode.Search;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Timers;

namespace SoundScapes.Views;

/// <summary>
/// This page, or view in this case. Allows user to search for the song in the internet.
/// </summary>
public partial class SearchView : UserControl
{
    /// <summary>
    /// Timer that will execute search event when user will stop typing something.
    /// </summary>
    private readonly Timer searchTimer = new() { Interval = 1000 };
    /// <summary>
    /// SpotifyClient is an high level API class that provides ability to search in the Spotify API to retrive songs. 
    /// </summary>
    private readonly SpotifyClient spotifyClient = new();

    public SearchView()
    {
        InitializeComponent();
        searchTimer.Elapsed += SearchTimer_ElapsedAsync;
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
        Dispatcher.UIThread.Invoke(() =>
        {
            resultsPanel.Children.Clear();
        });
        searchTimer.Stop();
        if (string.IsNullOrEmpty(query)) return;
        List<TrackSearchResult> results = [];
        try
        {
            results = spotifyClient.Search.GetTracksAsync(query).Result;
        }
        catch // if there is any internet issues we tell about it. 
        {
            Dispatcher.UIThread.Invoke(() =>
            {
                resultsPanel.Children.Clear();
                TextBlock notFound = new()
                {
                    Margin = new Thickness(25),
                    Foreground = new SolidColorBrush(Colors.White),
                    Text = $"Looks like you have problems with internet!",
                    TextTrimming = TextTrimming.CharacterEllipsis,
                    HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Center,
                    VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center
                };
                resultsPanel.Children.Add(notFound);
            });
            return;
        }
        if (results.Count > 0)
        {
            foreach (var result in results)
            {
                await Task.Run(async () =>
                {
                    await Task.Delay(20);
                    Dispatcher.UIThread.Invoke(() =>
                    {
                        try
                        {
                            SongTemplate songTemplate = new(result.Artists[0].Name, result.Title, TimeConverter.ConvertDurationToString(result.DurationMs), result.Album.Images[1].Url, result.PreviewUrl);
                            resultsPanel.Children.Add(songTemplate);
                        }
                        catch { } // just in case something is missing in api we just ignore the template. 
                    });
                });
            }
            return;
        }
        Dispatcher.UIThread.Invoke(() =>
        {
            resultsPanel.Children.Clear();
            TextBlock notFound = new()
            {
                Margin = new Thickness(25),
                Foreground = new SolidColorBrush(Colors.White),
                Text = $"There was no music found labeled: '{query}'!",
                TextTrimming = TextTrimming.CharacterEllipsis,
                HorizontalAlignment = Avalonia.Layout.HorizontalAlignment.Center,
                VerticalAlignment = Avalonia.Layout.VerticalAlignment.Center
            };
            resultsPanel.Children.Add(notFound);
        });
    }
}