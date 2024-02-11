using Avalonia.Animation;
using Avalonia.Controls;
using Avalonia.Interactivity;
using Avalonia.Media.Imaging;
using Avalonia.Media;
using System;

namespace SoundScapes.Views;

public partial class MainView : UserControl
{
    public MainView()
    {
        InitializeComponent();
        RenderOptions.SetBitmapInterpolationMode(searchIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(libraryIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(settingsIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(statisticsIcon, BitmapInterpolationMode.HighQuality);
        RenderOptions.SetBitmapInterpolationMode(authorIcon, BitmapInterpolationMode.HighQuality);
    }

    private void PageSwitch_Clicked(object? sender, RoutedEventArgs e)
    {
        if (sender == searchMenuButton)
        {
            if (searchViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, searchViewPage, true, default);
            searchViewPage.IsVisible = true;
            libraryViewPage.IsVisible = false;
            settingsViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
        }
        else if (sender == libraryMenuButton)
        {
            if (libraryViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, libraryViewPage, true, default);
            searchViewPage.IsVisible = false;
            libraryViewPage.IsVisible = true;
            settingsViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
        }
        else if (sender == settingsMenuButton)
        {
            if (settingsViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, settingsViewPage, true, default);
            searchViewPage.IsVisible = false;
            libraryViewPage.IsVisible = false;
            settingsViewPage.IsVisible = true;
            statisticsViewPage.IsVisible = false;
            authorViewPage.IsVisible = false;
        }
        else if (sender == statisticsMenuButton)
        {
            if (statisticsViewPage.IsVisible) return;
            var transition = new PageSlide(TimeSpan.FromMilliseconds(300), PageSlide.SlideAxis.Vertical);
            transition.Start(null, statisticsViewPage, true, default);
            searchViewPage.IsVisible = false;
            libraryViewPage.IsVisible = false;
            settingsViewPage.IsVisible = false;
            statisticsViewPage.IsVisible = true;
            authorViewPage.IsVisible = false;
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
            authorViewPage.IsVisible = true;
        }
    }
}