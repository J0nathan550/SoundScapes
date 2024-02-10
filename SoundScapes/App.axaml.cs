using Avalonia;
using Avalonia.Controls.ApplicationLifetimes;
using Avalonia.Markup.Xaml;
using SoundScapes.Views;
using System;

namespace SoundScapes;

public partial class App : Application
{
    public override void Initialize() 
    {
        Environment.SetEnvironmentVariable("SLAVA_UKRAINI", "1");
        AvaloniaXamlLoader.Load(this);
    }

    public override void OnFrameworkInitializationCompleted()
    {
        if (ApplicationLifetime is IClassicDesktopStyleApplicationLifetime desktop) desktop.MainWindow = new MainWindow();
        else if (ApplicationLifetime is ISingleViewApplicationLifetime singleViewPlatform) singleViewPlatform.MainView = new MainView();
        base.OnFrameworkInitializationCompleted();
    }
}
