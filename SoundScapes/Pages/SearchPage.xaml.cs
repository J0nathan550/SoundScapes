using SoundScapes.Models;

namespace SoundScapes.Pages;

public partial class SearchPage : ContentPage
{
	public SearchPage()
	{
		InitializeComponent();
		BindingContext = new SearchPageViewModel() {  ListViewTracks = listViewTrackTest };
	}
}