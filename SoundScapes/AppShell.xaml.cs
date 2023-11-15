using SoundScapes.Pages;

namespace SoundScapes
{
    public partial class AppShell : Shell
    {
        public AppShell()
        {
            InitializeComponent();
#if WINDOWS || MACCATALYST
            SetTabBarIsVisible(this, false);
            SetFlyoutBehavior(this, FlyoutBehavior.Flyout);
            SetNavBarIsVisible(this, false);
#else
            SetTabBarIsVisible(this, true);
            SetFlyoutBehavior(this, FlyoutBehavior.Disabled);
#endif
        }
    }
}