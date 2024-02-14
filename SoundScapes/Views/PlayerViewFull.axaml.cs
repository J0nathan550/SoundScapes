using Avalonia.Controls;

namespace SoundScapes.Views;

public partial class PlayerViewFull : UserControl
{
    private static PlayerViewFull? playerViewFullInstance;
    public PlayerViewFull()
    {
        InitializeComponent();
        PlayerViewFullInstance = this; 
    }
    /// <summary>
    /// Singleton of <see cref="playerViewFullInstance"/>. Used to show the full song description of what are you listening to in media player.
    /// </summary>
    public static PlayerViewFull? PlayerViewFullInstance { get => playerViewFullInstance; set => playerViewFullInstance = value; }
}