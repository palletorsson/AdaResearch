# Simple Substrates — Bar, Profile, BarArray

Three primitives simpler than the Grid. Each is a 2D canvas (flat panel in VR, like a screen or board) that algorithms draw on.

---

## 1. Bar — Single Vertical Line

The simplest possible substrate. One value, one bar.

```
     ┃
     ┃
     ┃  ← height = value
     ┃
  ───┸───
```

**What it shows:** A single scalar value. Threshold, amplitude, counter, progress.

**Cartridges:**
- `threshold` — value vs threshold line, turns red when exceeded
- `accumulator` — counts up over time, resets
- `comparator` — two bars side by side, which is taller?
- `binary_state` — up/down, on/off, 0/1

**In a map:** `"Bar#mode:threshold#value:0.7"`

**Existing code:** `y_oscillation_cube` is basically this in 3D form.

---

## 2. Profile — A Line on a 2D Canvas

A continuous line tracing values left-to-right. The classic waveform / function graph.

```
  ╭─╮     ╭──╮
 ╱   ╲   ╱    ╲
╱     ╰─╯      ╲___
─────────────────────
```

**What it shows:** A function, signal, trajectory, or history over time/space.

**Cartridges:**
- `sine_wave` — basic function plotting (sin, cos, tan, custom)
- `signal_trace` — oscilloscope-style real-time signal
- `random_walk` — particle position over time
- `convergence` — algorithm output approaching a value (gradient descent, Newton's method)
- `function_explorer` — y = f(x), change f interactively
- `derivative` — show function AND its derivative overlaid
- `integration` — show function with shaded area underneath

**VR Interaction:**
- Touch the canvas to draw/set values
- Grab endpoints to scale axes
- Slide finger along to trace the curve

**In a map:** `"Profile#mode:sine_wave"`, `"Profile#mode:convergence#algo:gradient_descent"`

**Existing code:** `oscilloscope_display.gd` — already does waveform/Lissajous/spectrum on a 2D canvas with phosphor aesthetic. The Profile substrate could extend or wrap this.

---

## 3. BarArray — Array of Vertical Lines on a 2D Canvas

**This is the workhorse.** An ordered array of values rendered as vertical bars. The classic sorting/spectrum/histogram visualization.

```
  │       │
  │   │   │ │
  │ │ │   │ │ │
  │ │ │ │ │ │ │ │
  │ │ │ │ │ │ │ │ │
──┴─┴─┴─┴─┴─┴─┴─┴─┴──
  0 1 2 3 4 5 6 7 8
```

**What it shows:** An ordered collection of values. THE universal algorithm visualization.

**Cartridges:**

### Sorting (watch elements swap in real-time)
- `bubble_sort` — adjacent comparisons, bubbling up
- `insertion_sort` — element slides into place
- `selection_sort` — find minimum, swap to front
- `merge_sort` — split, sort halves, merge (shows recursion)
- `quicksort` — pivot, partition, recurse
- `heap_sort` — heap property maintenance
- `radix_sort` — digit-by-digit bucketing

### Searching
- `linear_search` — highlight bar by bar, left to right
- `binary_search` — highlight middle, halve, repeat
- `interpolation_search` — estimate position from value

### Data Structures
- `stack` — push/pop from one end (bars grow/shrink from right)
- `queue` — enqueue right, dequeue left
- `priority_queue` — insert sorted, dequeue min/max
- `heap` — tree structure implied by array positions

### Signal / Spectrum
- `fft_spectrum` — frequency bins from audio input
- `histogram` — distribution of sampled values
- `sampling` — continuous signal → discrete bars (shows aliasing)
- `quantization` — continuous values → stepped values

### Mathematical
- `fibonacci` — each bar = F(n), watch exponential growth
- `prime_sieve` — Sieve of Eratosthenes, bars go dark when eliminated
- `collatz` — sequence for a starting number

**VR Interaction:**
- Touch a bar to select it (highlight)
- Grab a bar to change its value (drag up/down)
- Grab two bars to swap them manually
- STEP / PLAY / RESET buttons (same as Grid)
- Speed slider
- Algorithm selector dropdown
- Size slider (number of bars: 8–128)

**Color Coding:**
- Default: height-mapped gradient (short=blue, tall=red)
- Active comparison: yellow highlight
- Swapping: white flash
- Sorted/done: green
- Pivot (quicksort): magenta
- Search target: cyan

---

## Physical Form

All three are **flat 2D panels** in the VR world:

```
┌─────────────────────┐
│                     │  ← 2D canvas (SubViewport texture on a MeshInstance3D)
│   ▐ ▐▌▐ ▐▌▐ ▐▌    │     or MultiMesh bars in 3D space
│   ▐▌▐▌▐▌▐▌▐▌▐▌▐▌   │
│   ▐▌▐▌▐▌▐▌▐▌▐▌▐▌▐  │
│  ─┴┴┴┴┴┴┴┴┴┴┴┴┴┴── │
│  [STEP][▶][↺][🧩▼]  │
└─────────────────────┘
```

**Two rendering approaches:**

### A. Screen (2D SubViewport)
- Flat panel with a SubViewport texture
- Bars drawn with `draw_rect()` in a Control node
- Profile drawn with `draw_polyline()`
- Crisp, pixel-perfect, lightweight
- Best for: wall-mounted displays, info boards

### B. Physical (3D MultiMesh)
- Each bar is a 3D box (BoxMesh in MultiMesh)
- Bars rise from a base plate
- Grabbable in VR — can reach in and touch individual bars
- More immersive, more expensive
- Best for: table artifacts, interactive stations

Both should be selectable via `variant`: `"BarArray:screen#mode:bubble_sort"` vs `"BarArray:physical#mode:bubble_sort"`

---

## Cartridge Interface (shared with Grid)

```gdscript
class_name ArrayAlgorithm extends RefCounted

func get_name() -> String:
    return "Unknown"

func get_description() -> String:
    return ""

func get_category() -> String:
    return "sorting"

## Initialize the array (called on reset)
## Return the starting array of float values (0.0 to 1.0)
func initialize(size: int) -> Array[float]:
    var arr: Array[float] = []
    for i in range(size):
        arr.append(randf())
    return arr

## Advance one step. Return a StepResult.
func step(arr: Array[float]) -> StepResult:
    return StepResult.new()  # Override this

## Is the algorithm finished?
func is_complete(arr: Array[float]) -> bool:
    return false

class StepResult:
    var comparisons: Array[Array] = []   # [[i, j], ...] indices being compared
    var swaps: Array[Array] = []         # [[i, j], ...] indices being swapped
    var highlights: Dictionary = {}       # {index: Color}
    var description: String = ""          # "Comparing elements 3 and 7"
```

---

## Relation to Existing Code

| Existing | Becomes |
|---|---|
| `distribution_sampler.gd` | BarArray with `histogram` cartridge |
| `oscilloscope_display.gd` | Profile with `signal_trace` cartridge |
| `y_oscillation_cube` | Bar with `sine_value` cartridge |
| `additive_wave_demo` | Profile with `additive_waves` cartridge |
| `ArrayInfoBoard` | BarArray with `manual` cartridge (just display, no algorithm) |
| `sine_wall_explanation` | Profile with `sine_wave` cartridge |

---

## File Structure

```
commons/artifacts/algorithm_bar/
├── algorithm_bar.tscn
├── algorithm_bar.gd
└── README.md

commons/artifacts/algorithm_profile/
├── algorithm_profile.tscn
├── algorithm_profile.gd
└── README.md

commons/artifacts/algorithm_bar_array/
├── algorithm_bar_array.tscn
├── algorithm_bar_array.gd
├── algorithm_bar_array_screen.gd     # 2D SubViewport renderer
├── algorithm_bar_array_physical.gd   # 3D MultiMesh renderer
├── array_algorithm.gd                # Base class for cartridges
├── ui/
│   ├── bar_array_controls.tscn
│   └── bar_array_controls.gd
└── cartridges/
    ├── sorting/
    │   ├── bubble_sort.gd
    │   ├── insertion_sort.gd
    │   ├── merge_sort.gd
    │   └── quicksort.gd
    ├── searching/
    │   ├── linear_search.gd
    │   └── binary_search.gd
    ├── signal/
    │   ├── fft_spectrum.gd
    │   ├── histogram.gd
    │   └── sampling.gd
    └── mathematical/
        ├── fibonacci.gd
        ├── prime_sieve.gd
        └── collatz.gd
```

---

## Map Placement

```json
"Bar#mode:threshold#value:0.5"
"Profile#mode:sine_wave"
"Profile:wall#mode:convergence#algo:newton"
"BarArray#mode:bubble_sort#size:32"
"BarArray:screen#mode:fft_spectrum"
"BarArray:physical#mode:quicksort#size:16"
```

---

## The Full Substrate Family

| Substrate | Complexity | Dimension | Renders |
|---|---|---|---|
| **Bar** | Simplest | 0D (single value) | One vertical line |
| **Profile** | Simple | 1D (function) | Connected line on canvas |
| **BarArray** | Medium | 1D (array) | Array of vertical lines |
| **AlgorithmGrid** | Complex | 2D (matrix) | Grid of cells |
| **Volume** (future) | Most complex | 3D (voxels) | Cube of cells |

Each level up contains the previous: a BarArray is a row of Bars. A Grid is a 2D array of rows. A Volume is a stack of Grids.

Build from the bottom up: Bar → Profile → BarArray → Grid → Volume.
