using Avalonia.Controls;
using Avalonia.Threading;
using LibVLCSharp.Shared;
using SoundScapes.Helpers;
using SpotifyExplode;
using SpotifyExplode.Tracks;
using System.Threading;
using System.Threading.Tasks;
using YoutubeReExplode;
using YoutubeReExplode.Videos.Streams;

namespace SoundScapes.Views;

public partial class PlayerMediaSound : UserControl
{
    private static PlayerMediaSound? playerMediaSoundInstance;
    public CancellationTokenSource cancelSong = new(); 
    /// <summary>
    /// Cached <see cref="SpotifyClient"/> to load track ID in YouTube.
    /// </summary>
    private readonly SpotifyClient spotifyClient = new();
    /// <summary>
    /// Cached <see cref="YoutubeClient"/> to load stream audio
    /// </summary>
    private readonly YoutubeClient youtubeClient = new();
    /// <summary>
    /// <see cref="LibVLC"/> used in VLC to load audio and load the <see cref="mediaPlayer"/>
    /// </summary>
    private readonly LibVLC libVLC = new();
    /// <summary>
    /// Placeholder to retrive end time of song.
    /// </summary>
    private Track spotifyTrack = new();
    /// <summary>
    /// <see cref="MediaPlayer"/> used to play audio in the program.
    /// </summary>
    public MediaPlayer? mediaPlayer;

    /// <summary>
    /// Main constructor <see cref="PlayerMediaSound"/>
    /// </summary>
    public PlayerMediaSound()
    {
        InitializeComponent();
        PlayerMediaSoundInstance = this;
    }

    /// <summary>
    /// Singleton of <see cref="PlayerMediaSound"/> used in <see cref="SearchView"/> to get Spotify-YouTube track id. And load audio stream.
    /// </summary>
    public static PlayerMediaSound? PlayerMediaSoundInstance { get => playerMediaSoundInstance; set => playerMediaSoundInstance = value; }

    /// <summary>
    /// Grabs <see cref="spotifyTrack"/> and loads stream of audio data, and playing music inside of <see cref="mediaPlayer"/>
    /// </summary>
    /// <param name="spotifyTrack">spotifyTrack to play sound.</param>
    public async void PlayMusic(Track spotifyTrack)
    {
        cancelSong = new CancellationTokenSource();
        await Task.Run(async () =>
        {
            try
            {
                mediaPlayer?.Stop();
                this.spotifyTrack = spotifyTrack;
                var youTubeID = await spotifyClient.Tracks.GetYoutubeIdAsync(spotifyTrack.Id, cancelSong.Token);
                var streamManifest = await youtubeClient.Videos.Streams.GetManifestAsync("https://youtube.com/watch?v=" + youTubeID, cancelSong.Token);
                var streamInfo = streamManifest.GetAudioOnlyStreams().GetWithHighestBitrate();
                var media = new Media(libVLC, streamInfo.Url, FromType.FromLocation);
                if (mediaPlayer == null)
                {
                    mediaPlayer = new(media)
                    {
                        Volume = 30,
                    };
                    mediaPlayer.Play();
                    mediaPlayer.TimeChanged += MediaPlayer_TimeChanged;
                    mediaPlayer.EndReached += MediaPlayer_EndReached;
                }
                else
                {
                    mediaPlayer.Media = media;
                    mediaPlayer.Play();
                }
                Dispatcher.UIThread.Invoke(() =>
                {
                    if (PlayerViewCompact.PlayerViewCompactInstance != null)
                    {
                        PlayerViewCompact.PlayerViewCompactInstance.playButtonCompact.IsVisible = false;
                        PlayerViewCompact.PlayerViewCompactInstance.pauseButtonCompact.IsVisible = true;
                    }
                });
            }
            catch // when task get canceled we want to stop mediaPlayer.
            {
                mediaPlayer?.Stop();
            }
        }, cancelSong.Token);
    }

    /// <summary>
    /// Events fires when MediaPlayer reaches it's end, used to switch music in the MediaPlayer. based on <see cref="SearchView.resultsPanel"/>
    /// </summary>
    /// <param name="sender"></param>
    /// <param name="e"></param>
    private void MediaPlayer_EndReached(object? sender, System.EventArgs e) => NextSong();

