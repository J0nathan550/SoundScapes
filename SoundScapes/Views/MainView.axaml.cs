using Avalonia.Animation;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Media.Imaging;
using Avalonia.Media;
using System;

namespace SoundScapes.Views;

public partial class MainView : UserControl
{
    private static MainView? mainViewInstance;
    /// <summary>
    /// Main constructor of <see cref="MainView"/>
    /// </summary>
    public MainView()
    {
        InitializeComponent();
        RenderOptions.SetBitmapInterpolationMode(searchIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(libraryIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(settingsIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(statisticsIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(authorIcon, BitmapInterpolationMode.HighQuality);
        MainViewInstance = this; 
    }

    /// <summary>
    /// Singleton of the <see cref="MainView"/> used to find what control is visible now to hide it for the media player. 
    /// </summary>
    public static MainView? MainViewInstance { get => mainViewInstance; set => mainViewInstance = value; }

    /// <summary>
    /// Function switches pages depending on what button you clicked.
    /// </summary>
    private void PageSwitch_Clicked(object? sender, RoutedEventArgs e)
    {
        if (sender == searchMenuButton)
        {
            if (searchViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, searchViewPage, true, default);
            libraryViewPage.IsVisible = false;
            settingsViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
            playerViewFull.IsVisible = false;
            playerViewStripe.IsVisible = false;
            playerViewCompact.IsVisible = true;
            searchViewPage.IsVisible = true;
        }
        else if (sender == libraryMenuButton)
        {
            if (libraryViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, libraryViewPage, true, default);
            searchViewPage.IsVisible = false;
            settingsViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
            playerViewFull.IsVisible = false;
            playerViewStripe.IsVisible = false;
            playerViewCompact.IsVisible = true;
            libraryViewPage.IsVisible = true;
        }
        else if (sender == settingsMenuButton)
        {
            if (settingsViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, settingsViewPage, true, default);
            searchViewPage.IsVisible = false;
            libraryViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
            playerViewFull.IsVisible = false;
            playerViewStripe.IsVisible = false;
            playerViewCompact.IsVisible = true;
            settingsViewPage.IsVisible = true;
        }
        else if (sender == statisticsMenuButton)
        {
            if (statisticsViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, statisticsViewPage, true, default);
            searchViewPage.IsVisible = false;
            libraryViewPage.IsVisible = false;
            settingsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
            playerViewFull.IsVisible = false;
            playerViewStripe.IsVisible = false;
            playerViewCompact.IsVisible = true;
            statisticsViewPage.IsVisible = true;
        }
        else if (sender == authorMenuButton)
        {
            if (authorViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, authorViewPage, true, default);
            searchViewPage.IsVisible = false;
            libraryViewPage.IsVisible = false;
            settingsViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = false;
            playerViewFull.IsVisible = false;
            playerViewStripe.IsVisible = false;
            playerViewCompact.IsVisible = true;
            authorViewPage.IsVisible = true;
        }
    }
}