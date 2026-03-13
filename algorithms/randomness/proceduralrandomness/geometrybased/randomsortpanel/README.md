# Random Sort Panel -- Four Sorting Algorithms Visualizer

An animated panel displaying four classic sorting algorithms running side by side on identical data. This artifact teaches the concept of **sorting algorithms as visual processes** -- showing how Bubble Sort, Selection Sort, Insertion Sort, and Quick Sort each reorder the same random data using different strategies, with real-time highlighting of comparisons and swaps.

## How It Works

1. **Panel structure** -- Four horizontal shelves are created, one per algorithm. Each shelf displays a row of vertical bars whose heights represent random values. All four rows start with identical random arrangements so their sorting behavior can be compared directly.

2. **Sorting cycle** -- The visualizer auto-cycles between randomized and sorted states:
   - A timer counts up to `auto_resort_delay` seconds.
   - When triggered, all four rows either randomize (generating a shared set of random heights) or begin sorting simultaneously.

3. **Algorithm implementations** -- Each algorithm runs as an async coroutine using `await`:
   - **Bubble Sort** -- Compares adjacent pairs, swaps if out of order, repeats for shrinking range.
   - **Selection Sort** -- Finds the minimum in the unsorted portion, swaps it to the front.
   - **Insertion Sort** -- Takes each element and shifts it backward into its correct position.
   - **Quick Sort** -- Recursively partitions around a pivot, sorting sub-arrays. Tracks recursive calls to know when finished.

4. **Visual feedback** -- During each step, the currently compared bars are highlighted with emissive materials. Bars are color-coded per algorithm (red, green, blue, yellow).

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `num_algorithms` | 4 | Number of algorithm rows |
| `shelf_width` | 6.0 | Width of each shelf |
| `shelf_depth` | 0.25 | Depth of each shelf |
| `shelf_height` | 0.12 | Thickness of each shelf |
| `shelf_spacing` | 0.7 | Vertical gap between rows |
| `shelf_color` | Off-white | Base shelf color |
| `bars_per_row` | 20 | Number of bars per algorithm |
| `min_bar_height` | 0.25 | Shortest possible bar |
| `max_bar_height` | 0.65 | Tallest possible bar |
| `bar_width` | 0.08 | Width of each bar |
| `bar_depth` | 0.08 | Depth of each bar |
| `bar_gap` | 0.02 | Gap between bars |
| `sort_delay` | 0.3 | Delay between sorting steps (seconds) |
| `auto_resort_delay` | 4.0 | Seconds between sort/randomize cycles |
| `auto_animate` | true | Whether to auto-cycle |

## Features

- Side-by-side comparison of four sorting algorithms on identical input
- Async coroutine-based animation with configurable step delay
- Emissive highlight materials for active comparisons
- Quick Sort tracks recursive call depth to detect completion
- Auto-cycling between random and sorted states
- Label3D algorithm names with per-algorithm color coding

## Files

| File | Description |
|------|-------------|
| `random_sort_panel.gd` | Four-algorithm sorting visualizer with animated bars |
| `random_sort_panel.tscn` | Scene file for the sorting panel |
