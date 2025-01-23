package com.j0nathan550.soundscapes.fragments;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.SearchView;
import android.widget.Toast;

import com.j0nathan550.soundscapes.R;
import com.j0nathan550.soundscapes.adapters.SearchResultAdapter;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import se.michaelthelin.spotify.SpotifyApi;
import se.michaelthelin.spotify.model_objects.credentials.ClientCredentials;
import se.michaelthelin.spotify.model_objects.specification.Paging;
import se.michaelthelin.spotify.model_objects.specification.Track;
import se.michaelthelin.spotify.requests.authorization.client_credentials.ClientCredentialsRequest;

public class SearchFragment extends Fragment {
    private SearchResultAdapter adapter;
    private final List<Track> trackList = new ArrayList<>();
    private final SpotifyApi spotifyApi = new SpotifyApi.Builder().setClientId("CLIENT_ID").setClientSecret("CLIENT_SECRET").build();
    private final ClientCredentialsRequest clientCredentialsRequest = spotifyApi.clientCredentials().build();
    private String accessToken;
    private Handler tokenRefreshHandler;
    private final Runnable tokenRefresher = this::refreshToken;

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        tokenRefreshHandler = new Handler(Looper.getMainLooper());
        refreshToken();
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        View view = inflater.inflate(R.layout.fragment_search, container, false);

        RecyclerView recyclerView = view.findViewById(R.id.searchResultRecycleView);
        recyclerView.setLayoutManager(new LinearLayoutManager(getContext()));
        adapter = new SearchResultAdapter(trackList);
        recyclerView.setAdapter(adapter);

        SearchView searchView = view.findViewById(R.id.searchResultView);
        searchView.setOnQueryTextListener(new SearchView.OnQueryTextListener() {
            @Override
            public boolean onQueryTextSubmit(String query) {
                performSearch(query);
                return true;
            }

            @Override
            public boolean onQueryTextChange(String newText) {
                return true;
            }
        });

        return view;
    }

    @SuppressLint("NotifyDataSetChanged")
    private void performSearch(String query) {
        new Thread(() -> {
            try {
                if (accessToken == null) {
                    refreshToken();
                }
                spotifyApi.setAccessToken(accessToken);

                Paging<Track> trackPaging = spotifyApi.searchTracks(query).build().execute();
                Track[] tracks = trackPaging.getItems();

                trackList.clear();
                trackList.addAll(Arrays.asList(tracks));

                if (getActivity() != null) {
                    getActivity().runOnUiThread(() -> adapter.notifyDataSetChanged());
                }
            } catch (Exception e) {
                if (getActivity() != null) {
                    getActivity().runOnUiThread(() ->
                            Toast.makeText(getContext(), "Error: " + e.getMessage(), Toast.LENGTH_SHORT).show()
                    );
                }
            }
        }).start();
    }

    private void refreshToken() {
        new Thread(() -> {
            try {
                ClientCredentials clientCredentials = clientCredentialsRequest.execute();
                accessToken = clientCredentials.getAccessToken();

                long refreshTime = (clientCredentials.getExpiresIn() - 2) * 1000L;
                tokenRefreshHandler.removeCallbacks(tokenRefresher);
                tokenRefreshHandler.postDelayed(tokenRefresher, Math.max(refreshTime, 0));
            } catch (Exception e) {
                if (getActivity() != null) {
                    getActivity().runOnUiThread(() ->
                            Toast.makeText(getContext(), "Failed to refresh token: " + e.getMessage(), Toast.LENGTH_SHORT).show()
                    );
                }
            }
        }).start();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (tokenRefreshHandler != null) {
            tokenRefreshHandler.removeCallbacks(tokenRefresher);
        }
    }
}