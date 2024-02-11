using Avalonia.Controls;
using Avalonia.Media;
using Avalonia.Media.Imaging;

namespace SoundScapes.Views;

public partial class PlayerView : UserControl
{
    public PlayerView()
    {
        InitializeComponent();
        RenderOptions.SetBitmapInterpolationMode(songImage, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(downloadIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(backwardIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(playIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(forwardIcon, BitmapInterpolationMode.HighQuality);
    }
}