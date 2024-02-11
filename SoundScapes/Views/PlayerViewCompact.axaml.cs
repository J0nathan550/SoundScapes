using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Media;
using Avalonia.Media.Imaging;

namespace SoundScapes.Views;

public partial class PlayerViewCompact : UserControl
{
    private static PlayerViewCompact? playerViewCompactInstance;

    /// <summary>
    /// Main constructor of <see cref="PlayerViewCompact"/>
    /// </summary>
    public PlayerViewCompact()
    {
        InitializeComponent();
        RenderOptions.SetBitmapInterpolationMode(songImage, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(downloadIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(backwardIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(playIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(pauseIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(forwardIcon, BitmapInterpolationMode.HighQuality);
        PlayerViewCompactInstance = this;
    }

    /// <summary>
    /// Singleton of this Page or User Control if you will. Used to retrive metadata in <see cref="SearchView"/> and represent it in visuals.
    /// </summary>
    public static PlayerViewCompact? PlayerViewCompactInstance { get => playerViewCompactInstance; set => playerViewCompactInstance = value; }

    /// <summary>
    /// Main function that loads all visuals in the <see cref="PlayerViewCompact"/> from mainly <see cref="SearchView"/>
    /// </summary>
    public void LoadContentToPlayerViewCompact(Bitmap icon, string title, string author, string endTime)
    {
        songImage.Source = icon;
        ImageBrush backgroundTemplate = new()
        {
            Opacity = 0.3,
            Stretch = Stretch.UniformToFill,
            Source = icon
        };
        mediaPlayerBorder.Background = backgroundTemplate;
        authorSong.Text = author;
        titleSong.Text = title;
        endTimeOfSong.Text = "0:00 / " + endTime;
    }

    /// <summary>
    /// Does nothing for now, should save song to library and download it.
    /// </summary>
    private void DownloadButton_Click(object? sender, RoutedEventArgs e) { }
    /// <summary>
    /// When button is pressed plays previous song
    /// </summary>
    private void PreviousSongButton_Click(object? sender, RoutedEventArgs e) => PlayerMediaSound.PlayerMediaSoundInstance?.PreviousSong();
    /// <summary>
    /// When button is pressed plays next song
    /// </summary>
    private void NextSongButton_Click(object? sender, RoutedEventArgs e) => PlayerMediaSound.PlayerMediaSoundInstance?.NextSong();
    /// <summary>
    /// When button is pressed switches between paused / play song.
    /// </summary>
    private void PlayButton_Click(object? sender, RoutedEventArgs e) => PlayerMediaSound.PlayerMediaSoundInstance?.PlayButtonHandle();
}