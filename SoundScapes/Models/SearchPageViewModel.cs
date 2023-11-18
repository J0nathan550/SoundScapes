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
        private async Task SearchingTaskAsync()
        {
            if (string.IsNullOrEmpty(SearchQuery))
            {
                return;
            }

            IsSearching = true;
            IsSearchingEnabled = false;

            var spotify = new SpotifyClient();
            await Task.Run(async () =>
            {
                try
                {
                    TracksList.Clear();
                    foreach (var result in await spotify.Search.GetResultsAsync(SearchQuery))
                    {
                        // Use pattern matching to handle different results (albums, artists, tracks, playlists)
                        if (result is TrackSearchResult track)
                        {
                            TracksList.Add(track);
                        }
                    }
                }
                catch(Exception ex)
                {
                    if (App.Current != null && App.Current.MainPage != null)
                    {
                        await App.Current.MainPage.DisplayAlert("Помилка!", "Виникла якась помилка, спробуйте ще раз." + "\n" + ex.Message, "OK");
                    }
                }


            });

            var thread = Dispatcher.GetForCurrentThread();
            thread?.DispatchAsync(() => {
                ListViewTracks.ItemsSource = null;
                ListViewTracks.ItemsSource = TracksList;
            });

            IsSearching = false;
            IsSearchingEnabled = true; 
        }
    }
}