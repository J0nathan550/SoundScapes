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
                catch 
                {
                    //if (App.Current != null && App.Current.MainPage != null)
                    //{
                    //    await App.Current.MainPage.DisplayAlert("Помилка!", "Виникла якась помилка, спробуйте ще раз." + "\n" + ex.Message, "OK");
                    //}
                    //CancellationTokenSource cancellationTokenSource = new CancellationTokenSource();

                    //string text = "Виникла якась помилка, спробуйте ще раз.";
                    //ToastDuration duration = ToastDuration.Short;
                    //double fontSize = 14;

                    //var toast = Toast.Make(text, duration, fontSize);

                    //await toast.Show(cancellationTokenSource.Token);
                    var snackBar = Snackbar.Make("Looks like you have problem with internet!", null, "OK", TimeSpan.FromSeconds(5), new SnackbarOptions()
                    {
                        BackgroundColor = new Color(0x2C, 0x2C, 0x2C),
                        CornerRadius = 6,
                        TextColor = new Color(255, 255, 255),
                        ActionButtonTextColor = new Color(255, 255 ,255)
                    });
                    await snackBar.Show();
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