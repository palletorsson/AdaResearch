# Boyer-Moore Pattern Matching Visualization

An animated 3D visualization of the Boyer-Moore string search algorithm. Characters from a text corpus are laid out as a grid of labeled cubes, and a search pattern slides across them right-to-left, highlighting matches and mismatches in real time. The artifact teaches how efficient string search works by making the algorithm's "skip" strategy visible -- when a character does not appear in the pattern the entire window jumps forward, and a yellow indicator shows how many comparisons were saved.

## Concept Taught

**String pattern matching** is a fundamental algorithmic problem: given a text and a shorter pattern, find every occurrence of the pattern inside the text. The naive approach checks every position one character at a time. Boyer-Moore improves on this by comparing from the end of the pattern backward and using a **bad-character table** to skip large sections of text that cannot possibly match. The visualization shows these skips physically, making abstract algorithmic efficiency concrete and visible.

## How It Works

1. The text corpus is split into individual characters, each rendered as a small emissive box with a `Label3D` overlay, arranged in rows of 20.
2. A **bad-character table** is precomputed for the search pattern, recording how far the window can skip when a mismatch occurs.
3. Each animation step compares one character pair (right-to-left within the pattern). Matching characters glow green; mismatches glow red.
4. On a mismatch the bad-character rule calculates a skip distance, the pattern overlay jumps forward, and a temporary cylinder indicator visualizes the skip.
5. When every character in the pattern matches, the full match is highlighted in bright green and recorded.
6. A HUD panel tracks comparisons, skips, matches found, and current algorithm state.
7. Three identity-themed presets swap both the text and the search term with a single key press.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `text_corpus` | String | (identity paragraph) | The text to search through |
| `search_pattern` | String | `"queer"` | Pattern to locate in the text |
| `case_sensitive` | bool | `false` | Whether matching is case-sensitive |
| `highlight_partial_matches` | bool | `true` | Highlight partial runs of matching characters |
| `animation_speed` | float | `0.8` | Seconds between comparison steps |
| `show_bad_character_table` | bool | `true` | Display the preprocessing table |
| `auto_animate` | bool | `true` | Start searching automatically on load |
| `text_size` | float | `0.8` | Size of each character box |
| `character_spacing` | float | `1.0` | Horizontal gap between character boxes |
| `pattern_color` | Color | Magenta | Color of the sliding pattern overlay |
| `match_color` | Color | Green | Color used for matching characters |
| `mismatch_color` | Color | Red | Color used for mismatching characters |
| `text_color` | Color | White | Default color of the text characters |
| `identity_preset` | String | `"Trans_Visibility"` | Active preset (`Trans_Visibility`, `Queer_Community`, `Non_Binary_Recognition`) |

## Features

- Right-to-left comparison with visible skip indicators, faithfully reproducing Boyer-Moore behavior.
- Bad-character preprocessing table built at startup.
- Three switchable text/pattern presets accessible via number keys.
- Step-by-step mode (Space bar) or continuous auto-animation.
- HUD panel with live statistics: comparisons, skips, matches, and efficiency.
- Camera auto-adjusts to frame the full text grid.

## Files

- `boyer_moore_visualization.gd` -- Main script: algorithm logic, 3D character grid, animation, and UI.
- `boyer_moore_visualization.tscn` -- Scene file.