    /// <summary>
    /// Event fires when time is changing in <see cref="mediaPlayer"/> used to update current time passed in song.
    /// </summary>
    private void MediaPlayer_TimeChanged(object? sender, MediaPlayerTimeChangedEventArgs e)
    {
        if (PlayerViewCompact.PlayerViewCompactInstance != null)
        {
            if (cancelSong.IsCancellationRequested)
            {
                mediaPlayer?.Stop();
                return;
            }
            Dispatcher.UIThread.Invoke(() =>
            {
                PlayerViewCompact.PlayerViewCompactInstance.endTimeOfSong.Text = $"{TimeConverter.ConvertDurationToString(e.Time)} / {TimeConverter.ConvertDurationToString(spotifyTrack.DurationMs)}";
            });
        }
    }

    /// <summary>
    /// Plays next song that is inside of <see cref="SearchView.resultsPanel"/>
    /// </summary>
    public void NextSong()
    {
        if (SearchView.SearchViewInstance != null && mediaPlayer != null)
        {
            if (SearchView.SearchViewInstance.resultsPanel.Items.Count - 1 > 0)
            {
                Dispatcher.UIThread.Invoke(() =>
                {
                    if (SearchView.SearchViewInstance.resultsPanel.SelectedIndex >= SearchView.SearchViewInstance.resultsPanel.Items.Count - 1)
                    {
                        SearchView.SearchViewInstance.resultsPanel.SelectedIndex = 0;
                    }
                    else
                    {
                        SearchView.SearchViewInstance.resultsPanel.SelectedIndex++;
                    }
                });
            }
        }
    }

    /// <summary>
    /// Plays previous song that is inside of <see cref="SearchView.resultsPanel"/>
    /// </summary>
    public void PreviousSong()
    {
        if (SearchView.SearchViewInstance != null && mediaPlayer != null)
        {
            if (SearchView.SearchViewInstance.resultsPanel.Items.Count - 1 > 0)
            {
                Dispatcher.UIThread.Invoke(() =>
                {
                    if (SearchView.SearchViewInstance.resultsPanel.SelectedIndex <= 0)
                    {
                        SearchView.SearchViewInstance.resultsPanel.SelectedIndex = SearchView.SearchViewInstance.resultsPanel.Items.Count - 1;
                    }
                    else
                    {
                        SearchView.SearchViewInstance.resultsPanel.SelectedIndex--;
                    }
                });
            }
        }
    }

    /// <summary>
    /// Pauses / Plays music.
    /// </summary>
    public void PlayButtonHandle()
    {
        if (mediaPlayer != null)
        {
            switch (mediaPlayer.State)
            {
                case VLCState.Playing:
                    mediaPlayer.Pause();
                    Dispatcher.UIThread.Invoke(() =>
                    {
                        if (PlayerViewCompact.PlayerViewCompactInstance != null)
                        {
                            PlayerViewCompact.PlayerViewCompactInstance.playButtonCompact.IsVisible = true;
                            PlayerViewCompact.PlayerViewCompactInstance.pauseButtonCompact.IsVisible = false;
                        }
                    });
                    break;
                case VLCState.Paused:
                    mediaPlayer.Play();
                    Dispatcher.UIThread.Invoke(() =>
                    {
                        if (PlayerViewCompact.PlayerViewCompactInstance != null)
                        {
                            PlayerViewCompact.PlayerViewCompactInstance.playButtonCompact.IsVisible = false;
                            PlayerViewCompact.PlayerViewCompactInstance.pauseButtonCompact.IsVisible = true;
                        }
                    });
                    break;
                default:
                Dispatcher.UIThread.Invoke(() =>
                {
                    if (PlayerViewCompact.PlayerViewCompactInstance != null)
                    {
                        PlayerViewCompact.PlayerViewCompactInstance.playButtonCompact.IsVisible = true;
                        PlayerViewCompact.PlayerViewCompactInstance.pauseButtonCompact.IsVisible = false;
                    }
                });
                break;
            }
        }
    }
}