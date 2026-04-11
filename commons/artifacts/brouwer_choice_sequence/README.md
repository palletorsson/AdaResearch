# Brouwer Choice Sequence

Visualizes Brouwer's concept of free choice sequences from intuitionistic mathematics -- infinite sequences where each term is freely chosen and the sequence is never finished, representing the idea that mathematical objects can exist in a genuinely unfinished state.

## How It Works

Eight spheres are arranged in a line, each progressively more transparent, representing the known terms of an unfolding sequence. An ellipsis ("...") and a question mark follow the last sphere, emphasizing that the sequence continues indefinitely with undetermined future values. The spheres gently oscillate vertically with a phase offset, creating a wave-like breathing animation that suggests ongoing, living construction rather than a static completed object.

## Features

- Fading transparency gradient across 8 spheres (alpha decreases by 0.1 per step)
- Ellipsis and question mark symbols indicating open-ended continuation
- Gentle sinusoidal vertical animation with per-dot phase offset
- Explanatory label: "Infinite, but never finished. Each term chosen freely."
- Grid configuration support via `apply_grid_config()`

## Files

- `brouwer_choice_sequence.gd` -- Main script
- `brouwer_choice_sequence.tscn` -- Scene file
