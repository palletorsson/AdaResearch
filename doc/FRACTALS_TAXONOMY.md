# Fractals, taught in the order the engine needs it

> Eleventh sequence through the recipe (2026-08-27). Cheat-code: **recursion — a
> function that calls itself, and a stack that will eventually refuse.**

## The finding: the gallery was reading the wrong file

`doc/` holds TWO fractal maps. `fractals_concept_map.json` (plural) is a June file whose
"concepts" are ROOM NAMES — `MandelbrotSet`, `KochSierpinski`, `Synthesis` — with truths
that repeat their own names. `fractal_concept_map.json` (singular) is the bespoke
builder's output: **19 real concepts with real truths**, written the same week. The
concept-gallery alias pointed at the plural one from the day it was written, so the good
canon has been invisible for two months. One line in `build_concept_gallery.py` fixed
it; the comment there says why, so it cannot silently regress.

## The three inserted rungs (at source, in `tools/build_fractal_concept_map.py`)

Before the phenomena, what recursion IS in this engine:

1. **The base case** — the rung that stops it. A function that calls itself and never
   stops is not a fractal, it is a crash; the stack limit is this sequence's first
   teacher.
2. **The self-call** — `func f(): ... f()`. The whole of recursion is those four
   characters.
3. **Depth** — each level costs a stack frame. Depth is a budget, and infinity is a
   promise the machine cannot keep.

Then the 19 inherited concepts follow untouched: recursive trees, fractal dimension,
Cantor, Koch, Sierpinski, Menger, Mandelbrot, Julia, Lyapunov, IFS, golden spiral, DLA,
strange attractors, fractal terrain, space-filling curves, fractal furniture,
architecture, antennas. Live at **localhost:3003/fractals-concepts** — 117 tiles, 22
sections. Truth kept: *"Infinite complexity from finite rules."*

## The super: the_recursion_cabinet

A curiosity cabinet built by a function that calls itself — each shelf holds a smaller
copy of the whole cabinet, and at level 0 the **base case draws a SOLID block and
returns**, so the stop is visible as furniture. The depth plate reads how many cabinets
the recursion actually made.

In the drawers, each genuinely computed: Cantor's five levels of removed thirds; a Koch
edge after three replacements; Sierpinski by 400 chaos-game throws; a level-2 Menger
sponge built by the same keep-or-remove test at both scales; phi's spiral of boxes;
a 500-point Barnsley fern from four affine maps; and an escape-time Mandelbrot plate
where `z -> z*z + c` is asked of every one of 432 cells. 1,958 meshes; probe 0 broken.

Instrument note, new fault class: `_box` is a method on `_embodied/embodied_prop.gd`,
so declaring a local helper of that name is a signature clash, not a shadow — the
engine refuses the whole script. Renamed to `_slab`. Check the base class before naming
a helper.
