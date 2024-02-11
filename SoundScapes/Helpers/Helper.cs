using LibVLCSharp.Shared;
using SpotifyExplode;
using YoutubeReExplode;

namespace SoundScapes.Helpers
{
    public static class Helper
    {
        public static MediaPlayer? player;
        public static LibVLC libVLC = new();
        public static SpotifyClient spotifyClient = new();
        public static YoutubeClient youtubeClient = new();
    }
}