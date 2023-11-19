using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Maui.Core;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using SpotifyExplode;
using SpotifyExplode.Search;

namespace SoundScapes.Models
{
    public partial class SearchPageViewModel : ObservableObject
    {
        [ObservableProperty]
        private bool isSearching = false;
        [ObservableProperty]
        private bool isSearchingEnabled = true;
        [ObservableProperty]
        private string searchQuery = string.Empty;
        [ObservableProperty]
        private List<TrackSearchResult> tracksList = [];
        [ObservableProperty]
        private ListView listViewTracks = new();

        [RelayCommand]
        private async Task SearchingTaskAsync(CancellationToken token)
        {
            if (string.IsNullOrEmpty(SearchQuery))
            {
                return;
            }

            IsSearching = true;
            IsSearchingEnabled = false;

            var spotify = new SpotifyClient();

            try
            {
                TracksList.Clear();
                foreach (var result in await spotify.Search.GetResultsAsync(SearchQuery, SearchFilter.Track, 0, 50, token).ConfigureAwait(false))
                {
                    // Use pattern matching to handle different results (albums, artists, tracks, playlists)
                    if (result is TrackSearchResult track)
                    {
                        TracksList.Add(track);
                    }
                }
            }
            catch
            {
                var snackBar = Snackbar.Make("Looks like you have problem with internet!", null, "OK", TimeSpan.FromSeconds(5), new SnackbarOptions()
                {
                    BackgroundColor = new Color(0x2C, 0x2C, 0x2C),
                    CornerRadius = 6,
                    TextColor = new Color(255, 255, 255),
                    ActionButtonTextColor = new Color(255, 255, 255)
                });
                await snackBar.Show(token).ConfigureAwait(false);
            }

            IsSearching = false;
            IsSearchingEnabled = true;
            ListViewTracks.Dispatcher.Dispatch(() =>
            {
                ListViewTracks.ItemsSource = null;
                ListViewTracks.ItemsSource = TracksList;
            });
        }
    }
}