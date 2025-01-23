package com.j0nathan550.soundscapes.adapters;

import androidx.recyclerview.widget.RecyclerView;

import android.annotation.SuppressLint;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import com.bumptech.glide.Glide;
import com.j0nathan550.soundscapes.R;

import java.util.List;
import java.util.concurrent.TimeUnit;
import se.michaelthelin.spotify.model_objects.specification.Track;

public class SearchResultAdapter extends RecyclerView.Adapter<SearchResultAdapter.SearchResultViewHolder>
{
    private final List<Track> trackList;

    public SearchResultAdapter(List<Track> trackList)
    {
        this.trackList = trackList;
    }

    @NonNull
    @Override
    public SearchResultViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType)
    {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.layout_search_result, parent, false);
        return new SearchResultViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull SearchResultViewHolder holder, int position)
    {
        Track currentTrack = trackList.get(position);
        holder.titleTextView.setText(currentTrack.getName());

        StringBuilder artistNames = new StringBuilder();
        for (int i = 0; i < currentTrack.getArtists().length; i++) {
            artistNames.append(currentTrack.getArtists()[i].getName());
            if (i < currentTrack.getArtists().length - 1) {
                artistNames.append(", ");
            }
        }
        holder.authorTextView.setText(artistNames.toString());

        if (currentTrack.getAlbum().getImages().length > 0) {
            String imageUrl = currentTrack.getAlbum().getImages()[0].getUrl();
            Glide.with(holder.itemView.getContext())
                    .load(imageUrl)
                    .into(holder.backgroundImageView);
            Glide.with(holder.itemView.getContext())
                    .load(imageUrl)
                    .into(holder.foregroundImageView);
        } else {
            holder.backgroundImageView.setImageResource(R.drawable.baseline_downloading_24);
            holder.foregroundImageView.setImageResource(R.drawable.baseline_downloading_24);
        }

        long durationMs = currentTrack.getDurationMs();
        @SuppressLint("DefaultLocale") String durationFormatted = String.format("%d:%02d",
                TimeUnit.MILLISECONDS.toMinutes(durationMs),
                TimeUnit.MILLISECONDS.toSeconds(durationMs) -
                        TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(durationMs))
        );
        holder.durationTextView.setText(durationFormatted);
    }

    @Override
    public int getItemCount() {
        return trackList.size();
    }

    public static class SearchResultViewHolder extends RecyclerView.ViewHolder {
        final ImageView backgroundImageView;
        final ImageView foregroundImageView;
        final TextView titleTextView;
        final TextView authorTextView;
        final TextView durationTextView;

        public SearchResultViewHolder(@NonNull View itemView) {
            super(itemView);
            backgroundImageView = itemView.findViewById(R.id.backgroundImage);
            foregroundImageView = itemView.findViewById(R.id.foregroundImage);
            titleTextView = itemView.findViewById(R.id.title);
            authorTextView = itemView.findViewById(R.id.author);
            durationTextView = itemView.findViewById(R.id.time);
        }
    }
}