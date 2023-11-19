using SoundScapes.Models;
using SpotifyExplode;
using YoutubeExplode;
using YoutubeExplode.Videos.Streams;

namespace SoundScapes.Pages;

public partial class SearchPage : ContentPage
{
    private SearchPageViewModel searchPageViewModel = new();
    public SearchPage()
	{
		InitializeComponent();
        searchPageViewModel.ListViewTracks = listViewTrack;
        BindingContext = searchPageViewModel;
    }

    private async void ListViewTrack_ItemSelected(object sender, SelectedItemChangedEventArgs e)
    {
        mp3player.Stop();
        mp3player.Source = null;
        SpotifyClient spotifyYouTubeRetrive = new();
        YoutubeClient? youtube = new();
        string? youtubeID = await spotifyYouTubeRetrive.Tracks.GetYoutubeIdAsync(searchPageViewModel.TracksList[e.SelectedItemIndex].Url).ConfigureAwait(false);
        var streamManifest = youtube.Videos.Streams.GetManifestAsync($"https://youtube.com/watch?v={youtubeID}");
        var streamInfo = streamManifest.Result.GetAudioStreams().GetWithHighestBitrate();
        Dispatcher.Dispatch(() =>
        {
            mp3player.Source = streamInfo.Url;
            mp3player.Play();
        });
    }
}