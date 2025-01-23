package com.j0nathan550.soundscapes;

import static androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode;

import android.content.res.Configuration;
import android.os.Bundle;

import androidx.activity.EdgeToEdge;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;

import com.google.android.material.bottomnavigation.BottomNavigationView;
import com.j0nathan550.soundscapes.fragments.PlaylistFragment;
import com.j0nathan550.soundscapes.fragments.SearchFragment;
import com.j0nathan550.soundscapes.fragments.SettingsFragment;

public class MainActivity extends AppCompatActivity {

    private final SearchFragment searchFragment = new SearchFragment();
    private final PlaylistFragment playlistFragment = new PlaylistFragment();
    private final SettingsFragment settingsFragment = new SettingsFragment();
    private BottomNavigationView bottomNavigationView;
    private int lastSelectedFragmentId = -1;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        setDefaultNightMode(AppCompatDelegate.MODE_NIGHT_YES);

        bottomNavigationView = findViewById(R.id.bottomNavigationView);
        bottomNavigationView.setOnItemSelectedListener(item ->
        {
            int id = item.getItemId();

            if(id == R.id.searchMenuItem)
            {
                ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
                    Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
                    v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);
                    return insets;
                });
                replaceFragment(searchFragment);
            }
            else if (id == R.id.playlistMenuItem)
            {
                ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
                    v.setPadding(0, 0, 0, 0);
                    return insets;
                });
                replaceFragment(playlistFragment);
            }
            else if (id == R.id.settingsMenuItem)
            {
                ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
                    v.setPadding(0, 0, 0, 0);
                    return insets;
                });
                replaceFragment(settingsFragment);
            }

            lastSelectedFragmentId = id;

            return true;
        });

        bottomNavigationView.setSelectedItemId(R.id.searchMenuItem);
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        bottomNavigationView.setSelectedItemId(lastSelectedFragmentId);
    }

    private void replaceFragment(Fragment fragment) {
        getSupportFragmentManager().beginTransaction()
                .replace(R.id.mainContent, fragment)
                .commit();
    }
}