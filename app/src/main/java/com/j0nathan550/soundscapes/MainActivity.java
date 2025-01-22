package com.j0nathan550.soundscapes;

import static androidx.appcompat.app.AppCompatDelegate.setDefaultNightMode;

import android.os.Bundle;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;

import com.google.android.material.bottomnavigation.BottomNavigationView;

public class MainActivity extends AppCompatActivity {

    private BottomNavigationView bottomNavigationView;
    private final SearchFragment searchFragment = new SearchFragment();
    private final PlaylistFragment playlistFragment = new PlaylistFragment();
    private final SettingsFragment settingsFragment = new SettingsFragment();

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
                replaceFragment(searchFragment);
            }
            else if (id == R.id.playlistMenuItem)
            {
                replaceFragment(playlistFragment);
            }
            else if (id == R.id.settingsMenuItem)
            {
                replaceFragment(settingsFragment);
            }

            return true;
        });

        bottomNavigationView.setSelectedItemId(R.id.searchMenuItem);
    }

    private void replaceFragment(Fragment fragment) {
        getSupportFragmentManager().beginTransaction()
                .replace(R.id.mainContent, fragment)
                .commit();
    }
}