# Bar Array Cartridges

Algorithm cartridges for the BarArray substrate. Each extends `BarArrayCartridge` and implements `initialize()`, `step()`, and `get_bar_color()` to drive a 1D bar chart visualization.

## How It Works

A cartridge receives a `PackedFloat32Array` of normalized bar heights and returns an updated array plus comparison/swap metadata on each step. The renderer interpolates bar heights and applies per-bar colors. Sorting cartridges highlight comparisons in yellow and flash swaps in white; non-sorting cartridges use custom color schemes.

## Files

- `cartridge_bubble_sort.gd` -- Bubble sort. Adjacent compare-and-swap, sorted boundary creeps right. O(n^2).
- `cartridge_insertion_sort.gd` -- Insertion sort. Slides each element left into sorted position. O(n^2) worst, O(n) best.
- `cartridge_selection_sort.gd` -- Selection sort. Finds minimum, swaps to front. O(n^2).
- `cartridge_merge_sort.gd` -- Bottom-up merge sort. Merges widening halves. O(n log n).
- `cartridge_quicksort.gd` -- Quicksort with Lomuto partition. Magenta pivot sweep. O(n log n) average.
- `cartridge_heap_sort.gd` -- Heap sort. Build-heap phase then extract-max. O(n log n).
- `cartridge_histogram.gd` -- Bins Gaussian samples into a growing bell curve.
- `cartridge_fibonacci.gd` -- Builds the Fibonacci sequence with exponential bar growth.
- `cartridge_prime_sieve.gd` -- Sieve of Eratosthenes. Primes stay cyan, composites go dark.
