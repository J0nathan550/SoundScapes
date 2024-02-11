using Avalonia.Media.Imaging;
using SpotifyExplode.Tracks;

namespace SoundScapes.Models
{
    /// <summary>
    /// Simple model to represent data in result panel of SearchView.
    /// </summary>
    public class SongInfo
    {
        public Bitmap? SongImage { get; set; }
        public string SongAuthor { get; set; } = "...";
        public string SongTitle { get; set; } = "...";
        public string SongEnd { get; set; } = "0:00";
        public Track SongUrl { get; set; } = new Track();
    }
}